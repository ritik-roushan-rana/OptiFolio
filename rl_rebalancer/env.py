import gym
import numpy as np
import re

class PortfolioEnv(gym.Env):
    def __init__(self, data, initial_cash=100000, initial_portfolio=None):
        super().__init__()
        self.data = data
        self.initial_cash = initial_cash
        self.current_step = 0
        # Detect asset names from columns ending with '_Close'
        self.asset_names = [re.sub(r'_Close$', '', col) for col in self.data.columns if col.endswith('_Close')]
        self.n_assets = len(self.asset_names)
        self.action_space = gym.spaces.Box(low=-1, high=1, shape=(self.n_assets,), dtype=np.float32)
        self.observation_space = gym.spaces.Box(low=0, high=np.inf, shape=(self.n_assets * 3,), dtype=np.float32)
        self.initial_portfolio = initial_portfolio if initial_portfolio is not None else np.zeros(self.n_assets)
        self.reset()

    def reset(self):
        self.current_step = 0
        self.cash = self.initial_cash
        self.portfolio = self.initial_portfolio.copy() if hasattr(self, 'initial_portfolio') else np.zeros(self.n_assets)
        self.prev_portfolio = self.portfolio.copy()
        self.prev_cash = self.initial_cash
        return self._get_obs()

    def _get_obs(self):
        prices = []
        returns = []
        volatility = []
        for i, asset in enumerate(self.asset_names):
            price_series = self.data[f"{asset}_Close"].values
            idx = min(self.current_step, len(price_series)-1)
            price = price_series[idx]
            if not np.isfinite(price) or price <= 0:
                price = 1e-6
            prices.append(price)
            # Calculate recent return (1-step)
            if idx > 0 and np.isfinite(price_series[idx-1]) and price_series[idx-1] != 0:
                ret = (price - price_series[idx-1]) / price_series[idx-1]
            else:
                ret = 0.0
            returns.append(ret)
            # Calculate rolling volatility (last 5 steps)
            if idx >= 4:
                window = price_series[idx-4:idx+1]
                window = np.where(np.isfinite(window), window, 0.0)
                vol = np.std(window)
            else:
                vol = 0.0
            volatility.append(vol)
        prices = np.array(prices)
        total_value = np.sum(prices * self.portfolio) + self.cash
        if not np.isfinite(total_value) or total_value <= 0:
            weights = np.zeros(self.n_assets)
        else:
            weights = (prices * self.portfolio) / total_value
        # Replace any NaN or inf in weights, returns, volatility
        weights = np.where(np.isfinite(weights), weights, 0.0)
        returns = np.where(np.isfinite(returns), returns, 0.0)
        volatility = np.where(np.isfinite(volatility), volatility, 0.0)
        obs = np.concatenate([weights, returns, volatility])
        # Pad or truncate obs to match observation_space shape
        obs_shape = self.observation_space.shape[0]
        if obs.shape[0] < obs_shape:
            obs = np.pad(obs, (0, obs_shape - obs.shape[0]), 'constant')
        elif obs.shape[0] > obs_shape:
            obs = obs[:obs_shape]
        # Final sanitization
        obs = np.where(np.isfinite(obs), obs, 0.0)
        return obs

    def step(self, action):
        action = np.clip(action, 0, 1)  # Only allow positive allocations
        action_sum = np.sum(action)
        if action_sum > 1:
            action = action / action_sum  # Normalize so sum <= 1
        prices = []
        for i, asset in enumerate(self.asset_names):
            price_series = self.data[f"{asset}_Close"].values
            idx = min(self.current_step, len(price_series)-1)
            price = price_series[idx]
            if not np.isfinite(price) or price <= 0:
                price = 1e-6
            prices.append(price)
        prices = np.array(prices)
        total_value = np.sum(prices * self.portfolio) + self.cash
        if not np.isfinite(total_value) or total_value <= 0:
            total_value = self.initial_cash
        # Target value for each asset
        target_value = action * total_value
        target_shares = np.where(prices > 0, target_value / prices, 0.0)
        # Calculate trades and cost
        trades = target_shares - self.portfolio
        trade_cost = np.sum(np.abs(trades) * prices * 0.001)
        # Check if enough cash for trade cost
        if self.cash < trade_cost:
            # Scale down trades so cash never goes negative
            scale = self.cash / (trade_cost + 1e-6)
            target_shares = self.portfolio + trades * scale
            trade_cost = np.sum(np.abs(target_shares - self.portfolio) * prices * 0.001)
        self.prev_portfolio = self.portfolio.copy()
        self.prev_cash = self.cash
        self.cash -= trade_cost
        if not np.isfinite(self.cash) or self.cash < 0:
            print(f"Warning: cash became invalid: {self.cash}. Resetting to 0.")
            self.cash = 0.0
        self.portfolio = np.where(np.isfinite(target_shares), target_shares, 0.0)
        self.portfolio = np.where(self.portfolio >= 0, self.portfolio, 0.0)
        self.current_step += 1
        reward = self._calculate_reward(prices)
        if not np.isfinite(reward):
            print(f"Warning: reward became invalid: {reward}. Resetting to 0.")
            reward = 0.0
        obs = self._get_obs()
        if not np.all(np.isfinite(obs)):
            print(f"Warning: obs contains invalid values. Resetting to zeros.")
            obs = np.where(np.isfinite(obs), obs, 0.0)
        done = self.current_step >= len(self.data)
        portfolio_value = np.sum(prices * self.portfolio) + self.cash
        if not np.isfinite(portfolio_value):
            print(f"Warning: portfolio_value became invalid: {portfolio_value}. Resetting to 0.")
            portfolio_value = 0.0
        info = {"portfolio_value": portfolio_value}
        return obs, reward, done, info

    def _calculate_reward(self, prices=None):
        if prices is None:
            prices = []
            for i, asset in enumerate(self.asset_names):
                price_series = self.data[f"{asset}_Close"].values
                idx = min(self.current_step, len(price_series)-1)
                price = price_series[idx]
                if not np.isfinite(price) or price <= 0:
                    price = 1e-6
                prices.append(price)
            prices = np.array(prices)
        portfolio_value = np.sum(prices * self.portfolio) + self.cash
        if not np.isfinite(portfolio_value):
            print(f"Warning: portfolio_value in reward became invalid: {portfolio_value}. Resetting to 0.")
            portfolio_value = 0.0
        if self.current_step == 0:
            prev_value = self.initial_cash
        else:
            prev_prices = []
            for i, asset in enumerate(self.asset_names):
                price_series = self.data[f"{asset}_Close"].values
                idx = min(self.current_step-1, len(price_series)-1)
                price = price_series[idx]
                if not np.isfinite(price) or price <= 0:
                    price = 1e-6
                prev_prices.append(price)
            prev_prices = np.array(prev_prices)
            prev_value = np.sum(prev_prices * self.prev_portfolio) + self.prev_cash
            if not np.isfinite(prev_value):
                print(f"Warning: prev_value in reward became invalid: {prev_value}. Resetting to 0.")
                prev_value = 0.0
        reward = portfolio_value - prev_value
        if not np.isfinite(reward):
            print(f"Warning: reward calculation produced invalid value: {reward}. Resetting to 0.")
            reward = 0.0
        return reward

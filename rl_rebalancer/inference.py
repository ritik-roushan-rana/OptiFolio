from stable_baselines3 import PPO
from env import PortfolioEnv
from data_loader import DataLoader
import numpy as np

class RLInference:
    def __init__(self, model_path, data_path):
        self.loader = DataLoader(csv_path=data_path)
        self.df = self.loader.load_csv()
        self.df = self.loader.preprocess(self.df)
        self.env = PortfolioEnv(self.df)
        self.model = PPO.load(model_path)

    def recommend(self, obs=None):
        if obs is None:
            obs = self.env.reset()
        action, _ = self.model.predict(obs)
        return action

    def backtest(self):
        obs = self.env.reset()
        done = False
        rewards = []
        while not done:
            action, _ = self.model.predict(obs)
            obs, reward, done, info = self.env.step(action)
            rewards.append(reward)
        return np.sum(rewards), rewards

if __name__ == "__main__":
    # Example usage: print recommendations and backtest results
    model_path = "rl_rebalancer_model"
    data_path = "/Users/ritikrana/Desktop/new/OptiFolio/Frontend/assets/data/all_data_2018_2021.csv"
    infer = RLInference(model_path, data_path)
    obs = infer.env.reset()
    action = infer.recommend(obs)
    print("Recommended action (portfolio weights):", action)
    total_reward, rewards = infer.backtest()
    print("Backtest total reward:", total_reward)
    print("Backtest rewards per step:", rewards)

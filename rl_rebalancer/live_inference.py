import yfinance as yf
import pandas as pd
from stable_baselines3 import PPO
from env import PortfolioEnv
import re

# Get asset names from your training CSV
csv_path = "/Users/ritikrana/Desktop/new/OptiFolio/Frontend/assets/data/all_data_2018_2021.csv"
with open(csv_path, "r") as f:
    header = f.readline().strip().split(",")
asset_names = [re.sub(r'_Close$', '', col) for col in header if col.endswith('_Close')]

# Fetch live prices for all assets (append .NS for Indian stocks)
latest_prices = {}
for asset in asset_names:
    try:
        ticker = asset + ".NS"
        data = yf.download(ticker, period='1d', interval='1m')
        price = float(data['Close'].dropna().iloc[-1]) if not data['Close'].dropna().empty else 1e-6
    except Exception:
        price = 1e-6
    latest_prices[f"{asset}_Close"] = price

# Create DataFrame in expected format
df = pd.DataFrame([latest_prices])

# Create environment with one step of live data
env = PortfolioEnv(df)

# Load trained model
model = PPO.load("rl_rebalancer_model")

# Get recommended action (portfolio weights)
obs = env.reset()
action, _ = model.predict(obs)
print("Live recommended portfolio weights:")
for asset, weight in zip(env.asset_names, action):
    print(f"{asset}: {weight:.4f}")

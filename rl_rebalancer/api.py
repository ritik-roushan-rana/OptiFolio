from fastapi import FastAPI, UploadFile, File
from inference import RLInference
import os
from pydantic import BaseModel
import yfinance as yf
import pandas as pd
from stable_baselines3 import PPO
from env import PortfolioEnv
import re

app = FastAPI()

MODEL_PATH = "/home/ubuntu/OptiFolio/rl_rebalancer_model.zip"
DATA_PATH = "/home/ubuntu/OptiFolio/rl_rebalancer/all_data_2018_2021.csv"

class PortfolioRequest(BaseModel):
    assets: list  # e.g. ["BHARTIARTL", "TATASTEEL", ...]

@app.post("/recommend")
def recommend():
    rl = RLInference(MODEL_PATH, DATA_PATH)
    action = rl.recommend()
    return {"recommended_action": action.tolist()}

@app.post("/backtest")
def backtest():
    rl = RLInference(MODEL_PATH, DATA_PATH)
    total_reward, rewards = rl.backtest()
    return {"total_reward": float(total_reward), "rewards": [float(r) for r in rewards]}

@app.post("/upload-data")
def upload_data(file: UploadFile = File(...)):
    file_location = f"/home/ubuntu/OptiFolio/rl_rebalancer/{file.filename}"
    with open(file_location, "wb") as f:
        f.write(file.file.read())
    return {"info": f"file '{file.filename}' saved"}

@app.post("/rl-rebalance")
def rl_rebalance(request: PortfolioRequest):
    # Get asset names from training CSV
    csv_path = DATA_PATH
    with open(csv_path, "r") as f:
        header = f.readline().strip().split(",")
    all_asset_names = [re.sub(r'_Close$', '', col) for col in header if col.endswith('_Close')]
    # Use only assets provided in the request (portfolio holdings)
    portfolio_assets = request.assets
    # Fetch live prices for all assets in training file
    latest_prices = {}
    for asset in all_asset_names:
        try:
            ticker = asset + ".NS"
            data = yf.download(ticker, period='1d', interval='1m')
            price = float(data['Close'].dropna().iloc[-1]) if not data['Close'].dropna().empty else 1e-6
        except Exception:
            price = 1e-6
        latest_prices[f"{asset}_Close"] = price
    df = pd.DataFrame([latest_prices])
    env = PortfolioEnv(df)
    model = PPO.load(MODEL_PATH)
    obs = env.reset()
    action, _ = model.predict(obs)
    # Only return weights for portfolio assets
    weights = dict(zip(env.asset_names, action.tolist()))
    filtered_weights = {k: v for k, v in weights.items() if k in portfolio_assets}
    return {"weights": filtered_weights}

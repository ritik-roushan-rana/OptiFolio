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
def rl_rebalance(portfolio_file: UploadFile = File(...)):
    import io
    portfolio_df = pd.read_csv(io.StringIO(portfolio_file.file.read().decode()))
    with open(DATA_PATH, "r") as f:
        header = f.readline().strip().split(",")
    all_asset_names = [re.sub(r'_Close$', '', col) for col in header if col.endswith('_Close')]
    portfolio_assets = portfolio_df[portfolio_df.columns[0]].tolist()[1:] if portfolio_df.columns[0] == 'Stock' else portfolio_df['symbol'].tolist()
    if 'Stock' in portfolio_df.columns:
        holdings = portfolio_df[['Stock', 'Current_Amount']]
        portfolio_map = {row['Stock']: {'value': row['Current_Amount']} for _, row in holdings.iterrows()}
    else:
        holdings = portfolio_df[portfolio_df['type'] == 'holding']
        portfolio_map = {row['symbol']: {'value': row['value']} for _, row in holdings.iterrows()}
    latest_prices = {}
    for asset in all_asset_names:
        try:
            ticker = asset + ".NS"
            data = yf.download(ticker, period='1d', interval='1m')
            price = float(data['Close'].dropna().iloc[-1]) if not data['Close'].dropna().empty else 1e-6
        except Exception:
            price = 1e-6
        latest_prices[f"{asset}_Close"] = price
    total_portfolio_value = sum([float(portfolio_map[asset]['value']) for asset in portfolio_assets if asset in portfolio_map])
    current_weights = {}
    for asset in all_asset_names:
        value = float(portfolio_map[asset]['value']) if asset in portfolio_map else 0.0
        current_weights[asset] = value / total_portfolio_value if total_portfolio_value > 0 else 0.0
    df = pd.DataFrame([latest_prices])
    env = PortfolioEnv(df)
    model = PPO.load(MODEL_PATH)
    obs = env.reset()
    action, _ = model.predict(obs)
    filtered_current_weights = {k: v for k, v in current_weights.items() if k in portfolio_assets}
    filtered_recommended_weights = {k: v for k, v in dict(zip(env.asset_names, action.tolist())).items() if k in portfolio_assets}
    return dict(current_weights=filtered_current_weights, recommended_weights=filtered_recommended_weights)

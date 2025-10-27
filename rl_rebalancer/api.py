from fastapi import FastAPI, UploadFile, File
from inference import RLInference
import os
from pydantic import BaseModel
import yfinance as yf
import pandas as pd
from stable_baselines3 import PPO
from env import PortfolioEnv
import re
import time
from typing import Dict

app = FastAPI()

MODEL_PATH = "/home/ubuntu/OptiFolio/rl_rebalancer_model.zip"
DATA_PATH = "/home/ubuntu/OptiFolio/rl_rebalancer/all_data_2018_2021.csv"

# Global instances to avoid reloading per request
MODEL = None
RL_INSTANCE = None

# ---- Symbol mapping and simple in-memory cache ----
YAHOO_MAP: Dict[str, str] = {
    # Indices
    'NIFTY50': '^NSEI',
    'NIFTYBANK': '^NSEBANK',
    'NIFTYIT': '^CNXIT',
    # Common aliases
    'MM': 'M&M.NS',  # Mahindra & Mahindra
    'GOLD': 'GOLDBEES.NS',  # Gold ETF in India
}

PRICE_CACHE: Dict[str, Dict[str, float]] = {}
CACHE_TTL_SECONDS = 120  # avoid hammering Yahoo within this window


def to_yahoo_symbol(asset: str) -> str:
    a = asset.strip().upper()
    if a in YAHOO_MAP:
        return YAHOO_MAP[a]
    # Already suffixed/formatted
    if any(s in a for s in ['.NS', '.BO', '^', '=X', '-USD', 'BINANCE:']):
        return a
    return f"{a}.NS"


def fetch_latest_price(ticker: str) -> float:
    # Cache check
    now = time.time()
    entry = PRICE_CACHE.get(ticker)
    if entry and (now - entry['ts'] < CACHE_TTL_SECONDS):
        return entry['price']

    price = 1e-6
    try:
        # Try fast intraday first (explicit auto_adjust to silence warning)
        df = yf.download(ticker, period='1d', interval='1m', auto_adjust=False, progress=False, threads=True)
        if df is None or df.empty:
            # Fallback to daily data last 5 days
            df = yf.download(ticker, period='5d', interval='1d', auto_adjust=False, progress=False, threads=True)
        if df is not None and not df.empty and 'Close' in df.columns:
            close_series = df['Close'].dropna()
            if not close_series.empty:
                # Use .item() to avoid single-element Series float deprecation
                price = float(close_series.iloc[-1].item()) if hasattr(close_series.iloc[-1], 'item') else float(close_series.iloc[-1])
    except Exception:
        # Keep tiny epsilon to avoid zeros
        price = 1e-6

    PRICE_CACHE[ticker] = { 'price': price, 'ts': now }
    return price


class PortfolioRequest(BaseModel):
    assets: list  # e.g. ["BHARTIARTL", "TATASTEEL", ...]


@app.on_event("startup")
def _load_on_start():
    global MODEL, RL_INSTANCE
    try:
        MODEL = PPO.load(MODEL_PATH)
    except Exception as e:
        print("Failed to load PPO model:", e)
    try:
        # RLInference also loads data env; keep one instance for recommend/backtest
        RL_INSTANCE = RLInference(MODEL_PATH, DATA_PATH)
    except Exception as e:
        print("Failed to init RLInference:", e)


@app.get("/health")
def health():
    return {"status": "ok", "model": bool(MODEL is not None), "rl": bool(RL_INSTANCE is not None)}


@app.post("/recommend")
def recommend():
    if RL_INSTANCE is None:
        # Fallback lazy init
        rl = RLInference(MODEL_PATH, DATA_PATH)
    else:
        rl = RL_INSTANCE
    action = rl.recommend()
    return {"recommended_action": action.tolist()}


@app.post("/backtest")
def backtest():
    if RL_INSTANCE is None:
        rl = RLInference(MODEL_PATH, DATA_PATH)
    else:
        rl = RL_INSTANCE
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
    portfolio_assets = [a.strip().upper() for a in request.assets]

    # Fetch live prices for all assets in training file (cached + symbol mapped)
    latest_prices = {}
    for asset in all_asset_names:
        ticker = to_yahoo_symbol(asset)
        price = fetch_latest_price(ticker)
        latest_prices[f"{asset}_Close"] = price

    df = pd.DataFrame([latest_prices])
    env = PortfolioEnv(df)
    # Use preloaded model if available
    model = MODEL or PPO.load(MODEL_PATH)
    obs = env.reset()
    action, _ = model.predict(obs)

    # Only return weights for portfolio assets
    weights = dict(zip(env.asset_names, action.tolist()))
    filtered_weights = {k: float(v) for k, v in weights.items() if k in portfolio_assets}
    return {"weights": filtered_weights}

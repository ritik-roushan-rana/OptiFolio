import pandas as pd
import yfinance as yf

class DataLoader:
    def __init__(self, csv_path=None, tickers=None, start=None, end=None):
        self.csv_path = csv_path
        self.tickers = tickers
        self.start = start
        self.end = end

    def load_csv(self):
        df = pd.read_csv(self.csv_path)
        return df

    def load_yahoo(self):
        data = yf.download(self.tickers, start=self.start, end=self.end)
        return data

    def preprocess(self, df):
        # Example: fill missing, normalize, etc.
        df = df.fillna(0)
        return df

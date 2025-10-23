from stable_baselines3 import PPO
from env import PortfolioEnv
from data_loader import DataLoader
import torch

if __name__ == "__main__":
    # Load data
    loader = DataLoader(csv_path="/Users/ritikrana/Desktop/new/OptiFolio/Frontend/assets/data/all_data_2018_2021.csv")
    df = loader.load_csv()
    df = loader.preprocess(df)

    # Create environment
    env = PortfolioEnv(df)

    # Use PPO for continuous action space
    model = PPO("MlpPolicy", env, verbose=1)

    # Train
    model.learn(total_timesteps=10000)

    # Save model
    model.save("rl_rebalancer_model")

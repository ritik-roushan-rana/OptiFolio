import requests

url = "http://localhost:8001/rl-rebalance"
portfolio_path = "/Users/ritikrana/Desktop/new/OptiFolio/Frontend/assets/data/sample_portfolio.csv"

with open(portfolio_path, "rb") as f:
    files = {"portfolio_file": f}
    response = requests.post(url, files=files)
    print(response.status_code)
    print(response.json())

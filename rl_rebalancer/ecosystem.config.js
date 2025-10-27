module.exports = {
  apps: [
    {
      name: "rl-rebalancer",
      cwd: __dirname,
      script: "venv/bin/uvicorn",
      args: "api:app --host 0.0.0.0 --port 8001",
      interpreter: "none",
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      env: {
        PYTHONUNBUFFERED: "1",
        PYTHONPATH: "."
      }
    }
  ]
};

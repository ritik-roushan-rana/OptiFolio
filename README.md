# OptiFolio: Portfolio Tracker

OptiFolio is a full-stack investment portfolio and analytics application. It features a Flutter-based frontend, a Node.js + MongoDB backend, and a Python RL model service. The app provides tools for portfolio tracking, analytics, and insights, making it ideal for personal finance enthusiasts and investors.

---

## Monorepo Structure
```
OptiFolio/
├── Frontend/                 # Flutter app
│   ├── lib/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── services/
│   ├── pubspec.yaml
│   └── ios/ android/ assets/ ...
├── flutter-backend/          # Node.js API server
│   ├── src/
│   │   ├── app.js
│   │   ├── db.js
│   │   ├── middleware/
│   │   ├── controllers/
│   │   ├── routes/
│   │   └── models/
│   ├── package.json
│   └── .env
├── rl_rebalancer/            # RL model Python service
│   ├── api.py
│   ├── train.py
│   └── ...
```

---

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **UI**: Custom theming, Google Fonts, animated overlays

### Backend
- **Framework**: Node.js, Express
- **Database**: MongoDB (Mongoose)
- **Authentication**: JWT-based
- **Utilities**: CORS, Morgan (logging)

### RL Model
- **Language**: Python
- **Purpose**: Portfolio rebalancing API

---

## Features

### Frontend
- Onboarding & Authentication
- Dynamic Settings Panel
- Centralized State Management
- Custom Theming & Animated Panels

### Backend
- Modular API Design
- Database Integration
- Pluggable Controllers (alerts, analytics, portfolios, etc.)
- Health Check Endpoint

### RL Model
- Portfolio rebalancing via API

---

## App Screens & Features

### Frontend Screens
- **Onboarding Screen**: User registration and login.
- **Portfolio Dashboard**: Overview of investments, balances, and performance.
- **Analytics Screen**: Visualizations and metrics for portfolio analysis.
- **Insights Screen**: AI-generated investment insights and recommendations.
- **News Feed**: Latest market news and updates.
- **Rebalance Screen**: Portfolio rebalancing suggestions and actions.
- **Alerts Screen**: Price and event alerts management.
- **Settings Overlay**: Dynamic settings panel with toggles, navigation, and info cards.
- **Search Screen**: Search for stocks, companies, and news.
- **Stock Details Screen**: Detailed view of individual stock data.
- **Quotes Screen**: Live market quotes and price updates.
- **Authentication Screen**: Managed via AuthService for secure login/logout.

### RL Model Features
- **Portfolio Rebalancing**: Uses reinforcement learning to suggest optimal asset allocations.
- **API Service**: Exposes endpoints for live inference and portfolio uploads (see rl_rebalancer/api.py and related files).
- **Integration**: Backend communicates with RL model via REST API (`RL_API_URL`).
- **ML Model Files**: Model weights and logic are stored in `rl_rebalancer/` (see attachments above for file contents).

### Key Features
- **Portfolio Tracking**: Add, edit, and view investment portfolios.
- **Performance Analytics**: Track returns, risk, and other metrics.
- **AI Insights**: Get actionable insights powered by backend and RL model.
- **Market News**: Stay updated with financial news feeds.
- **Rebalancing**: Automated and manual portfolio rebalancing.
- **Alerts**: Set up price and event alerts for assets.
- **Dynamic Settings**: Customize app experience with dynamic settings panel.
- **Centralized State Management**: Provider-based state for consistency.
- **Custom Theming**: Google Fonts and animated overlays for modern UI.
- **Health Check**: `/api/health` endpoint for backend status.

---

## Environment Variables

### Backend (`flutter-backend/.env`)
```
PORT=3000
MONGODB_URI="mongodb+srv://<user>:<password>@cluster0.mongodb.net/"
JWT_SECRET="your_jwt_secret"
GEMINI_API_KEY="your_gemini_api_key"
CORS_ORIGIN="*"
RL_API_URL="http://<rl_model_host>:8001"
```

### Frontend (`Frontend/.env`)
```
IOS_CLIENT_ID=<ios_client_id>
REVERSED_CLIENT_ID=<reversed_client_id>
WEB_CLIENT_ID=<web_client_id>
FINNHUB_API_KEY=<finnhub_api_key>
API_BASE_URL=http://<backend_host>:3000
```

---

## Installation

### Backend
```bash
cd flutter-backend
npm install
npm run dev
```

### Frontend
```bash
cd Frontend
flutter pub get
flutter run -d ios
# or: flutter run -d chrome / android
```

If iOS:
```bash
cd ios
pod install
```

### RL Model
```bash
cd rl_rebalancer
pip install -r requirements.txt
python api.py
```

---

## SSH & Server Access

To access your backend server via SSH:

```bash
cd pem_key
ssh -i backend.pem ubuntu@15.206.217.186
```

This connects to your Ubuntu 24.04.3 LTS server (AWS EC2, IP: 15.206.217.186) using your PEM key.

---

## RL Model Service

To run the RL rebalancer API service:

```bash
cd rl_rebalancer
source venv/bin/activate
uvicorn api:app --host 0.0.0.0 --port 8001
```

---

## Running Full Stack
1. Start MongoDB (local or Atlas).
2. Start RL model service: `python api.py`
3. Start backend: `npm run dev`
4. Run Flutter app: `flutter run`

---

## API Overview

### Base URL: `/api`

| Route Group   | Purpose                  |
|---------------|--------------------------|
| `/auth`       | Authentication           |
| `/portfolio`  | Portfolio CRUD / balances|
| `/insights`   | Generated insights       |
| `/news`       | Market/news feeds        |
| `/rebalance`  | Rebalancing endpoints    |
| `/alerts`     | Price / event alerts     |
| `/search`     | Search results           |
| `/stocks`     | Stock data snapshot      |
| `/analytics`  | Performance & metrics    |
| `/quotes`     | Live/quote endpoints     |

#### Health Check:
```http
GET /api/health -> { status: "ok" }
```

#### Example Request:
```http
GET /api/portfolio
Authorization: Bearer <token>
```

---

## Dynamic Settings Flow
1. On overlay open: `SettingsOverlay.initState` triggers `loadSettings()` if empty.
2. Provider stores `List<SettingItem>` (types: `toggle`, `navigation`, `info`).
3. UI renders via `_buildDynamicSettingCards`.
4. Toggles call: `AppStateProvider.toggleSetting(key, value)`.

### Adding a New Setting
1. Expose from backend settings endpoint (e.g., `/api/settings`).
2. Extend model/transformer.
3. Update provider mapping in `AppStateProvider`.
4. Add icon mapping in `_iconForKey` inside `settings_overlay.dart`.

---

## Common Commands

### Flutter
```bash
# Analyze Flutter
flutter analyze
# Format
dart format lib
# Clean
flutter clean && rm -rf ios/Pods
```

### Backend
```bash
# Run Tests
npm test
```

---

## Deployment Notes
- **Secrets**: Externalize secrets (never commit `.env`).
- **Production Build**: Use `flutter build ios` / `flutter build apk`.
- **Backend**: Use a reverse proxy (e.g., nginx) + HTTPS.
- **Caching**: Enable caching for heavy analytics endpoints.

---

## Troubleshooting

| Issue                     | Fix                                      |
|---------------------------|------------------------------------------|
| iOS pods out of sync      | `cd ios && pod repo update && pod install` |
| CORS blocked              | Set `CORS_ORIGIN` correctly             |
| Settings empty            | Confirm backend endpoint + `loadSettings()` |
| Auth logout not redirecting | Ensure `/login` route registered in `MaterialApp` |

---

## Roadmap
- Add integration tests
- Add Web build pipeline
- Real-time price streaming (WebSockets)
- Offline caching layer
- Theming persistence


# OptiFolio: Portfolio Tracker

OptiFolio is a full-stack investment portfolio and analytics application. It features a Flutter-based frontend and a Node.js + MongoDB backend. The app provides tools for portfolio tracking, analytics, and insights, making it ideal for personal finance enthusiasts and investors.

---

## Monorepo Structure
```
OptiFolio/
├── Frontend/                 # Flutter app
│   ├── lib/
│   │   ├── widgets/
│   │   │   └── settings_overlay.dart
│   │   ├── providers/
│   │   │   └── app_state_provider.dart
│   │   └── services/
│   │       ├── auth_service.dart
│   │       └── settings_service.dart
│   ├── pubspec.yaml
│   └── ios/ android/ assets/ ...
└── flutter-backend/          # Node.js API server
    ├── src/
    │   ├── app.js
    │   ├── db.js
    │   ├── middleware/
    │   │   └── auth.js
    │   ├── controllers/
    │   ├── routes/
    │   └── models/
    ├── package.json
    └── .env (local)
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

---

## Features

### Frontend
- **Onboarding & Authentication**: Managed via `AuthService`
- **Dynamic Settings Panel**: Rendered dynamically using `SettingsOverlay`
- **Centralized State Management**: `AppStateProvider`
- **Custom Theming**: Google Fonts integration
- **Animated Panels**: Smooth transitions for overlays

### Backend
- **Modular API Design**: Organized routes and controllers
- **Database Integration**: Centralized DB connection via `db.js`
- **Pluggable Controllers**: Alerts, analytics, portfolios, and more
- **Health Check Endpoint**: `/api/health`

---

## Environment Variables

### Backend `.env` (example):
```
PORT=5000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=replace_me
CORS_ORIGIN=http://localhost:3000
```

### Frontend `.env` (example):
```
API_BASE_URL=http://localhost:5000/api
APP_ENV=dev
```

---

## Installation

### 1. Backend
```bash
cd flutter-backend
npm install
npm run dev        # if a dev script exists
# or: node src/app.js
```

### 2. Frontend
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

---

## Running Full Stack
1. Start MongoDB (local or Atlas).
2. Start backend: `npm run dev`
3. Run Flutter app: `flutter run`

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


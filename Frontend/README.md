# Portfolio Tracker (Flutter + Node/Express)

Full-stack investment portfolio & analytics app with a Flutter frontend and a Node.js + MongoDB backend.

## Monorepo Structure
```
Project/
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

## Tech Stack
- Frontend: Flutter (Dart), Provider state management, Google Fonts
- Backend: Node.js, Express, MongoDB (Mongoose)
- Auth: (JWT or session-based – adjust as implemented)
- UI: Custom theming via AppColors + animated overlay panels
- Dynamic Settings: Fetched from backend into provider, rendered in [`lib/widgets/settings_overlay.dart`](Frontend/lib/widgets/settings_overlay.dart)

## Key Frontend Features
- Onboarding & Auth (`AuthService`)
- Dynamic Settings Panel (navigation / toggle / info types) in [`SettingsOverlay`](Frontend/lib/widgets/settings_overlay.dart)
- Centralized app state in [`AppStateProvider`](Frontend/lib/providers/app_state_provider.dart)
- Logout + route reset
- Animated slide/fade panels
- Theming + typography via Google Fonts

## Key Backend Features
- Health & root endpoints
- Modular route grouping
- Logging (morgan), JSON parsing, CORS
- Pluggable controllers (alerts, analytics, portfolios, search, quotes, companies, news)
- Central DB connector (`db.js`)

## Environment Variables

Backend `.env` (example):
```
PORT=5000
MONGODB_URI=mongodb+srv://...
JWT_SECRET=replace_me
CORS_ORIGIN=http://localhost:3000
```

Frontend `.env` (example placed in `Frontend/.env` and also bundled if needed):
```
API_BASE_URL=http://localhost:5000/api
APP_ENV=dev
```

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

## Running Full Stack (Typical)
1. Start MongoDB (local or Atlas).
2. Start backend: `npm run dev`
3. Run Flutter app: `flutter run`

## Notable Files
- API entry: [`src/app.js`](flutter-backend/src/app.js)
- Dynamic settings UI: [`lib/widgets/settings_overlay.dart`](Frontend/lib/widgets/settings_overlay.dart)
- State: [`lib/providers/app_state_provider.dart`](Frontend/lib/providers/app_state_provider.dart)

## API Overview (Base: `/api`)
| Route Group | Purpose |
|-------------|---------|
| `/auth` | Authentication |
| `/portfolio` | Portfolio CRUD / balances |
| `/insights` | Generated insights |
| `/news` | Market/news feeds |
| `/rebalance` | Rebalancing endpoints |
| `/alerts` | Price / event alerts |
| `/search` | Search results |
| `/stocks` | Stock data snapshot |
| `/analytics` | Performance & metrics |
| `/quotes` | Live/quote endpoints |

Health:
```
GET /api/health -> { status: "ok" }
```

Example (adjust to implementation):
```http
GET /api/portfolio
Authorization: Bearer <token>
```

## Dynamic Settings Flow
1. On overlay open: [`SettingsOverlay.initState`](Frontend/lib/widgets/settings_overlay.dart) triggers `loadSettings()` if empty.
2. Provider stores `List<SettingItem>` (types: `toggle`, `navigation`, `info`).
3. UI renders via `_buildDynamicSettingCards`.
4. Toggles call: `AppStateProvider.toggleSetting(key, value)`.

## Adding a New Setting
1. Expose from backend settings endpoint (e.g., `/api/settings`).
2. Extend model/transformer.
3. Update provider mapping in `AppStateProvider`.
4. Add icon mapping in `_iconForKey` inside [`settings_overlay.dart`](Frontend/lib/widgets/settings_overlay.dart).

## Navigation
- After logout: route stack cleared → `/login`.
- Callback-based navigation injected via `SettingsOverlay` constructor for modularity.

## Common Commands
```bash
# Analyze Flutter
flutter analyze
# Format
dart format lib
# Clean
flutter clean && rm -rf ios/Pods
```

## Testing
Backend example (adjust):
```bash
npm test
```
Flutter:
```bash
flutter test
```

## Deployment Notes
- Externalize secrets (never commit `.env`).
- For production Flutter build: `flutter build ios` / `flutter build apk`
- Use reverse proxy (nginx) + HTTPS for backend.
- Consider enabling caching layers for heavy analytics endpoints.

## Troubleshooting
| Issue | Fix |
|-------|-----|
| iOS pods out of sync | `cd ios && pod repo update && pod install` |
| CORS blocked | Set `CORS_ORIGIN` correctly |
| Settings empty | Confirm backend endpoint + provider `loadSettings()` |
| Auth logout not redirecting | Ensure `/login` route registered in `MaterialApp` |

## Roadmap (Suggested)
- Add integration tests
- Add Web build pipeline
- Real-time price streaming (WebSockets)
- Offline caching layer
- Theming persistence

## License
Internal / Proprietary (adjust as needed).

## Credits
Developed by FinTech Labs.

---
Concise README generated. Adjust specifics (auth strategy, scripts) as implementation evolves.
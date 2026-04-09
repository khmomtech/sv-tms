# tms_customer_app

Minimal Flutter scaffold for SV‑TMS customer mobile app.


Run locally:

- Install Flutter SDK: https://flutter.dev/docs/get-started/install
- cd tms_customer_app
- flutter pub get
- Run the app (default backend is http://localhost:8080):

```bash
flutter run
```

Or specify the backend API URL at runtime using a Dart define (recommended):

```bash
flutter run --dart-define=API_BASE_URL=https://api.your-backend.com
```

When building for release or CI you can also pass the same `--dart-define` to `flutter build`.

Notes:

- The app reads the backend base URL from the compile-time define `API_BASE_URL`.
- Expected backend endpoints (adjust if your API differs):
	- POST /api/customers/login -> returns JSON with token (field `token` or `accessToken` or inside `data.token`)
	- GET /api/customers/orders -> list (supports paging)
	- GET /api/customers/orders/{id} -> order detail
- To generate a typed API client, expose the backend OpenAPI at `/v3/api-docs` and run a generator.

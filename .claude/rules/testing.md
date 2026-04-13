---
description: Testing conventions for backend, Angular, and Flutter
---

# Testing Conventions

## Backend (Spring Boot)

- Unit tests use H2 in-memory database — no external deps needed.
- Integration tests require MySQL + Redis running:
  ```bash
  docker compose -f docker-compose.local-dev.yml up -d mysql redis
  ```
- Run all tests: `./mvnw test`
- Run single service: `./mvnw -pl tms-core-api test`
- After any Lombok/MapStruct class change: `./mvnw clean package` (annotation processors must regenerate)
- Do not mock the database in integration tests — real DB divergence has caused prod failures.

## Angular

```bash
npm run test        # Karma/Jasmine watch mode
npm run test:ci     # Headless with coverage report
```

- Use `TestBed` for component tests, not standalone shallow rendering.
- Do not import unused Angular Material modules in test beds — it slows test compilation.

## Flutter

```bash
flutter test                      # All unit tests
flutter test test/widget/         # Widget tests only
flutter analyze                   # Static analysis
```

- Mock HTTP calls with `dio` mock adapter, never hit real endpoints in unit tests.
- Widget tests must pump and settle: `await tester.pumpAndSettle()`.

## Verification Pattern

When fixing a bug, write a failing test first, then fix the code, then confirm the test passes.

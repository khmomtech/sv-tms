---
description: QA and testing conventions — what to test, coverage targets, test types
---

# QA Conventions

## Test Types and When to Use Each

| Type | Tool | When |
|---|---|---|
| Unit test | JUnit 5 + Mockito (Java), Karma/Jasmine (Angular), `flutter test` | All business logic and service methods |
| Integration test | Spring `@SpringBootTest` with real MySQL | Repository queries, full request/response flows |
| Widget test | Flutter `testWidgets` | Flutter UI components |
| Manual smoke test | Browser + Postman | After every deploy to VPS |

## Coverage Targets

- Backend service methods: aim for 80%+ line coverage on new code.
- Angular components: cover all user interactions (button clicks, form submits, error states).
- Flutter screens: cover happy path + error state.

## Test Naming Convention

```java
// Java: methodName_condition_expectedResult
@Test
void login_withInvalidPassword_returns401() { ... }
```

```typescript
// Angular
it('should show error message when login fails', () => { ... });
```

```dart
// Flutter
testWidgets('shows loading spinner while fetching dispatch', (tester) async { ... });
```

## Regression Testing Checklist (before any PR)

- [ ] Run `./mvnw test` — all unit tests pass
- [ ] Run `npm run test:ci` — Angular tests pass with coverage
- [ ] Run `flutter test` — Flutter tests pass
- [ ] Manually verify the changed flow in the UI or app
- [ ] Check no new API boundary violations: `/check-boundaries`

## Bug Report Template

When reporting a bug to Claude:
1. State the exact error message or wrong behavior
2. Provide the file path and line number if known
3. State the expected behavior
4. State what you already tried

Example: "In `DriverLocationController.java:448`, the spoofing alert logs a WARN but does not persist. Expected: alert saved to DB. Tried: added log statement, confirmed method is called."

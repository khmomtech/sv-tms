# Auth client — Backend integration notes

This document summarizes the current backend auth endpoints (from `driver-app`) and the small changes or endpoints the mobile client expects for a smooth end-to-end experience.

## Current backend (driver-app)
Verified in `driver-app/src/main/java/com/svtrucking/logistics/controller/AuthController.java`:

- POST /api/auth/login
  - Request: { "username": "...", "password": "..." }
  - Response (200):
    {
      "code": "LOGIN_SUCCESS",
      "message": "Login successful",
      "token": "<access-token>",
      "refreshToken": "<refresh-token>",
      "user": { "username":"...", "email":"...", "roles": [...], "permissions": [...] }
    }
  - Notes: client accepts `token` (legacy) and `refreshToken` (optional).

- POST /api/auth/driver/login
  - Similar to login but includes driver-specific fields in `user` and requires `deviceId` in request.

- POST /api/auth/refresh
  - Request: Authorization header `Bearer <refresh-token>`
  - Response (200): { "accessToken": "<new-access-token>" }
  - Notes: client will also accept `token` key if returned instead of `accessToken`.

- POST /api/auth/change-password
  - Request: { "currentPassword": "...", "newPassword": "..." }
  - Requires authenticated user (Authorization: Bearer <access-token> via normal security filter).

- POST /api/auth/register and /api/auth/registerdriver
  - Present but annotated with `@PreAuthorize("hasRole('ADMIN')")` in current server. These endpoints are restricted to admin users and are not public.

- No endpoint exists for public password reset or password reset token/email sending (no `/api/auth/forgot-password` implemented).

## What the mobile client expects / supports

- Login: expects `token` and optional `refreshToken` along with `user` object. Implemented and verified.
- Change password: implemented and matches `ChangePasswordRequest` fields.
- Register: client sends `{ username, email, password, roles }` to `/api/auth/register`. Because this endpoint is ADMIN-only currently, client will surface the 403 and instruct users to contact admin. If the server owner wants public registration, remove the `@PreAuthorize` or add a separate public registration endpoint.
- Password reset: the client attempts to POST `{"email": "..."}` to `/api/auth/forgot-password` if available. If the server does not implement it the client will gracefully fall back to showing guidance to contact admin.
- Refresh: client added `refreshAccessToken()` which will call `/api/auth/refresh` with Authorization: Bearer <refreshToken> header and save `accessToken` or `token` from the response.

## Recommended backend additions / changes (if you want full E2E flows)

1) Public registration endpoint (optional)
- Route: POST `/api/auth/register-public` (or remove `@PreAuthorize` on existing register if appropriate)
- Request body (JSON):
  {
    "username": "string",
    "email": "string",
    "password": "string",
    "roles": ["USER"] // optional; default to USER if not provided
  }
- Response (201 or 200): { "code": "REGISTER_SUCCESS", "message": "User registered" }
- Notes: Consider MX/anti-abuse (captcha, email verification) if making public.

2) Password reset flow
- Route 1 (request reset): POST `/api/auth/forgot-password`
  - Body: { "email": "user@example.com" }
  - Behavior: If email exists, create a time-limited reset token and send an email to the user containing a reset link (or return token for testing).
  - Response: 200 OK with { "message": "If the email exists we sent reset instructions" } (avoid user enumeration)

- Route 2 (perform reset): POST `/api/auth/reset-password`
  - Body: { "token": "...", "newPassword": "..." }
  - Response: 200 OK with { "message": "Password updated" }

3) Profile endpoints (optional but useful)
- GET `/api/auth/profile` -> returns { user fields }
- PUT `/api/auth/profile` -> accepts { username?, email? } and updates the current user

4) Consistent token refresh response
- `/api/auth/refresh` should return either `{ "accessToken": "..." }` or for backward compatibility `{ "token": "..." }` — client supports both keys.

## Quick client-side notes and current fallbacks

- The Flutter client (`tms_customer_app`) uses `ApiConstants.baseUrl = http://10.0.2.2:8080` by default (Android emulator). For iOS simulator use `http://localhost:8080` or configure per platform.
- The client will gracefully fall back when password reset endpoint is missing, or when register is forbidden (shows a helpful error).
- Refresh logic: client calls `/api/auth/refresh` with Authorization header `Bearer <refreshToken>` and saves the returned access token if present.

## Suggested server-side implementation sketch for forgot-password controller (Spring Boot)

- POST /api/auth/forgot-password
  - Validate email, generate token, save token (or store in DB), send email with URL: https://your.domain/reset-password?token=XYZ
  - Use a background email sender (Spring Mail or external service)

- POST /api/auth/reset-password
  - Validate token and expiry, set new password after encoding with PasswordEncoder.

## Next steps I can take

- If you want, I can prepare a patch/PR for driver-app that adds a lightweight `forgot-password` + `reset-password` implementation (including DB table for tokens) and integration tests.
- Or I can keep client-only behavior and add more tests and localization strings.

---

If you want me to proceed with a backend PR for password reset or a public register endpoint, tell me which approach you prefer and I will prepare the server-side change and tests.

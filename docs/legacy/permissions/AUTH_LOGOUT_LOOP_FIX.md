> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Authentication Logout Loop Fix

## Problem Summary

The Angular frontend was experiencing an infinite logout loop caused by circular token refresh attempts when WebSocket connections closed.

### Error Pattern

```
POST http://localhost:4200/api/auth/refresh 401 (Unauthorized)
[AuthService] Token refresh failed: HttpErrorResponse {status: 401, ...}
[AuthService] Refresh token invalid, logging out
[WebSocket] Unable to refresh token on close
GET http://localhost:4200/ws-sockjs/info?token=<expired_token> 401 (Unauthorized)
```

### Root Cause

**Circular Refresh Loop:**

1. Access token expires (15 minutes)
2. ❌ WebSocket connection closes due to expired token
3. ❌ `socket.service.ts` onWebSocketClose handler tries to refresh token
4. ❌ Refresh attempt uses **already-expired** refresh token
5. ❌ Backend returns 401 Unauthorized
6. ❌ AuthService logs out user
7. ❌ WebSocket tries to reconnect with expired token
8. 🔁 Loop repeats infinitely

**Multiple Concurrent Refreshes:**
- Multiple components/services could trigger refresh simultaneously
- No deduplication → multiple 401 failures → instant logout

## Solution Implemented

### 1. **Removed Token Refresh from WebSocket Handlers** ✅

**Before (socket.service.ts):**
```typescript
onWebSocketClose: async () => {
  this.setDisconnected('WebSocket closed');
  const newTok = await this.authService.refreshToken(); // ❌ Bad
  const t = newTok ?? this.authService.getToken();
  if (t) {
    this.ensureClient(t);
  }
}
```

**After:**
```typescript
onWebSocketClose: () => {
  this.setDisconnected('WebSocket closed');
  // Don't attempt refresh here - let AuthInterceptor handle it
  const currentToken = this.authService.getToken();
  if (currentToken && !this.authService.isTokenExpired(currentToken)) {
    console.log('[WebSocket] Scheduling reconnect with current token');
    setTimeout(() => this.ensureClient(currentToken), 3000);
  } else {
    console.warn('[WebSocket] No valid token for reconnect');
  }
}
```

**Why:** WebSocket layer should NOT manage token lifecycle. AuthInterceptor already handles automatic token refresh for HTTP requests.

### 2. **Added Refresh Deduplication** ✅

**Before (auth.service.ts):**
```typescript
async refreshToken(): Promise<string | null> {
  const refreshToken = this.getRefreshToken();
  // ... refresh logic
  // ❌ Multiple concurrent calls = multiple 401s
}
```

**After:**
```typescript
private isRefreshing = false;
private refreshPromise: Promise<string | null> | null = null;

async refreshToken(): Promise<string | null> {
  // Prevent concurrent refresh attempts
  if (this.isRefreshing && this.refreshPromise) {
    console.log('[AuthService] Refresh already in progress, waiting...');
    return this.refreshPromise; // Return same promise
  }

  this.isRefreshing = true;
  this.refreshPromise = (async () => {
    try {
      // ... refresh logic
    } finally {
      this.isRefreshing = false;
      this.refreshPromise = null;
    }
  })();

  return this.refreshPromise;
}
```

**Why:** Prevents race conditions where 5+ components trigger refresh simultaneously, causing multiple 401s and instant logout.

### 3. **Simplified WebSocket Token Validation** ✅

**Before:**
```typescript
private ensureClient(token: string): void {
  if (this.authService.isTokenExpired(token)) {
    this.authService.refreshToken().then((newTok) => { // ❌ Recursive refresh
      if (newTok) {
        this.ensureClient(newTok);
      }
    });
    return;
  }
  // ...
}
```

**After:**
```typescript
private ensureClient(token: string): void {
  // Don't connect with expired token
  if (this.authService.isTokenExpired(token)) {
    console.warn('[WebSocket] Token is expired, cannot connect. User needs to refresh token through normal flow.');
    return; // Just fail gracefully
  }
  // ...
}
```

**Why:** WebSocket should only connect with valid tokens. Token refresh happens through HTTP interceptor.

## Architecture Overview

### Correct Token Refresh Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER MAKES REQUEST                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │   AuthInterceptor       │
         │  Check Token Expiry     │
         └─────────┬───────────────┘
                   │
         ┌─────────▼──────────┐
         │ Token Expired?     │
         └─────────┬──────────┘
                   │
         YES ◄─────┼─────► NO
          │                  │
          ▼                  ▼
    ┌──────────────┐   ┌──────────────┐
    │ Refresh Token│   │ Add Bearer   │
    │ (Deduped)    │   │ Token Header │
    └──────┬───────┘   └──────┬───────┘
           │                  │
           ▼                  │
    ┌──────────────┐         │
    │ POST /refresh│         │
    │ with Refresh │         │
    │ Token        │         │
    └──────┬───────┘         │
           │                 │
     ┌─────▼──────┐         │
     │ 200 OK?    │         │
     └─────┬──────┘         │
           │                │
    YES ◄──┼──► NO         │
     │           │          │
     ▼           ▼          │
┌─────────┐  ┌────────┐    │
│ Update  │  │ Logout │    │
│ Token   │  └────────┘    │
└────┬────┘                │
     │                     │
     │◄────────────────────┘
     ▼
┌──────────────┐
│ Retry Request│
└──────────────┘
```

### WebSocket Connection Flow (Fixed)

```
┌────────────────────────────────────────┐
│  Component calls connect(driverIds)    │
└─────────────────┬──────────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │ Get Token from │
         │ localStorage   │
         └────────┬───────┘
                  │
         ┌────────▼────────┐
         │ Token Valid?    │
         └────────┬────────┘
                  │
         YES ◄────┼───► NO
          │               │
          ▼               ▼
    ┌──────────┐    ┌─────────────┐
    │ Connect  │    │ Don't Connect│
    │ WebSocket│    │ Log Warning │
    └──────┬───┘    └─────────────┘
           │
           ▼
    ┌──────────────┐
    │ Connection   │
    │ Established  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Subscribe to │
    │ Topics       │
    └──────────────┘

If Connection Closes:
    │
    ▼
┌──────────────┐
│ Get Current  │
│ Token Again  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Schedule     │
│ Reconnect    │
│ (3s delay)   │
└──────────────┘

❌ REMOVED: Auto-refresh on close
NEW: Use current token only
```

## Testing & Verification

### Before Fix (Broken Behavior)
```bash
# Symptoms:
1. User logged in successfully
2. After ~15 minutes (access token expires)
3. WebSocket closes
4. Multiple refresh attempts (401 401 401)
5. User immediately logged out
6. Login page appears unexpectedly
```

### After Fix (Expected Behavior)
```bash
# Expected:
1. User logged in successfully
2. After ~15 minutes (access token expires)
3. Next HTTP request triggers refresh (via AuthInterceptor)
4. Refresh succeeds (if refresh token still valid)
5. WebSocket reconnects with new token
6. User stays logged in for 30 days (refresh token lifetime)

# If refresh token also expired:
1. User logged in successfully
2. After 30 days (refresh token expires)
3. Next HTTP request triggers refresh
4. Refresh fails (401)
5. User logged out gracefully
6. Redirected to login page
```

### How to Test

1. **Normal Flow:**
   ```bash
   # Start Angular dev server
   cd tms-frontend
   npm start
   
   # Login as admin
   # Open browser console
   # Wait 15+ minutes
   # Navigate to different pages
   # Verify: No logout, token refreshes automatically
   ```

2. **Expired Token Simulation:**
   ```javascript
   // In browser console after login:
   
   // Get current token
   const token = localStorage.getItem('token');
   
   // Manually expire it (modify expiry in JWT payload)
   const parts = token.split('.');
   const payload = JSON.parse(atob(parts[1]));
   payload.exp = Math.floor(Date.now() / 1000) - 60; // 1 minute ago
   const expiredToken = parts[0] + '.' + btoa(JSON.stringify(payload)) + '.' + parts[2];
   localStorage.setItem('token', expiredToken);
   
   // Make a request or wait for WebSocket
   // Verify: AuthInterceptor refreshes token, no logout
   ```

3. **Monitor Console Logs:**
   ```
   Good Logs:
   [AuthInterceptor] Token expired. Attempting refresh...
   [AuthService] Token refresh successful
   [WebSocket] Scheduling reconnect with current token
   
   ❌ Bad Logs (should not see):
   [AuthService] Refresh already in progress (multiple times rapidly)
   [WebSocket] Unable to refresh token on close
   POST /api/auth/refresh 401 (multiple times)
   [AuthService] Refresh token invalid, logging out
   ```

## Backend Configuration (Already Correct)

The backend correctly permits `/api/auth/refresh`:

**SecurityConfig.java:**
```java
.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/auth/**", ...).permitAll()  // Includes /refresh
    .anyRequest().authenticated()
)
```

**AuthController.java:**
```java
@PostMapping("/refresh")
public ResponseEntity<ApiResponse<Map<String, Object>>> refresh(
    @RequestHeader(value = "Authorization", required = false) String authHeader) {
  // Validates refresh token
  // Rotates tokens
  // Returns new access + refresh tokens
}
```

## Token Lifetimes

| Token Type       | Lifetime  | Purpose                         |
|------------------|-----------|----------------------------------|
| Access Token     | 15 minutes| API authentication              |
| Refresh Token    | 30 days   | Obtain new access tokens        |
| Auto-refresh     | 13 minutes| Refresh 2 min before expiry     |

## Files Modified

1. **tms-frontend/src/app/services/auth.service.ts**
   - Added `isRefreshing` flag
   - Added `refreshPromise` deduplication
   - Wrapped refresh logic in promise

2. **tms-frontend/src/app/services/socket.service.ts**
   - Removed refresh attempts from `onWebSocketClose`
   - Removed refresh attempts from `onWebSocketError`
   - Simplified `ensureClient` to validate only
   - Added token validation before reconnect

## Rollback Plan

If issues occur, revert with:

```bash
cd tms-frontend
git checkout HEAD~1 -- src/app/services/auth.service.ts src/app/services/socket.service.ts
```

## Additional Improvements (Future)

### 1. Token Refresh Before Expiry
Currently auto-refresh runs 2 minutes before expiry. Consider:
- Visual warning at 5 minutes
- Background refresh at 10 minutes
- Failsafe refresh at 2 minutes

### 2. Refresh Token Rotation Monitoring
Log refresh token rotations for security auditing:
```typescript
console.info('[Auth] Token rotated', {
  oldRefreshTokenId: oldId,
  newRefreshTokenId: newId,
  userId: user.id
});
```

### 3. Connection Health Monitoring
Add heartbeat to detect stale WebSocket connections:
```typescript
setInterval(() => {
  if (this.isConnected) {
    this.stompClient.publish({
      destination: '/app/heartbeat',
      body: JSON.stringify({ timestamp: Date.now() })
    });
  }
}, 30000); // Every 30s
```

## Conclusion

The logout loop is fixed by:
- Removing WebSocket-layer token refresh attempts
- Adding refresh deduplication in AuthService
- Letting AuthInterceptor handle all token refresh logic
- WebSocket reconnects only with valid tokens

**Result:** Users stay logged in for the full 30-day refresh token lifetime instead of being logged out after 15 minutes.

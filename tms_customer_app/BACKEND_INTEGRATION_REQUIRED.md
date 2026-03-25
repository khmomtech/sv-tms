# Backend Integration Required for Customer App

## IMPLEMENTATION COMPLETE

### Status: Ready for Testing

The critical blocker has been **RESOLVED**. The backend now includes `customerId` in the login response for CUSTOMER role users.

**See**: `/CUSTOMER_ID_IMPLEMENTATION_GUIDE.md` for complete testing and deployment instructions.

---

## Implementation Summary

### Changes Made

#### Backend (tms-backend)

1. **User.java** - Added bidirectional customer relationship:
```java
@OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
private Customer customer;
```

2. **UserRepository.java** - Updated queries to eagerly fetch customer:
```java
"SELECT DISTINCT u FROM User u "
    + "LEFT JOIN FETCH u.roles r "
    + "LEFT JOIN FETCH r.permissions "
    + "LEFT JOIN FETCH u.customer "  // ← Added
    + "WHERE u.username = :username"
```

3. **AuthController.java** - Modified login response to include customerId:
```java
// Add customerId for CUSTOMER role users
if (user.getRoles().stream().anyMatch(r -> r.getName().toString().equals("CUSTOMER"))) {
  if (user.getCustomer() != null) {
    userInfo.put("customerId", user.getCustomer().getId());
  }
}
```

#### Mobile App (tms_customer_app)

Already prepared with optional `customerId` field:
```dart
class UserInfo {
  final int? customerId; // Receives from backend
  // ... other fields
}
```

---

## Original Problem Description (RESOLVED)

~~The customer app cannot call `/api/customer/{customerId}/*` endpoints because the login response does not include `customerId` for users with `CUSTOMER` role.~~

**Resolution**: Login response now includes `customerId` when user has CUSTOMER role and is linked to a customer record.

### Expected Response Format (NOW IMPLEMENTED)

```json
{
  "code": "LOGIN_SUCCESS",
  "message": "Login successful",
  "token": "eyJhbGci...",
  "refreshToken": "eyJhbGci...",
  "user": {
    "username": "customer@example.com",
    "email": "customer@example.com",
    "roles": ["USER", "CUSTOMER"],
    "permissions": ["order:read", "order:create"],
    "customerId": 123  // Now included
  }
}
```

---

## Related Backend Endpoints That Need `customerId`

From `CustomerPublicController.java`:

1. **GET /api/customers/{customerId}/orders**
   - Security: Checks `authenticatedUserUtil.getCurrentCustomerId()` matches path `{customerId}`
   - Mobile needs `customerId` from login to call this

2. **GET /api/customers/{customerId}/orders/{orderId}**
   - Security: Same ownership check
   - Requires `customerId` from login

3. **GET /api/customers/{customerId}/addresses**
   - Security: Same ownership check
   - Requires `customerId` from login

### Security Note
Backend already validates that authenticated user owns the `customerId` via:
```java
var optCid = authenticatedUserUtil.getCurrentCustomerId();
if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(...);
}
```

This means `getCurrentCustomerId()` method must return the customer ID associated with the authenticated user — the login response should expose the same value to the mobile app.

## Non-Blocking Items (Future Enhancements)

### 1. WebSocket URL Configuration
**Status**: Fixed in customer app
- Mobile app now derives WebSocket URL from `API_BASE_URL` environment variable
- `http://api.example.com` → `ws://api.example.com/ws`
- `https://api.example.com` → `wss://api.example.com/ws`

No backend changes required.

### 2. Automatic Token Refresh on 401
**Status**: Not critical for v1
- Access tokens expire in 15 minutes
- Refresh tokens last 30 days
- Most customer sessions are short-lived

Can be added later as mobile interceptor if needed.

### 3. Customer Registration Endpoint
**Status**: Intentionally requires ADMIN role
- Backend `/api/auth/register` requires ADMIN role
- Customer signup flow should go through admin portal or separate onboarding process

No change needed.

## Testing Checklist

Once backend fix is deployed:

- [ ] Login with CUSTOMER role user returns `customerId` in response
- [ ] `GET /api/customers/{customerId}/orders` works with returned `customerId`
- [ ] Attempting to access another customer's orders returns 403
- [ ] WebSocket connection includes customer-specific notifications
- [ ] Token refresh maintains `customerId` in refreshed user info

## Questions for Backend Team

1. **User-Customer Relationship**: 
   - Does `User` entity have a direct relationship to `Customer` entity?
   - Or is there a `customer_id` column in `users` table?
   - How should we retrieve the customer ID for a CUSTOMER role user?

2. **Customer ID Type**:
   - Is it `Long` (like `driverId`) or `String`?
   - Mobile app assumes `int` (Dart equivalent of Java `Long`)

3. **Token Refresh**:
   - When refreshing tokens via `/api/auth/refresh`, should response include updated user info with `customerId`?
   - Or does refresh only return new access token?

## Contact

For questions about mobile app requirements:
- Customer app repo: `tms_customer_app/`
- Copilot instructions: `tms_customer_app/.github/copilot-instructions.md`
- This document: `tms_customer_app/BACKEND_INTEGRATION_REQUIRED.md`

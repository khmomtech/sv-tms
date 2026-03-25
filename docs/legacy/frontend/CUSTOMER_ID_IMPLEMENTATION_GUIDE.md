> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Customer ID Implementation - Testing & Deployment Guide

## Implementation Complete

### Changes Made

#### 1. Backend Changes (tms-backend)

**User.java** - Added bidirectional relationship to Customer:
```java
/** Optional customer association for CUSTOMER role users */
@OneToOne(mappedBy = "user", fetch = FetchType.LAZY)
private Customer customer;
```

**UserRepository.java** - Updated queries to fetch customer eagerly:
```java
@Query(
    "SELECT DISTINCT u FROM User u "
        + "LEFT JOIN FETCH u.roles r "
        + "LEFT JOIN FETCH r.permissions "
        + "LEFT JOIN FETCH u.customer "  // ← Added this line
        + "WHERE u.username = :username")
Optional<User> findByUsernameWithRoles(@Param("username") String username);
```

**AuthController.java** - Modified login response to include customerId:
```java
// Build user info map with optional customerId
Map<String, Object> userInfo = new HashMap<>();
userInfo.put("username", user.getUsername());
userInfo.put("email", user.getEmail());
userInfo.put("roles", user.getRoles().stream().map(r -> r.getName().toString()).toList());
userInfo.put("permissions", effectivePermissions);

// Add customerId for CUSTOMER role users
if (user.getRoles().stream().anyMatch(r -> r.getName().toString().equals("CUSTOMER"))) {
  if (user.getCustomer() != null) {
    userInfo.put("customerId", user.getCustomer().getId());
  }
}

response.put("user", userInfo);
```

#### 2. Mobile App Changes (customer_app)

**auth_models.dart** - Already prepared to receive customerId:
```dart
class UserInfo {
  final String username;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final int? customerId; // Ready to receive from backend
  
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      // ... other fields
      customerId: json['customerId'] as int?,
    );
  }
}
```

**notification_provider.dart** - WebSocket URL now dynamic:
```dart
static String _convertToWsUrl(String httpUrl) {
  final uri = Uri.parse(httpUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  return '$scheme://${uri.host}:${uri.port}/ws';
}
```

## Testing Checklist

### Prerequisites

1. **Create test customer user in database**:
```sql
-- Insert customer record
INSERT INTO customers (name, email, phone, address, type, status, customer_code)
VALUES ('Test Customer', 'customer@test.com', '+1234567890', '123 Test St', 'INDIVIDUAL', 'ACTIVE', 'CUST001');

-- Get the customer ID
SET @customer_id = LAST_INSERT_ID();

-- Create user account
INSERT INTO users (username, password, email, enabled, account_non_locked, account_non_expired, credentials_non_expired)
VALUES ('testcustomer', '$2a$10$encrypted_password_hash', 'customer@test.com', 1, 1, 1, 1);

-- Get the user ID
SET @user_id = LAST_INSERT_ID();

-- Link customer to user
UPDATE customers SET user_id = @user_id WHERE id = @customer_id;

-- Assign CUSTOMER role
INSERT INTO user_roles (user_id, role_id)
SELECT @user_id, id FROM roles WHERE name = 'CUSTOMER';
```

2. **Start backend**:
```bash
cd tms-backend
./mvnw clean package
./mvnw spring-boot:run
```

3. **Verify backend is running**:
```bash
curl http://localhost:8080/actuator/health
# Should return: {"status":"UP"}
```

### Test 1: Login Response Includes CustomerId

**Request**:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testcustomer",
    "password": "your_password"
  }'
```

**Expected Response**:
```json
{
  "code": "LOGIN_SUCCESS",
  "message": "Login successful",
  "user": {
    "username": "testcustomer",
    "email": "customer@test.com",
    "roles": ["CUSTOMER"],
    "permissions": ["order:read", "order:create", ...],
    "customerId": 1  // This should be present
  },
  "token": "eyJhbGci...",
  "refreshToken": "eyJhbGci..."
}
```

**Pass Criteria**:
- Response contains `customerId` field in `user` object
- `customerId` matches the customer ID from database
- Login succeeds with 200 status

### Test 2: Customer API Endpoints Work

**Request** (use token from Test 1):
```bash
export TOKEN="eyJhbGci..."
export CUSTOMER_ID=1

curl -X GET "http://localhost:8080/api/customers/${CUSTOMER_ID}/orders" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Expected Response**:
```json
{
  "content": [...],
  "totalElements": 0,
  "totalPages": 0,
  "size": 20,
  "number": 0
}
```

**Pass Criteria**:
- Request returns 200 (not 403 or 401)
- Can access own customer data with customerId from login

### Test 3: Cannot Access Other Customer Data

**Request**:
```bash
export TOKEN="eyJhbGci..."
export OTHER_CUSTOMER_ID=999  # Different customer ID

curl -X GET "http://localhost:8080/api/customers/${OTHER_CUSTOMER_ID}/orders" \
  -H "Authorization: Bearer ${TOKEN}"
```

**Expected Response**:
```json
{
  "code": "FORBIDDEN",
  "message": "You do not have permission to access this customer's data",
  "timestamp": "2025-12-02T..."
}
```

**Pass Criteria**:
- Request returns 403 Forbidden
- Security validation prevents accessing other customers' data

### Test 4: Mobile App Login (Flutter)

**Setup**:
```bash
cd customer_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**Test Steps**:
1. Launch app on Android emulator/iOS simulator
2. Login with test customer credentials
3. Check logs for login response

**Expected Logs**:
```
flutter: 🔐 Login response: LoginResponse{user: UserInfo{username: testcustomer, email: customer@test.com, roles: [CUSTOMER], permissions: [...], customerId: 1, ...}, token: eyJhbGci..., refreshToken: eyJhbGci...}
flutter: 🔌 Connecting to WebSocket: ws://10.0.2.2:8080/ws?token=***
flutter: WebSocket Connected
```

**Pass Criteria**:
- Login succeeds in mobile app
- `customerId` is logged in the response
- WebSocket connects successfully
- No errors in console

### Test 5: WebSocket Notifications (Customer-Specific)

**Backend Action**: Create order/notification for customer ID 1

**Expected in Mobile App**:
```
flutter: 🔔 Received notification: {id: 123, title: "Order Update", message: "Your order has been confirmed", ...}
```

**Pass Criteria**:
- Mobile app receives notifications via WebSocket
- Notifications are customer-specific

### Test 6: Token Refresh Maintains CustomerId

**Request**:
```bash
export REFRESH_TOKEN="eyJhbGci..."

curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"${REFRESH_TOKEN}\"}"
```

**Expected Response**:
```json
{
  "token": "eyJhbGci...",
  "refreshToken": "eyJhbGci..."
}
```

**Note**: Current `/api/auth/refresh` only returns tokens, not user info. If you need customerId to persist across refresh, update the refresh endpoint to return user info as well.

**Pass Criteria**:
- New access token is issued
- Mobile app can continue making authenticated requests

## Production Deployment

### 1. Database Schema Verification

Ensure `customers` table has `user_id` column:
```sql
DESCRIBE customers;
-- Should show: user_id BIGINT (or similar)

-- Check for foreign key constraint
SHOW CREATE TABLE customers;
-- Should include: CONSTRAINT `fk_customer_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
```

If missing, add the column and constraint:
```sql
ALTER TABLE customers 
ADD COLUMN user_id BIGINT UNIQUE,
ADD CONSTRAINT fk_customer_user 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
```

### 2. Build & Deploy Backend

```bash
cd tms-backend
./mvnw clean package -DskipTests
# Deploy the JAR from target/logistics-0.0.1-SNAPSHOT.jar
```

### 3. Test Production Endpoints

```bash
curl -X POST https://your-api.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "customer@example.com", "password": "..."}'
  
# Verify customerId is in response
```

### 4. Deploy Mobile App

```bash
cd customer_app

# Android
flutter build apk --dart-define=API_BASE_URL=https://your-api.com --release

# iOS
flutter build ios --dart-define=API_BASE_URL=https://your-api.com --release
```

### 5. Monitor Logs

Check backend logs for:
```
User found: testcustomer, roles count: 1
JWT authentication successful for user: testcustomer
WebSocket auth passed for: testcustomer
```

Check mobile logs for:
```
🔐 Login response: LoginResponse{..., customerId: 1, ...}
🔌 Connecting to WebSocket: wss://your-api.com/ws?token=***
WebSocket Connected
```

## Rollback Plan

If issues occur in production:

1. **Revert AuthController.java** to not include customerId:
```java
response.put("user", Map.of(
    "username", user.getUsername(),
    "email", user.getEmail(),
    "roles", user.getRoles().stream().map(r -> r.getName().toString()).toList(),
    "permissions", effectivePermissions));
```

2. **Redeploy backend** with reverted code
3. **Mobile app** will gracefully handle missing customerId (field is optional `int?`)

## Known Limitations

1. **User without Customer record**: If a user has CUSTOMER role but no linked customer record in the database, `customerId` will be `null` in the response. This is expected behavior.

2. **Multiple roles**: If a user has both DRIVER and CUSTOMER roles, only customerId will be included (not driverId). This is an edge case that should be handled if needed.

3. **Token refresh**: Current implementation doesn't return user info on token refresh. If the mobile app needs to re-fetch user data after refresh, it should call a `/api/auth/me` endpoint (if available).

## Troubleshooting

### Issue: customerId is null in response despite user having CUSTOMER role

**Check**:
```sql
SELECT u.id, u.username, c.id as customer_id, c.user_id
FROM users u
LEFT JOIN customers c ON c.user_id = u.id
WHERE u.username = 'testcustomer';
```

**Expected**: `customer_id` and `user_id` should match
**Fix**: Update customer record to link to user:
```sql
UPDATE customers SET user_id = ? WHERE id = ?;
```

### Issue: LazyInitializationException on user.getCustomer()

**Cause**: Customer relationship not fetched eagerly
**Fix**: Verify `UserRepository.findByUsernameWithRoles()` includes `LEFT JOIN FETCH u.customer`

### Issue: Mobile app doesn't receive customerId

**Check**:
1. Backend logs show customerId in login response
2. Mobile app logs show full response JSON
3. `UserInfo.fromJson()` correctly parses `customerId` field

**Debug**:
```dart
print('Raw login response JSON: ${response.data}');
print('Parsed customerId: ${userInfo.customerId}');
```

## Success Metrics

After deployment, verify:
- Customer users can login via mobile app
- `customerId` is present in login response for CUSTOMER role users
- Customer can access `/api/customers/{customerId}/orders` endpoint
- 403 errors occur when accessing other customers' data
- WebSocket connections work with `wss://` for HTTPS
- No LazyInitializationException errors in backend logs

## Next Steps (Optional Enhancements)

1. **Auto-refresh on 401**: Implement HTTP interceptor in mobile app to auto-refresh tokens
2. **Secure storage**: Replace SharedPreferences with flutter_secure_storage for production
3. **Customer registration**: Add `/api/public/register` endpoint for self-service signup
4. **Token refresh user info**: Update `/api/auth/refresh` to return updated user info including customerId
5. **Multi-role support**: Handle users with both DRIVER and CUSTOMER roles (rare edge case)

## Contact

For issues or questions:
- Backend team: Check `tms-backend/` repository
- Mobile team: Check `customer_app/` repository
- Integration docs: `customer_app/BACKEND_INTEGRATION_REQUIRED.md`
- This guide: `CUSTOMER_ID_IMPLEMENTATION_GUIDE.md`

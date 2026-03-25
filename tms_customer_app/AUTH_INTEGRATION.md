# Customer App Authentication Integration

This document describes the customer login authentication API integration with the Flutter customer app.

## Overview

The customer app now integrates with the backend authentication API (`/api/auth/login`) to authenticate users and manage sessions.

## Architecture

### Backend API Endpoint

- **URL**: `POST /api/auth/login`
- **Request Body**:
  ```json
  {
    "username": "user@example.com",
    "password": "password123"
  }
  ```
- **Response** (Success - 200 OK):
  ```json
  {
    "code": "LOGIN_SUCCESS",
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "username": "user@example.com",
      "email": "user@example.com",
      "roles": ["USER", "CUSTOMER"],
      "permissions": ["order:read", "order:create"]
    }
  }
  ```
- **Response** (Error - 401 Unauthorized):
  ```json
  {
    "error": "Invalid username or password"
  }
  ```

### Flutter Implementation

#### File Structure

```
tms_customer_app/lib/
├── models/
│   └── auth_models.dart          # LoginRequest, LoginResponse, UserInfo models
├── services/
│   ├── auth_service.dart         # Authentication service with API calls
│   └── local_storage.dart        # Token and user info persistence
├── providers/
│   └── auth_provider.dart        # State management for authentication
├── screens/
│   └── login/
│       └── login_screen.dart     # Login UI with real API integration
└── constants/
    └── api_constants.dart        # API endpoints and configuration
```

## Components

### 1. AuthModels (`lib/models/auth_models.dart`)

**LoginRequest**: Represents the login request payload
- `username`: User's email/username
- `password`: User's password
- `deviceId`: Optional device identifier

**LoginResponse**: Represents the successful login response
- `code`: Response code (e.g., "LOGIN_SUCCESS")
- `message`: Response message
- `token`: JWT access token
- `refreshToken`: JWT refresh token (optional)
- `user`: User information object

**UserInfo**: Represents authenticated user data
- `username`: User's username
- `email`: User's email
- `roles`: List of user roles
- `permissions`: List of user permissions

**AuthException**: Custom exception for authentication errors
- `code`: Error code
- `message`: Error message

### 2. AuthService (`lib/services/auth_service.dart`)

Handles all authentication operations:

**Methods**:
- `login(username, password)`: Authenticates user and returns LoginResponse
- `logout()`: Clears stored credentials and user data
- `tryRestore()`: Attempts to restore authentication from stored token
- `getToken()`: Returns current auth token

**Error Handling**:
- Network errors → `AuthException` with code "NETWORK_ERROR"
- Invalid credentials → `AuthException` with server error message
- Unknown errors → `AuthException` with code "UNKNOWN_ERROR"

### 3. LocalStorage (`lib/services/local_storage.dart`)

Manages persistent storage using SharedPreferences:

**Token Management**:
- `saveToken(token)` / `getToken()` / `clearToken()`
- `saveRefreshToken(token)` / `getRefreshToken()` / `clearRefreshToken()`

**User Info Management**:
- `saveUserInfo(userInfo)` / `getUserInfo()` / `clearUserInfo()`

### 4. AuthProvider (`lib/providers/auth_provider.dart`)

State management provider using ChangeNotifier:

**Properties**:
- `isAuthenticated`: Boolean indicating auth status
- `currentUser`: Current user information (UserInfo)

**Methods**:
- `login(username, password)`: Delegates to AuthService
- `logout()`: Clears authentication
- `tryRestore()`: Restores session on app start

### 5. LoginScreen (`lib/screens/login/login_screen.dart`)

Updated UI implementation:

**Features**:
- Email/username and password input validation
- Real API integration with error handling
- User-friendly error messages with translations
- Loading state during authentication
- Navigation to home screen on success

**Error Display**:
- Network errors show localized "networkError" message
- Invalid credentials show "invalidCredentials" message
- Other errors display the server message

## Configuration

### API Base URL

Edit `lib/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080'; // Change for production
  // ...
}
```

### Timeouts

Default timeouts are configured in `ApiConstants`:
- Connect timeout: 10 seconds
- Receive timeout: 30 seconds

## Translations

Both English and Khmer translations are supported:

**New Translation Keys**:
- `invalidCredentials`: "Invalid username or password"
- `networkError`: "Network error. Please check your connection and try again"

Files:
- `assets/lang/en.json`
- `assets/lang/km.json`

## Usage Example

### In Login Screen:

```dart
Future<void> _handleLogin() async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    // Navigate to home on success
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  } catch (e) {
    // Handle and display error
    setState(() {
      _errorMessage = e.toString();
    });
  }
}
```

### Checking Auth Status:

```dart
final authProvider = Provider.of<AuthProvider>(context);
if (authProvider.isAuthenticated) {
  // User is logged in
  final user = authProvider.currentUser;
  print('Logged in as: ${user?.username}');
}
```

### Getting Auth Token:

```dart
final token = await authProvider.getToken();
// Use token for API requests
```

## Testing

### Test Credentials

Use the backend's registered users or create test accounts via the admin panel.

### Testing Flow

1. Start the backend: `cd driver-app && ./mvnw spring-boot:run`
2. Run the Flutter app: `cd tms_customer_app && flutter run`
3. Enter credentials on login screen
4. Verify successful authentication and navigation
5. Check that token is persisted (app restart should maintain session)

## Security Notes

1. **Token Storage**: Tokens are stored in SharedPreferences (plaintext on device). For production, consider using flutter_secure_storage.
2. **HTTPS**: Always use HTTPS in production to encrypt credentials in transit.
3. **Token Refresh**: The refresh token is stored but automatic refresh is not yet implemented.
4. **Password Validation**: Client-side validation is minimal (6+ characters). Backend enforces stronger rules.

## Future Enhancements

1. Implement automatic token refresh using refresh token
2. Add biometric authentication option
3. Implement "Remember Me" functionality properly
4. Add password strength indicator
5. Implement forgot password flow
6. Add device registration for additional security
7. Use flutter_secure_storage for production token storage

## Troubleshooting

**Network Error**:
- Check backend is running on correct URL
- Verify API base URL in `api_constants.dart`
- Check network connectivity

**Invalid Credentials**:
- Verify user exists in database
- Check password is correct
- Ensure user account is enabled

**Token Not Persisting**:
- Check SharedPreferences initialization
- Verify `tryRestore()` is called on app start

## Related Files

- Backend: `driver-app/src/main/java/com/svtrucking/logistics/controller/AuthController.java`
- Backend DTO: `driver-app/src/main/java/com/svtrucking/logistics/dto/LoginRequest.java`
- OpenAPI Spec: `api/driver-app-openapi.json`

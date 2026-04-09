# Error Handling Improvements Report

**Date**: 2025-01-20  
**Scope**: Error handling patterns across driver_app  
**Status**: Good foundation with opportunities for improvement

---

## 📊 CURRENT ERROR HANDLING ANALYSIS

### Error Handling Services Identified

1. **RequestHelper** (`lib/core/request_helper.dart`)
   - Purpose: HTTP request wrapper with error formatting
   - Features: Status code parsing, error message extraction
   - Used by: Multiple services

2. **ErrorHandler** (`lib/core/error_handler.dart` - if exists)
   - Purpose: Centralized error handling
   - Features: TBD (need to verify existence)

3. **DioClient** (`lib/core/network/dio_client.dart`)
   - Purpose: HTTP client with retry logic and interceptors
   - Features: Automatic retry, token refresh, error logging
   - Status: Well-implemented

---

## 🟢 EXCELLENT PRACTICES FOUND

### 1. Retry Logic in DioClient

```dart
// EXCELLENT - Automatic retry with exponential backoff
class DioClient {
  Future<T> _retry<T>(Future<T> Function() fn, {int maxRetries = 2}) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        final backoff = Duration(milliseconds: 400 * (1 << attempt));
        await Future.delayed(backoff);
        attempt++;
      }
    }
  }
}
```

**Impact**: Resilient to transient network failures

### 2. Provider-Level Error Handling

```dart
// GOOD - Providers catch and expose errors
class DispatchProvider with ChangeNotifier {
  String? _error;
  String? get error => _error;
  
  Future<void> fetchDispatches() async {
    try {
      _error = null;
      final response = await _dio.get('/api/driver/dispatches');
      _dispatches = response.data;
    } catch (e) {
      _error = e.toString();
      debugPrint('[DispatchProvider] Error: $e');
    } finally {
      notifyListeners();
    }
  }
}
```

**Impact**: UI can react to errors appropriately

### 3. Try-Catch in User Actions

```dart
// GOOD - User-facing actions have error handling
Future<void> onSubmit() async {
  try {
    await provider.submitDispatch(data);
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e')),
    );
  }
}
```

---

## 🟡 IMPROVEMENT OPPORTUNITIES

### Opportunity 1: Consolidate Error Handling Services

**Current State**: Potentially multiple error handling approaches

**Recommended**: Single source of truth

```dart
// lib/core/error/app_error.dart
class AppError {
  final String code;
  final String message;
  final String? userMessage; // Localized message for users
  final dynamic originalError;
  final ErrorSeverity severity;

  const AppError({
    required this.code,
    required this.message,
    this.userMessage,
    this.originalError,
    this.severity = ErrorSeverity.error,
  });

  factory AppError.fromDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return AppError(
        code: 'NETWORK_TIMEOUT',
        message: 'Connection timeout',
        userMessage: 'network.timeout'.tr(), // Localized
        severity: ErrorSeverity.warning,
      );
    }
    
    if (e.response?.statusCode == 401) {
      return AppError(
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
        userMessage: 'error.unauthorized'.tr(),
        severity: ErrorSeverity.critical,
      );
    }
    
    return AppError(
      code: 'NETWORK_ERROR',
      message: e.message ?? 'Unknown error',
      userMessage: 'error.generic'.tr(),
      originalError: e,
    );
  }

  factory AppError.fromException(dynamic e) {
    if (e is DioException) return AppError.fromDioError(e);
    
    return AppError(
      code: 'UNKNOWN_ERROR',
      message: e.toString(),
      userMessage: 'error.generic'.tr(),
      originalError: e,
    );
  }
}

enum ErrorSeverity {
  info,    // Show subtle notification
  warning, // Show warning dialog
  error,   // Show error dialog
  critical // Show error + force logout/restart
}
```

**Benefit**: Consistent error handling across app  
**Effort**: 2-3 hours  
**Priority**: HIGH

### Opportunity 2: Add Localized Error Messages

**Current**:
```dart
// ❌ NOT LOCALIZED
catch (e) {
  showSnackBar(context, 'Failed to load dispatches: $e');
}
```

**Improved**:
```dart
// LOCALIZED
catch (e) {
  final appError = AppError.fromException(e);
  showSnackBar(context, appError.userMessage ?? 'error.generic'.tr());
  
  // Log technical details for debugging
  debugPrint('[Error] ${appError.code}: ${appError.message}');
}
```

**Translation Keys** (`assets/translations/en.json`):
```json
{
  "error": {
    "generic": "Something went wrong. Please try again.",
    "network": {
      "timeout": "Connection timed out. Check your internet.",
      "offline": "You are offline. Please check your connection.",
      "server": "Server error. Please try again later."
    },
    "unauthorized": "Session expired. Please login again.",
    "forbidden": "You don't have permission for this action.",
    "not_found": "Resource not found.",
    "validation": "Please check your input and try again."
  }
}
```

**Benefit**: Better UX for Khmer and English speakers  
**Effort**: 3-4 hours  
**Priority**: MEDIUM-HIGH

### Opportunity 3: Global Error Handler Widget

**Current**: Error handling scattered across screens

**Improved**:
```dart
// lib/widgets/error_handler_widget.dart
class ErrorHandlerWidget extends StatelessWidget {
  final Widget child;
  
  const ErrorHandlerWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // Log to crashlytics
        // FirebaseCrashlytics.instance.recordError(error, stackTrace);
        
        // Show user-friendly error
        final appError = AppError.fromException(error);
        if (appError.severity == ErrorSeverity.critical) {
          _showErrorDialog(context, appError);
        } else {
          _showErrorSnackbar(context, appError);
        }
      },
      child: child,
    );
  }

  void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('error.critical.title'.tr()),
        content: Text(error.userMessage ?? 'error.generic'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally: restart app or logout
            },
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userMessage ?? 'error.generic'.tr()),
        backgroundColor: error.severity == ErrorSeverity.warning
            ? Colors.orange
            : Colors.red,
        duration: Duration(seconds: error.severity == ErrorSeverity.info ? 2 : 4),
        action: error.severity != ErrorSeverity.info
            ? SnackBarAction(
                label: 'common.retry'.tr(),
                onPressed: () {
                  // Retry logic
                },
              )
            : null,
      ),
    );
  }
}
```

**Usage**:
```dart
// Wrap MaterialApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ErrorHandlerWidget(
      child: MaterialApp(/* ... */),
    );
  }
}
```

**Benefit**: Consistent error UI across app  
**Effort**: 2-3 hours  
**Priority**: MEDIUM

### Opportunity 4: Add Offline Error Handling

**Current**: Generic network errors

**Improved**:
```dart
// lib/services/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get isOnline => _connectivity.onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
  
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// In DioClient
class DioClient {
  final ConnectivityService _connectivity = ConnectivityService();
  
  Future<Response> get(String path) async {
    // Check connectivity first
    if (!await _connectivity.checkConnection()) {
      throw AppError(
        code: 'OFFLINE',
        message: 'No internet connection',
        userMessage: 'error.network.offline'.tr(),
        severity: ErrorSeverity.warning,
      );
    }
    
    return await _dio.get(path);
  }
}
```

**Benefit**: Better offline UX  
**Effort**: 1-2 hours  
**Priority**: MEDIUM

### Opportunity 5: Add Error Logging & Crashlytics

**Current**: Only debugPrint() for errors

**Improved**:
```dart
// lib/core/error/error_logger.dart
class ErrorLogger {
  static Future<void> log(
    AppError error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Console logging (dev)
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[ERROR] ${error.code}: ${error.message}');
      if (context != null) debugPrint('[CONTEXT] $context');
      if (stackTrace != null) debugPrint('[STACK] $stackTrace');
      debugPrint('═══════════════════════════════════════');
    }
    
    // Crashlytics (production)
    if (!kDebugMode && error.severity == ErrorSeverity.critical) {
      await FirebaseCrashlytics.instance.recordError(
        error.originalError ?? error,
        stackTrace,
        reason: error.message,
        information: context?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );
    }
    
    // Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_error',
      parameters: {
        'error_code': error.code,
        'severity': error.severity.toString(),
        ...?context,
      },
    );
  }
}

// Usage in providers
catch (e, stackTrace) {
  final appError = AppError.fromException(e);
  await ErrorLogger.log(
    appError,
    stackTrace: stackTrace,
    context: {
      'provider': 'DispatchProvider',
      'method': 'fetchDispatches',
      'user_id': userProvider.user?.id,
    },
  );
  _error = appError.userMessage;
  notifyListeners();
}
```

**Benefit**: Better debugging and error tracking  
**Effort**: 2-3 hours  
**Priority**: HIGH

### Opportunity 6: Validation Error Handling

**Current**: Form validation errors not standardized

**Improved**:
```dart
// lib/core/validation/validators.dart
class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.required'.tr(namedArgs: {'field': fieldName ?? 'field'});
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'validation.email'.tr();
    }
    return null;
  }
  
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return 'validation.minLength'.tr(namedArgs: {
        'field': fieldName ?? 'field',
        'min': min.toString(),
      });
    }
    return null;
  }
  
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s'), ''))) {
      return 'validation.phone'.tr();
    }
    return null;
  }
}

// Usage in forms
TextFormField(
  validator: (value) => Validators.required(value, fieldName: 'Phone'),
  decoration: InputDecoration(labelText: 'form.phone'.tr()),
)
```

**Translation keys**:
```json
{
  "validation": {
    "required": "{{field}} is required",
    "email": "Please enter a valid email address",
    "phone": "Please enter a valid phone number",
    "minLength": "{{field}} must be at least {{min}} characters"
  }
}
```

**Benefit**: Consistent validation UX  
**Effort**: 1-2 hours  
**Priority**: MEDIUM

---

## 🔧 IMPLEMENTATION PLAN

### Phase 1: Foundation (Week 1)
1. Create `AppError` class with error types
2. Add error logging with context
3. Update DioClient to use AppError

### Phase 2: Localization (Week 2)
1. Add error translation keys (en/km)
2. Update all error messages to use translations
3. Test both languages

### Phase 3: UI Improvements (Week 3)
1. Create ErrorHandlerWidget
2. Add offline detection
3. Standardize error snackbars/dialogs

### Phase 4: Validation (Week 4)
1. Create Validators class
2. Update all forms to use validators
3. Add validation translation keys

---

## 📋 ERROR HANDLING CHECKLIST

- [ ] Consolidate error handling into AppError class
- [ ] Add localized error messages (en + km)
- [ ] Implement global ErrorHandlerWidget
- [ ] Add connectivity checking before API calls
- [ ] Integrate Firebase Crashlytics
- [ ] Standardize validation with localized messages
- [ ] Add retry buttons to error snackbars
- [ ] Test error scenarios (timeout, 401, 403, 404, 500, offline)
- [ ] Document error codes and user messages

---

## 🧪 TESTING RECOMMENDATIONS

### Test Scenarios:
1. **Network Errors**:
   - Timeout (airplane mode delay)
   - Connection refused (wrong URL)
   - DNS failure
   
2. **HTTP Errors**:
   - 400 Bad Request
   - 401 Unauthorized
   - 403 Forbidden
   - 404 Not Found
   - 500 Server Error
   
3. **App Errors**:
   - Null pointer exceptions
   - JSON parsing errors
   - File upload failures
   - Permission denied

### Testing Tools:
```bash
# Simulate network errors with proxy
# Use Charles Proxy or Proxyman to:
# - Throttle bandwidth
# - Return specific status codes
# - Delay responses

# Test offline mode
# - Enable airplane mode
# - Disable WiFi
# - Block app network access
```

---

## SUMMARY

**Current State**: GOOD  
The app has solid error handling foundations with try-catch blocks and retry logic.

**Improvements Available**:
- Consolidate error handling (HIGH priority)
- Add localization (MEDIUM-HIGH priority)
- Add offline detection (MEDIUM priority)
- Improve error logging (HIGH priority)
- Standardize validation (MEDIUM priority)

**Estimated Effort**: 12-16 hours total for all improvements

**Impact**: Significantly better user experience, especially for non-technical users and Khmer speakers

---

**Next Steps**:
1. Review and approve error handling architecture
2. Implement Phase 1 (AppError + logging)
3. Add translation keys
4. Test error scenarios thoroughly

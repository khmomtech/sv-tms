# Driver App - Code Quality Standards

## 📋 Overview

This document outlines the code quality standards and best practices for the Smart Truck Driver App Flutter project.

## 🏗️ Architecture

### Folder Structure
```
lib/
├── core/                    # Core functionality
│   ├── constants/           # App-wide constants and configuration
│   ├── exceptions/          # Custom exception classes
│   ├── mixins/             # Reusable mixins for common functionality
│   ├── network/            # API client, interceptors, response models
│   ├── services/           # Core services (error handling, storage)
│   └── utils/              # Utility functions and helpers
├── models/                  # Data models
├── providers/              # State management (Provider pattern)
├── screens/                # UI screens organized by feature
├── services/               # Business logic services
├── widgets/                # Reusable UI components
└── routes/                 # App routing configuration
```

### Key Design Patterns

1. **Provider Pattern**: State management using `package:provider`
2. **Repository Pattern**: Data access abstraction (coming soon)
3. **Dependency Injection**: Services injected through Provider
4. **Result Pattern**: Type-safe error handling with `Result<T>`

## 🔒 Security Best Practices

### Token Storage
- **DO**: Use `FlutterSecureStorage` for tokens
- ❌ **DON'T**: Store tokens in `SharedPreferences`
- **DO**: Clear tokens on logout
- **DO**: Implement token refresh logic

### API Security
- Use HTTPS for all API calls
- Implement certificate pinning (production)
- Add request timeouts
- Validate server responses
- Handle 401 errors with auto-refresh

### Data Validation
- Validate user input on client-side
- Sanitize data before sending to API
- Use strong typing (avoid `dynamic`)
- Implement proper null safety

## 🚀 Performance Optimization

### Image Handling
```dart
// Compress images before upload
final compressed = await ImageHelper.compressImage(file);

// Validate image size
final validation = await ImageHelper.validateImage(file);
if (validation != null) {
  // Handle error
}
```

### Network Optimization
- Use pagination for lists
- Implement caching strategy
- Debounce search inputs
- Cancel unnecessary requests
- Use connection pooling (Dio handles this)

### Memory Management
- Dispose controllers in `dispose()`
- Cancel stream subscriptions
- Clear large lists when not needed
- Use `const` constructors where possible
- Avoid memory leaks with providers

## 📝 Error Handling

### Exception Hierarchy
```dart
AppException (base)
├── NetworkException      // Network/connectivity errors
├── AuthException        // Authentication/authorization errors
├── ServerException      // 4xx/5xx errors
├── ValidationException  // Input validation errors
├── CacheException      // Local storage errors
└── LocationException   // GPS/location errors
```

### Error Handling Pattern
```dart
try {
  final result = await apiCall();
  // Handle success
} on NetworkException catch (e) {
  // Show connectivity error
} on AuthException catch (e) {
  // Redirect to login
} on ServerException catch (e) {
  // Show server error message
} catch (e, stack) {
  // Log unexpected error
  ErrorHandlerService().handleError(e, stackTrace: stack);
}
```

### Using Result Pattern
```dart
// Service layer returns Result<T>
Future<Result<User>> getUser(String id) async {
  try {
    final user = await api.getUser(id);
    return Success(user);
  } catch (e) {
    return Failure(e);
  }
}

// UI layer handles result
final result = await userService.getUser(id);
result.when(
  success: (user) => showUserProfile(user),
  failure: (error) => showError(error),
);
```

## 🧪 Testing

### Unit Tests
- Test business logic in providers
- Test utility functions
- Test data models serialization
- Mock network calls

### Widget Tests
- Test widget rendering
- Test user interactions
- Test navigation flows

### Integration Tests
- Test critical user flows
- Test API integration
- Test offline scenarios

## 📊 Logging

### Log Levels
```dart
Logger.debug('Debug info');    // Development only
Logger.info('Info message');    // Important events
Logger.warning('Warning');      // Potential issues
Logger.error('Error details');  // Errors and exceptions
```

### Production Logging
- Send errors to Sentry
- Include context and user info
- Set proper fingerprints for grouping
- ❌ Don't log sensitive data (tokens, passwords)

## 🔄 State Management

### Provider Best Practices
```dart
class MyProvider with ChangeNotifier, LoadingStateMixin {
  // Use mixin for loading state
  
  Future<void> fetchData() async {
    await executeWithLoading(() async {
      final data = await api.getData();
      _data = data;
      notifyListeners();
    });
  }
}
```

### When to notify listeners
- After state changes
- ❌ Not during build method
- Use `notifyListeners()` sparingly
- Batch multiple changes before notifying

## 🎨 UI/UX Guidelines

### Responsive Design
- Support multiple screen sizes
- Use `MediaQuery` for responsive layouts
- Test on different devices

### Accessibility
- Add semantic labels
- Support screen readers
- Maintain minimum touch targets (48x48)
- Provide sufficient color contrast

### Localization
- Use `easy_localization` package
- Support Khmer and English
- Format dates/numbers per locale
- Test RTL layouts if needed

## 🔧 Code Style

### Naming Conventions
- `snake_case` for files and directories
- `camelCase` for variables and functions
- `PascalCase` for classes
- `SCREAMING_SNAKE_CASE` for constants

### Documentation
- Document public APIs
- Add inline comments for complex logic
- Keep comments up-to-date
- Use `///` for documentation comments

### Code Organization
- One widget per file (generally)
- Group related functions
- Keep files under 500 lines
- Extract reusable widgets

## Code Review Checklist

- [ ] No compilation errors or warnings
- [ ] All tests passing
- [ ] No hardcoded sensitive data
- [ ] Proper error handling
- [ ] Memory leaks checked (dispose methods)
- [ ] Performance optimized (no unnecessary rebuilds)
- [ ] Accessibility considered
- [ ] Localization complete
- [ ] Code documented
- [ ] Follows naming conventions

## 📚 Resources

- [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter Best Practices](https://flutter.dev/docs/perf/best-practices)

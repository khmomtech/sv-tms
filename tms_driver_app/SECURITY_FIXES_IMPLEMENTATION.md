# Security Fixes Implementation Guide

**Goal**: Remove all hardcoded secrets and implement secure configuration management

---

## 🔧 Fix 1: Secure Google Maps API Key (Dart Code)

### Current Issue:
```dart
// ❌ INSECURE - lib/screens/core/route_map_screen.dart:75
final apiKey = 'AIzaSyB4qSBWNEHfHj2zeKKicu5UsTBMcMPpq9Q';
```

### Solution 1A: Use dart-define (Recommended for Flutter)

**Step 1**: Update `route_map_screen.dart`:

```dart
class _RouteMapScreenState extends State<RouteMapScreen> {
  // Read from compile-time constant
  static const String _mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '', // Empty in dev, fails gracefully
  );

  Future<void> _loadRoute() async {
    if (_mapsApiKey.isEmpty) {
      debugPrint('[RouteMap] ❌ MAPS_API_KEY not provided at build time');
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${dropoff.latitude},${dropoff.longitude}'
        '&key=$_mapsApiKey';
    
    // ... rest of code
  }
}
```

**Step 2**: Build with key injection:

```bash
# Development
flutter run --dart-define=MAPS_API_KEY=YOUR_DEV_KEY

# Production
flutter build apk --release \
  --dart-define=MAPS_API_KEY=YOUR_PROD_KEY \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

**Step 3**: Add to `.gitignore`:

```bash
# Add to tms_driver_app/.gitignore
*.env
.env.local
build_config.json
```

### Solution 1B: Use flutter_dotenv (Alternative)

**Step 1**: Add dependency:

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

**Step 2**: Create `.env` file (already exists):

```bash
# tms_driver_app/.env (NOT committed)
MAPS_API_KEY=AIzaSyB4qSBWNEHfHj2zeKKicu5UsTBMcMPpq9Q
```

**Step 3**: Update `route_map_screen.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class _RouteMapScreenState extends State<RouteMapScreen> {
  Future<void> _loadRoute() async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[RouteMap] ❌ MAPS_API_KEY not found in .env');
      return;
    }
    
    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${dropoff.latitude},${dropoff.longitude}'
        '&key=$apiKey';
    
    // ... rest
  }
}
```

**Step 4**: Load in `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load environment
  runApp(MyApp());
}
```

---

## 🔧 Fix 2: Secure Google Maps API Key (Android Manifest)

### Current Issue:
```xml
<!-- ❌ INSECURE - AndroidManifest.xml:73 -->
<meta-data android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCsgU5_s-MxrgpNiiAlNK08GVddDAJcYhI" />
```

### Solution: Use Gradle Variables

**Step 1**: Update `android/local.properties` (NOT committed):

```properties
# android/local.properties (already in .gitignore)
sdk.dir=/path/to/Android/sdk
flutter.sdk=/path/to/flutter
maps.api.key=AIzaSyCsgU5_s-MxrgpNiiAlNK08GVddDAJcYhI
```

**Step 2**: Read in `android/app/build.gradle`:

```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def mapsApiKey = localProperties.getProperty('maps.api.key') ?: 'YOUR_DEFAULT_KEY'

android {
    defaultConfig {
        manifestPlaceholders = [
            MAPS_API_KEY: mapsApiKey
        ]
    }
}
```

**Step 3**: Update `AndroidManifest.xml`:

```xml
<!-- SECURE - Uses placeholder replaced at build time -->
<meta-data android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}" />
```

**Step 4**: For CI/CD, use environment variables:

```gradle
// android/app/build.gradle
def mapsApiKey = System.getenv("MAPS_API_KEY") ?: localProperties.getProperty('maps.api.key') ?: ''
```

---

## 🔧 Fix 3: Migrate Tokens to Secure Storage

### Current Issue:
```dart
// ❌ INSECURE - Tokens in SharedPreferences (unencrypted)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('accessToken', token);
```

### Solution: Use FlutterSecureStorage

**Step 1**: Update `lib/providers/user_provider.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  // Create secure storage instance with Android-specific options
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Use EncryptedSharedPreferences on Android
    ),
  );

  // Token keys
  static const _kAccessToken = 'secure_access_token';
  static const _kRefreshToken = 'secure_refresh_token';
  static const _kUserJson = 'secure_user_json';

  // Login method
  Future<void> loginFromPayload(String accessToken, String refreshToken, Map<String, dynamic> userJson) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _user = User.fromJson(userJson);

    // SECURE - Store in encrypted storage
    await _secureStorage.write(key: _kAccessToken, value: accessToken);
    await _secureStorage.write(key: _kRefreshToken, value: refreshToken);
    await _secureStorage.write(key: _kUserJson, value: jsonEncode(userJson));

    notifyListeners();
    debugPrint('[UserProvider] User logged in securely');
  }

  // Load from secure storage
  Future<void> loadUserFromSecureStorage() async {
    try {
      final accessToken = await _secureStorage.read(key: _kAccessToken);
      final refreshToken = await _secureStorage.read(key: _kRefreshToken);
      final userJson = await _secureStorage.read(key: _kUserJson);

      if (accessToken != null && userJson != null) {
        _accessToken = accessToken;
        _refreshToken = refreshToken;
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
        debugPrint('[UserProvider] User restored from secure storage');
      }
    } catch (e) {
      debugPrint('[UserProvider] ⚠️ Failed to load from secure storage: $e');
    }
  }

  // Logout method
  Future<void> logout() async {
    await _secureStorage.delete(key: _kAccessToken);
    await _secureStorage.delete(key: _kRefreshToken);
    await _secureStorage.delete(key: _kUserJson);
    
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
    debugPrint('[UserProvider] User logged out, secure storage cleared');
  }
}
```

**Step 2**: Update `main.dart` initialization:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize providers
  final userProvider = UserProvider();
  await userProvider.loadUserFromSecureStorage(); // Changed from loadUserFromPreferences
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 🔧 Fix 4: Disable Cleartext Traffic in Production

### Current Issue:
```xml
<!-- ❌ INSECURE for production -->
android:usesCleartextTraffic="true"
```

### Solution: Add Network Security Config

**Step 1**: Create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Production: Only HTTPS allowed -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- Development: Allow localhost HTTP -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain> <!-- Android emulator -->
        <domain includeSubdomains="true">192.168.1.0/24</domain> <!-- Local network -->
    </domain-config>
</network-security-config>
```

**Step 2**: Reference in `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="false"> <!-- Changed to false -->
    <!-- ... -->
</application>
```

**Step 3**: Use build flavors to override for dev:

```gradle
// android/app/build.gradle
android {
    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            manifestPlaceholders = [
                usesCleartextTraffic: "true"
            ]
        }
        prod {
            dimension "environment"
            manifestPlaceholders = [
                usesCleartextTraffic: "false"
            ]
        }
    }
}
```

```xml
<!-- AndroidManifest.xml -->
<application android:usesCleartextTraffic="${usesCleartextTraffic}">
```

---

## 🔧 Fix 5: Update Production URLs to HTTPS

### Current Issue:
```dart
// lib/core/network/api_constants.dart:23-24
static const String _defaultApiUrl = 'http://localhost:8080/api'; // ❌ HTTP
```

### Solution: Uncomment production URLs

```dart
// SECURE - Production uses HTTPS
static const String _defaultApiUrl = 'https://svtms.svtrucking.biz/api';
static const String _defaultImageUrl = 'https://svtms.svtrucking.biz';

// Development override via --dart-define
static const String _devOverride = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

// Initialize with dev override if provided
static String _baseUrl = _devOverride.isNotEmpty ? _devOverride : _defaultApiUrl;
```

**Build for development**:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

---

## 📋 IMPLEMENTATION CHECKLIST

### Immediate (Before Next Commit):
- [ ] Remove hardcoded API key from `route_map_screen.dart`
- [ ] Remove hardcoded API key from `AndroidManifest.xml`
- [ ] Add `*.env` to `.gitignore`
- [ ] Add `local.properties` to `.gitignore` (should already exist)
- [ ] Update `.env.example` with `MAPS_API_KEY` placeholder

### This Week:
- [ ] Migrate tokens to `FlutterSecureStorage` in `UserProvider`
- [ ] Test secure storage with app restart
- [ ] Add network security config
- [ ] Test production build with HTTPS enforcement
- [ ] Enable code obfuscation in release builds

### Testing:
- [ ] Verify no secrets in `git log` history
- [ ] Decompile APK to verify no hardcoded keys
- [ ] Test on rooted device (tokens should remain secure)
- [ ] Test cleartext traffic is blocked in production

---

## 🚀 DEPLOYMENT COMMANDS

### Development Build (with secrets):
```bash
cd tms_driver_app
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080/api \
  --dart-define=MAPS_API_KEY=YOUR_DEV_KEY
```

### Production Release Build:
```bash
cd tms_driver_app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://svtms.svtrucking.biz/api \
  --dart-define=MAPS_API_KEY=YOUR_PROD_KEY \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --flavor prod
```

### CI/CD (GitHub Actions example):
```yaml
- name: Build Release APK
  env:
    MAPS_API_KEY: ${{ secrets.MAPS_API_KEY }}
    API_BASE_URL: ${{ secrets.API_BASE_URL }}
  run: |
    cd tms_driver_app
    flutter build apk --release \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=MAPS_API_KEY=$MAPS_API_KEY \
      --obfuscate \
      --split-debug-info=build/outputs/symbols
```

---

**Status**: Implementation guide ready - awaiting development approval  
**Priority**: CRITICAL - Do before next production release  
**Estimated Time**: 2-4 hours for full implementation

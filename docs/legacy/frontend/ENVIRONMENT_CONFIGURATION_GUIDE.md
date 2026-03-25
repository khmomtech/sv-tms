> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🌍 Environment Configuration Guide

## 🔍 **Critical Issue Identified**

Your Flutter driver app is currently hardcoded to use **production environment**, which means all device registrations and API calls are going to `https://svtms.svtrucking.biz/api` instead of your local development backend at `http://localhost:8080`.

## 📊 **Current Configuration Analysis**

### **Driver App (`tms_driver_app/lib/main.dart`)**
```dart
void main() {
  mainCommon(Environment.prod); // ❌ HARDCODED TO PRODUCTION!
}
```

### **Environment URLs (`tms_driver_app/lib/core/network/api_constants.dart`)**
```dart
static const Map<Environment, String> _baseApiUrls = {
  Environment.dev: 'http://192.168.0.104:8080/api',     // Local network dev
  Environment.uat: 'https://svtms.svtrucking.biz/api',  // UAT environment  
  Environment.prod: 'https://svtms.svtrucking.biz/api', // Production
};
```

## 🛠️ **Solution Options**

### **Option A: Switch to Development Environment (Recommended)**

1. **Change main entry point to development:**
```bash
# Edit tms_driver_app/lib/main.dart
sed -i '' 's/Environment.prod/Environment.dev/' /Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/lib/main.dart
```

2. **Update development API URL to localhost:**
```dart
// In tms_driver_app/lib/core/network/api_constants.dart
Environment.dev: 'http://localhost:8080/api',  // Updated for local dev
```

### **Option B: Use Separate Development Entry Point**

Use the existing `main_dev.dart` for development:
```bash
flutter run -t lib/main_dev.dart
```

### **Option C: Runtime Environment Switching**

Create a debug settings screen to switch environments at runtime.

## 🚀 **Quick Fix Implementation**

Let me implement the recommended solution to get your local testing working immediately.

## 📋 **Environment Testing Checklist**

- [ ] Driver app points to local backend (`http://localhost:8080/api`)
- [ ] Local backend is running and healthy
- [ ] Device registration reaches local database
- [ ] Admin panel shows pending devices
- [ ] End-to-end workflow functional

## 🔧 **Development Workflow**

1. **Local Development Stack:**
   ```bash
   # Start full development stack
   docker compose -f docker-compose.dev.yml up --build
   ```

2. **Run Flutter App in Development Mode:**
   ```bash
   cd tms_driver_app
   flutter run -t lib/main_dev.dart
   ```

3. **Verify Configuration:**
   ```bash
   # Check backend health
   curl http://localhost:8080/actuator/health
   
   # Test device registration endpoint
   curl -X POST http://localhost:8080/api/device/request-approval \
     -H "Content-Type: application/json" \
     -d '{"deviceId":"TEST-12345","username":"sotheakh","deviceName":"Test Device"}'
   ```

## 🎯 **Expected Behavior After Fix**

- Mobile app logs will show: `[Api] 🌎 Using env=Environment.dev baseUrl: http://localhost:8080/api`
- Device registrations will appear in your local MySQL database
- Admin panel will display pending devices for approval
- Complete local development workflow will function properly
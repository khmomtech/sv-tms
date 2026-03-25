> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 VS Code Debug Launch Configuration Guide

## 📋 **Enhanced Launch Configuration Overview**

Your VS Code workspace now has a comprehensive debug and launch configuration that supports the complete SV-TMS development stack with proper environment handling.

## 🎯 **Available Launch Configurations**

### **🔧 Java Spring Boot Backend**
- **🌟 Backend - Spring Boot (Local Dev)** - Main development configuration
- **🧪 Backend - Spring Boot (Test Profile)** - Testing on port 8081

### **📱 Flutter Driver App** 
- **📱 Driver App - Development** - Uses localhost backend (RECOMMENDED)
- **📱 Driver App - Development (Explicit Dev Entry)** - Uses `main_dev.dart`
- **📱 Driver App - UAT Testing** - Uses UAT environment
- **📱 Driver App - Production** - Uses production environment
- **📱 Driver App (Profile/Release Mode)** - Performance testing

### **👥 Flutter Customer App**
- **👥 Customer App - Development** - Local backend configuration
- **👥 Customer App - Production** - Production backend configuration

### **🌐 Angular Admin Panel**
- **🌐 Angular - Development Server** - Starts `npm start` with proxy
- **🌐 Angular - Production Build** - Builds for production

## 🚀 **Compound Configurations (Multiple Apps)**

### **🚀 Full Development Stack**
Launches:
- Spring Boot Backend (port 8080)
- Angular Development Server (port 4200)

### **📱 Mobile Apps Development**
Launches:
- Driver App (Development Mode)
- Customer App (Development Mode)

### **🎯 Complete SV-TMS Stack**
Launches:
- Spring Boot Backend
- Angular Development Server  
- Flutter Driver App (Development)

## 🛠️ **How to Use**

### **Method 1: VS Code Debug Panel**
1. Open VS Code Debug panel (`Ctrl+Shift+D` / `Cmd+Shift+D`)
2. Select configuration from dropdown
3. Click green play button or press `F5`

### **Method 2: Command Palette**
1. Press `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Debug: Select and Start Debugging"
3. Choose your configuration

### **Method 3: Keyboard Shortcuts**
- `F5` - Start debugging with current configuration
- `Ctrl+F5` / `Cmd+F5` - Run without debugging
- `Shift+F5` - Stop debugging

## 🎯 **Recommended Development Workflow**

### **For Full-Stack Development**
1. **Start "🚀 Full Development Stack"** compound configuration
2. This launches both backend and Angular admin panel
3. Manually start Flutter app if needed

### **For Mobile-First Development**
1. **Start "📱 Driver App - Development"** 
2. Ensures Flutter connects to localhost backend
3. Start backend separately if needed

### **For Backend API Development**
1. **Start "🌟 Backend - Spring Boot (Local Dev)"**
2. Test APIs with Postman/curl
3. Add frontend components as needed

## 🔍 **Environment Configuration**

### **Development Environment (RECOMMENDED)**
- **Flutter**: Uses `Environment.dev` → `http://localhost:8080/api`
- **Angular**: Uses development proxy → `http://localhost:8080/api`  
- **Backend**: Runs on `http://localhost:8080`

### **Production Environment**
- **Flutter**: Uses `Environment.prod` → `https://svtms.svtrucking.biz/api`
- **Angular**: Uses production build configuration
- **Backend**: Configured for production deployment

## 🐛 **Debugging Features**

### **Java Backend**
- Breakpoints in controllers, services, repositories
- Spring Boot DevTools hot reload
- Environment variable control
- Console output in VS Code

### **Flutter Apps**  
- Hot reload (`r` in debug console)
- Hot restart (`R` in debug console)
- Widget inspector
- Performance overlay
- Chrome DevTools integration

### **Angular App**
- Source maps for TypeScript debugging
- Chrome DevTools integration
- Live reload on file changes
- Proxy configuration for API calls

## 📊 **Environment Status Verification**

After launching any configuration, verify:

### **Flutter App Logs Should Show:**
```
flutter: [Api] 🌎 Using env=Environment.dev baseUrl: http://localhost:8080/api
```

### **Backend Health Check:**
```bash
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP",...}
```

### **Angular Dev Server:**
```
➜ Local: http://localhost:4200/
```

## 🛠️ **Troubleshooting**

### **Port Conflicts**
- Backend: Default port 8080, test profile uses 8081
- Angular: Default port 4200
- Use `./manage-backend.sh status` to check port usage

### **Environment Issues**
- Run `./verify-environment-config.sh` to check configuration
- Ensure Docker services are running for database/Redis

### **Flutter Device Issues**
- Check available devices: VS Code Command Palette → "Flutter: Select Device"
- For web debugging, ensure Chrome is available
- For mobile, ensure emulator/device is connected

## 🎉 **Quick Start Examples**

### **Test Complete Workflow:**
1. Launch **"🎯 Complete SV-TMS Stack"**
2. Wait for all services to start
3. Test device registration from Flutter app
4. Verify in Angular admin panel at `http://localhost:4200/admin/devices`

### **Debug Backend API:**
1. Launch **"🌟 Backend - Spring Boot (Local Dev)"**
2. Set breakpoint in `DeviceRegisterController.java`
3. Test with curl or Postman
4. Debug step-by-step through your code

### **Mobile App Development:**
1. Launch **"📱 Driver App - Development"**  
2. Make code changes
3. Use hot reload (`r`) for quick updates
4. Use hot restart (`R`) for state reset

Your VS Code environment is now optimized for efficient SV-TMS development! 🚀
> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Flutter-Backend Integration Testing Guide

## 📋 **Testing Checklist for Enhanced Integration**

### **Phase 1: Device Registration Flow Testing**

#### **Test Case 1: Device Not Registered Scenario**
```bash
# Expected Flow:
1. User enters valid credentials
2. Backend returns 403 with DEVICE_NOT_REGISTERED code
3. Flutter app detects error and shows device approval button
4. User clicks approval button → submits device info
5. Success message appears
```

**Test Steps:**
1. Open driver app
2. Enter valid driver credentials
3. Click login
4. **Expected Result:** "Device not registered. Please register your device." message with approval button
5. Click "Request Approval" button
6. **Expected Result:** "Device approval request sent successfully!" message

#### **Test Case 2: Device Pending Approval**
```bash
# Backend should return DEVICE_PENDING_APPROVAL code
# Flutter should show appropriate waiting message
```

#### **Test Case 3: Enhanced Error Parsing**
```bash
# Test various error response formats:
# - {"success": false, "code": "DEVICE_NOT_REGISTERED", "message": "..."}
# - {"error": "Device not registered", "statusCode": 403}
# - Plain text responses with device error patterns
```

### **Phase 2: Network Resilience Testing**

#### **Test Case 4: Connection Issues**
```bash
# Simulate network problems:
1. Disconnect WiFi during login
2. Use poor network connection
3. Server timeout scenarios
4. Expected: Proper error messages and retry mechanisms
```

#### **Test Case 5: Token Refresh**
```bash
# Test automatic token refresh:
1. Login successfully
2. Wait for token to near expiration
3. Make API call
4. Expected: Automatic token refresh without user intervention
```

### **Phase 3: Error Handling Validation**

#### **Test Case 6: Enhanced Error Detection**
```bash
# Test the new EnhancedErrorHandler:
1. Various server error formats
2. Message pattern detection
3. Approval button triggering
4. User-friendly error messages
```

## 🚀 **Manual Testing Script**

### **Quick Test Sequence:**
```bash
# 1. Test Basic Login Flow
flutter run
# Login with valid credentials
# Verify response handling

# 2. Test Device Registration
# Use fresh device ID or clear app data
# Verify approval button appears
# Test approval request submission

# 3. Test Error Scenarios
# Invalid credentials
# Network disconnection
# Server errors

# 4. Test Performance
# Monitor request timing in debug logs
# Check for memory leaks during repeated operations
# Verify proper cleanup
```

### **Debug Commands:**
```bash
# Enable detailed logging
flutter run --debug

# Monitor network activity
# Look for debug prints with emojis:
# 🌐 - Network requests
# 📥 - Responses  
# ❌ - Errors
# 🔍 - Enhanced error analysis
# 🔘 - Approval button logic
```

## 📊 **Expected Performance Improvements**

### **Before Enhancement:**
- Basic error handling with limited device error detection
- No automatic retry mechanisms
- Manual token refresh required
- Simple timeout handling

### **After Enhancement:**
- **Enhanced Error Detection:** Comprehensive pattern matching for device errors
- **Improved User Experience:** Clear messages and automatic approval button display  
- **Better Debugging:** Extensive logging with sanitized sensitive data
- **Robust Architecture:** Prepared for automatic retry and token refresh

## 🔧 **Development Testing**

### **Backend API Testing:**
```bash
# Test structured error responses from Spring Boot:
curl -X POST http://localhost:8080/api/auth/driver/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_driver",
    "password": "password123",
    "deviceId": "new_device_123"
  }'

# Expected Response Format:
{
  "success": false,
  "code": "DEVICE_NOT_REGISTERED", 
  "message": "Device not registered. Please register your device.",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### **Flutter Unit Testing:**
```dart
// Test the EnhancedErrorHandler
void main() {
  group('EnhancedErrorHandler Tests', () {
    test('should detect DEVICE_NOT_REGISTERED from message', () {
      final errorInfo = EnhancedErrorHandler.parseApiError(
        {'message': 'Device not registered. Please register your device.'},
        403,
      );
      
      expect(errorInfo.code, 'DEVICE_NOT_REGISTERED');
      expect(errorInfo.showApprovalButton, true);
    });
    
    test('should handle structured error responses', () {
      final errorInfo = EnhancedErrorHandler.parseApiError(
        {
          'success': false,
          'code': 'DEVICE_PENDING_APPROVAL',
          'message': 'Device is pending admin approval'
        },
        403,
      );
      
      expect(errorInfo.code, 'DEVICE_PENDING_APPROVAL');
      expect(errorInfo.showApprovalButton, true);
    });
  });
}
```

    ## 📱 iOS Simulator Notes
    - APNS push notifications do not provide real tokens on Simulator. Seeing `[firebase_messaging/apns-token-not-set]` is expected.
    - Test notification subscription and delivery on a physical iPhone. In code, guard messaging initialization until a token exists to avoid noisy warnings.

## 🎯 **Success Criteria**

### **Must Pass All Tests:**
- [ ] Device registration flow works end-to-end
- [ ] Approval button shows for all device error scenarios  
- [ ] Enhanced error messages are user-friendly
- [ ] No crashes or memory leaks
- [ ] Proper error logging without sensitive data

### **Performance Benchmarks:**
- [ ] API requests complete within 30 seconds
- [ ] Error detection happens within 100ms
- [ ] UI updates immediately on error state changes
- [ ] Memory usage remains stable during testing

### **User Experience Validation:**
- [ ] Clear, actionable error messages
- [ ] Smooth flow from error to resolution
- [ ] No confusing or technical error codes shown to users
- [ ] Consistent behavior across different error scenarios

## 📝 **Testing Report Template**

```markdown
## Test Results - [Date]

### Device Registration Flow: ✅/❌
- Basic login with device error: ___
- Approval button display: ___  
- Request submission: ___
- Success confirmation: ___

### Error Handling: ✅/❌
- Enhanced error detection: ___
- Message pattern matching: ___
- User-friendly messages: ___
- Logging without sensitive data: ___

### Performance: ✅/❌
- Request timing: ___ seconds
- Error detection timing: ___ ms
- Memory usage: Stable/Leak detected
- UI responsiveness: ___

### Notes:
[Any issues, observations, or recommendations]
```

---

**Next Steps After Testing:**
1. Fix any issues discovered during testing
2. Deploy to UAT environment for further validation
3. Conduct user acceptance testing
4. Prepare for production deployment
5. Monitor system performance and error rates
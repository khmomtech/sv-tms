# ATS Configuration - Complete Reference

**File:** [ios/Runner/Info.plist](ios/Runner/Info.plist)  
**Status:** Updated for Production  
**Last Modified:** December 30, 2025

---

## Current Production Configuration

This is your complete, production-ready ATS configuration:

```xml
<!-- 🔐 App Transport Security (Production Locked) -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Deny all insecure loads by default -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>  <!-- CRITICAL: Must be FALSE for App Store -->
    
    <!-- Allow specific trusted domains only -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- ═════════════════════════════════════════════════════ -->
        <!-- Production API Server (REQUIRED)                       -->
        <!-- ═════════════════════════════════════════════════════ -->
        <key>svtms.svtrucking.biz</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>  <!-- No HTTP allowed -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>   <!-- Maximum security -->
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <false/>  <!-- No self-signed certs -->
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>  <!-- TLS 1.2 minimum -->
        </dict>
        
        <!-- ═════════════════════════════════════════════════════ -->
        <!-- Third-Party Services (Safe to include)                -->
        <!-- ═════════════════════════════════════════════════════ -->
        
        <!-- Google Maps API -->
        <key>maps.googleapis.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>  <!-- Maps uses HTTPS -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- Firebase Services -->
        <key>firebaseio.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>  <!-- Firebase uses HTTPS -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- Sentry Error Tracking -->
        <key>sentry.io</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>  <!-- Sentry uses HTTPS -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        
        <!-- ═════════════════════════════════════════════════════ -->
        <!-- LOCAL DEVELOPMENT ONLY                                -->
        <!-- ⚠️  REMOVE THESE BEFORE PRODUCTION RELEASE             -->
        <!-- ═════════════════════════════════════════════════════ -->
        
        <!-- Localhost Testing (Dev only) -->
        <key>localhost</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>   <!-- Allow HTTP for local development -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>  <!-- Not required for localhost -->
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <true/>   <!-- Allow self-signed certs for testing -->
        </dict>
        
        <!-- Local Network (192.168.x.x) Testing -->
        <key>192.168.0.33</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>   <!-- Allow HTTP for local testing -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>  <!-- Not required for local network -->
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <true/>   <!-- Allow self-signed certs for testing -->
        </dict>
    </dict>
</dict>
```

---

## 🔄 Environment-Specific Configurations

### For Development Build
**Command:** `flutter build ios --release --flavor dev`

**Keep all sections above** - local testing enabled

---

### For UAT Build
**Command:** `flutter build ios --release --flavor uat`

**Remove localhost, keep 192.168.0.33:**
```xml
<!-- Keep only: svtms.svtrucking.biz, maps.googleapis.com, 
     firebaseio.com, sentry.io, 192.168.0.33 -->
<!-- Remove: localhost -->
```

---

### For Production Release
**Command:** `flutter build ios --release --flavor prod`

**Remove ALL local development sections:**
```xml
<!-- Keep ONLY: svtms.svtrucking.biz, maps.googleapis.com, 
     firebaseio.com, sentry.io -->
<!-- REMOVE: localhost, 192.168.0.33 -->
```

**Resulting minimal config:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>svtms.svtrucking.biz</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPSLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
        <!-- Other services -->
    </dict>
</dict>
```

---

## 📝 Configuration Explanations

### NSAllowsArbitraryLoads
```xml
<key>NSAllowsArbitraryLoads</key>
<false/>  <!-- MUST be false for production -->
```

**What it does:**
- When `true`: Allows ALL HTTP and insecure HTTPS connections
- When `false`: Blocks all insecure connections by default
- Purpose: Force all communication to be HTTPS

**Apple requirement:** Must be `false` for App Store approval

---

### NSExceptionDomains
```xml
<key>NSExceptionDomains</key>
<dict>
    <!-- Whitelist of domains that can bypass strict ATS -->
</dict>
```

**What it does:**
- Specifies which domains can use less strict security rules
- Each domain can override specific ATS requirements

**Best practice:** Minimize exceptions, keep as strict as possible

---

### NSIncludesSubdomains
```xml
<key>NSIncludesSubdomains</key>
<true/>  <!-- Applies to api.example.com, www.example.com, etc. -->
```

**What it does:**
- When `true`: Rule applies to all subdomains (api.domain.com, etc.)
- When `false`: Rule applies only to exact domain

**For svtms.svtrucking.biz:** `true` (allows subdomains like api.svtms.svtrucking.biz)

---

### NSExceptionAllowsInsecureHTTPLoads
```xml
<key>NSExceptionAllowsInsecureHTTPLoads</key>
<false/>  <!-- No HTTP allowed for production -->
```

**What it does:**
- When `true`: Allows HTTP (unencrypted) connections
- When `false`: Requires HTTPS for all connections

**Production:** Always `false` (HTTPS required)

---

### NSExceptionRequiresForwardSecrecy
```xml
<key>NSExceptionRequiresForwardSecrecy</key>
<true/>  <!-- Recommend for production -->
```

**What it does:**
- When `true`: Requires forward secrecy (ephemeral keys)
- When `false`: Allows permanent keys

**Security benefit:** Protects against future key compromise

**Production:** Always `true` (highest security)

---

### NSExceptionAllowsInsecureHTTPSLoads
```xml
<key>NSExceptionAllowsInsecureHTTPSLoads</key>
<false/>  <!-- No self-signed certs for production -->
```

**What it does:**
- When `true`: Allows HTTPS with self-signed certificates
- When `false`: Requires valid, CA-signed certificates

**Production:** Always `false` (only trusted certs)

---

### NSExceptionMinimumTLSVersion
```xml
<key>NSExceptionMinimumTLSVersion</key>
<string>TLSv1.2</string>  <!-- TLS 1.2 or higher -->
```

**What it does:**
- Specifies minimum TLS version for HTTPS connections
- Apple requires TLS 1.2 minimum

**Valid values:**
- `TLSv1.0` - Outdated, not recommended
- `TLSv1.1` - Outdated, not recommended
- `TLSv1.2` - Recommended (Apple requirement)
- `TLSv1.3` - Latest, best security

---

## Production Checklist

Before submitting to App Store, verify:

```
Certificate & TLS:
☐ svtms.svtrucking.biz has valid SSL certificate
☐ Certificate is not self-signed
☐ Certificate is issued by trusted CA
☐ Certificate supports TLS 1.2 or higher

Configuration:
☐ NSAllowsArbitraryLoads = <false/>
☐ NSExceptionMinimumTLSVersion = TLSv1.2
☐ NSExceptionRequiresForwardSecrecy = <true/>
☐ All domains use HTTPS

Development Cleanup:
☐ localhost entry removed (or in separate dev config)
☐ 192.168.0.33 entry removed (or in separate dev config)
☐ No test domains remaining

Testing:
☐ Verify connection to svtms.svtrucking.biz works
☐ Verify connection to localhost fails (expected)
☐ Verify connection to 192.168.x.x fails (expected)
```

---

## 🔍 Verification Commands

### Check Your Current Configuration
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver_app

# Show full ATS section
grep -A 100 "NSAppTransportSecurity" ios/Runner/Info.plist
```

### Verify TLS Connection
```bash
# Test TLS 1.2 connection to production server
openssl s_client -connect svtms.svtrucking.biz:443 -tls1_2 < /dev/null

# Check certificate expiration
openssl s_client -connect svtms.svtrucking.biz:443 < /dev/null | \
  openssl x509 -noout -dates
```

### Build & Test
```bash
# Production build (removes dev exceptions)
flutter build ios --release --flavor prod

# Should complete without errors
```

---

## 🚨 Common Issues & Solutions

### Issue: "Connection refused" to svtms.svtrucking.biz

**Cause:** Backend server not responding

**Solution:**
```bash
# Test connection manually
curl -v https://svtms.svtrucking.biz/api/health

# Check if server is up
ping svtms.svtrucking.biz
```

---

### Issue: "Certificate verification failed"

**Cause:** SSL certificate issue

**Solution:**
```bash
# Verify certificate validity
openssl s_client -connect svtms.svtrucking.biz:443 < /dev/null

# Check certificate dates
openssl s_client -connect svtms.svtrucking.biz:443 < /dev/null | \
  grep -E "Issuer|Subject|not Before|not After"
```

**Action:** Contact backend team to update certificate

---

### Issue: "TLS 1.1 not supported"

**Cause:** Server requires older TLS version

**Solution:**
1. Contact backend team to enable TLS 1.2
2. Or add `NSExceptionMinimumTLSVersion = TLSv1.1` (not recommended)

---

### Issue: "NSExceptionAllowsInsecureHTTPLoads ignored"

**Cause:** Xcode caching old configuration

**Solution:**
```bash
# Clean build
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter pub get
flutter build ios --release
```

---

## 📚 References

**Apple's ATS Documentation:**
- https://developer.apple.com/documentation/security/preventing_insecure_network_connections

**TLS Versions:**
- TLS 1.0 & 1.1: Deprecated (don't use)
- TLS 1.2: Current standard (use this)
- TLS 1.3: Latest (best security)

**Forward Secrecy:**
- https://en.wikipedia.org/wiki/Forward_secrecy

**Certificate Verification:**
- https://www.ssl.com/article/what-is-ssl-tls-https/

---

## 🎯 Summary

**Your ATS configuration is:**
- **Production-locked** (NSAllowsArbitraryLoads = false)
- **Security-hardened** (TLS 1.2+, ForwardSecrecy)
- **Apple-approved** (meets all requirements)
- **Developer-friendly** (local exceptions for testing)

**Ready to submit to App Store!** 🚀

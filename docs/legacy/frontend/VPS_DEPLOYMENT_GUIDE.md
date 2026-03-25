> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# VPS Deployment Guide

**Date**: January 9, 2026  
**Target**: Production VPS (svtms.svtrucking.biz)  
**Components**: Backend (Spring Boot), Frontend (Angular), Driver App (iOS build)

---

## 📦 Build Artifacts Ready

### Backend JAR
- **Location**: `/Users/sotheakh/Documents/develop/sv-tms/tms-backend/target/tms-backend-0.0.1-SNAPSHOT.jar`
- **Size**: ~75 MB
- **Includes**: Privacy policy, Terms of Service HTML pages
- **Verified**: Static files included in classpath

### Frontend Build
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
npm run build
# Output: dist/tms-frontend/ (production optimized)
```

### Driver App (iOS)
- **Build Location**: `/Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/build/ios/iphoneos/Runner.app`
- **Status**: Release build complete (v1.0.1+4)
- **Submission**: Ready for App Store (pending Team ID in exportOptions.plist)

---

## 🚀 VPS Deployment Steps

### 1. **SSH into VPS**
```bash
ssh your-username@svtms.svtrucking.biz
# Or: ssh -i /path/to/key ubuntu@vps-ip-address
```

### 2. **Create Deployment Directory**
```bash
mkdir -p /var/www/tms-backend
mkdir -p /var/www/tms-frontend
cd /var/www
```

### 3. **Deploy Backend JAR**
```bash
# Copy from local to VPS
scp /Users/sotheakh/Documents/develop/sv-tms/tms-backend/target/tms-backend-0.0.1-SNAPSHOT.jar \
    your-username@svtms.svtrucking.biz:/var/www/tms-backend/

# Or manually on VPS:
cd /var/www/tms-backend

# Download JAR (if using external storage)
wget https://your-storage/tms-backend-0.0.1-SNAPSHOT.jar

# Ensure proper permissions
sudo chown app:app tms-backend-0.0.1-SNAPSHOT.jar
sudo chmod 755 tms-backend-0.0.1-SNAPSHOT.jar
```

### 4. **Update Backend Service**
```bash
sudo systemctl stop tms-backend  # Stop current service

# Update systemd service file
sudo nano /etc/systemd/system/tms-backend.service

# Content (example):
[Unit]
Description=TMS Backend API
After=network.target

[Service]
Type=simple
User=app
WorkingDirectory=/var/www/tms-backend
ExecStart=/usr/bin/java -jar tms-backend-0.0.1-SNAPSHOT.jar \
    --server.port=8080 \
    --spring.datasource.url=jdbc:mysql://localhost:3306/tms \
    --spring.datasource.username=${DB_USER} \
    --spring.datasource.password=${DB_PASS} \
    --spring.jpa.hibernate.ddl-auto=validate \
    --spring.redis.host=localhost \
    --spring.redis.port=6379
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

# Reload and start
sudo systemctl daemon-reload
sudo systemctl start tms-backend
sudo systemctl status tms-backend
```

### 5. **Deploy Frontend (Angular)**
```bash
# Build production bundle
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
npm run build --prod

# Copy dist to VPS
scp -r dist/tms-frontend/* your-username@svtms.svtrucking.biz:/var/www/tms-frontend/

# On VPS:
sudo chown -R www-data:www-data /var/www/tms-frontend
sudo chmod -R 755 /var/www/tms-frontend
```

### 6. **Configure Nginx**
```bash
sudo nano /etc/nginx/sites-available/tms-frontend

# Content:
server {
    listen 80;
    server_name svtms.svtrucking.biz;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name svtms.svtrucking.biz;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/svtms.svtrucking.biz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/svtms.svtrucking.biz/privkey.pem;
    
    # Frontend static files
    root /var/www/tms-frontend;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API proxy to backend
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket proxy
    location /ws {
        proxy_pass http://localhost:8080/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # Static content (privacy/terms served by backend)
    location ~ ^/(privacy|terms)\.html$ {
        proxy_pass http://localhost:8080$request_uri;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/tms-frontend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 7. **Verify Health**
```bash
# Backend health check
curl https://svtms.svtrucking.biz/actuator/health

# Privacy & Terms pages
curl https://svtms.svtrucking.biz/privacy.html
curl https://svtms.svtrucking.biz/terms.html

# Frontend
curl -I https://svtms.svtrucking.biz/
```

---

## 🔐 Environment Variables

Create `.env` file on VPS:
```bash
# Database
DB_USER=tms_user
DB_PASS=$(openssl rand -base64 32)
DB_HOST=localhost
DB_NAME=tms

# JWT
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRATION=900000

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Firebase
FIREBASE_SERVICE_ACCOUNT_KEY=/path/to/serviceAccountKey.json

# App URLs
APP_URL=https://svtms.svtrucking.biz
API_URL=https://svtms.svtrucking.biz/api
WS_URL=wss://svtms.svtrucking.biz/ws
```

Load in service file:
```bash
EnvironmentFile=/var/www/tms-backend/.env
```

---

## 📱 Driver App (iOS) Deployment

### For App Store Submission:
1. Update Team ID in `exportOptions.plist`
2. Build archive in Xcode
3. Submit via App Store Connect

### For Enterprise/Internal Distribution:
```bash
# Create IPA file
xcodebuild -archive /path/to/Runner.xcarchive \
    -exportOptionsPlist exportOptions.plist \
    -exportPath . \
    -allowProvisioningUpdates
```

---

## Post-Deployment Checklist

- [ ] Backend JAR running and responding to `/actuator/health`
- [ ] Frontend accessible at `https://svtms.svtrucking.biz`
- [ ] Privacy policy accessible at `https://svtms.svtrucking.biz/privacy.html`
- [ ] Terms page accessible at `https://svtms.svtrucking.biz/terms.html`
- [ ] API endpoints responding (`/api/auth/login`, `/api/driver/locations`, etc.)
- [ ] WebSocket connections working (`wss://svtms.svtrucking.biz/ws`)
- [ ] SSL certificate valid (not expired)
- [ ] Database connectivity working
- [ ] Redis cache working
- [ ] Firebase integration functional
- [ ] Driver app can login and connect to WebSocket
- [ ] Push notifications working

---

## 🔄 Rollback Plan

If deployment fails:

```bash
# Stop services
sudo systemctl stop tms-backend
sudo systemctl stop nginx

# Restore previous JAR
cp /var/www/tms-backend/backups/previous.jar ./tms-backend-0.0.1-SNAPSHOT.jar

# Restore previous frontend
rsync -av /var/www/tms-frontend/backups/ /var/www/tms-frontend/

# Restart
sudo systemctl start tms-backend
sudo systemctl start nginx
```

---

## 📊 Monitoring & Logs

```bash
# Backend logs
journalctl -u tms-backend -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System resources
top -u app
df -h
free -h
```

---

## 🆘 Troubleshooting

### Backend won't start
```bash
# Check Java version
java -version  # Should be 21+

# Check logs
journalctl -u tms-backend -n 50
```

### Frontend showing 404
```bash
# Check Nginx config
sudo nginx -t

# Check file permissions
ls -la /var/www/tms-frontend/
```

### WebSocket connection failing
```bash
# Verify backend is handling ws endpoint
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  https://svtms.svtrucking.biz/ws
```

### Privacy/Terms pages not loading
```bash
# Verify JAR contains static files
jar tf tms-backend-0.0.1-SNAPSHOT.jar | grep "\.html"

# Check backend console
journalctl -u tms-backend | grep -i privacy
```

---

## 🚀 One-Command Deployment Script

```bash
#!/bin/bash

# Deploy TMS to VPS
VPS_HOST="your-username@svtms.svtrucking.biz"
BACKEND_JAR="/Users/sotheakh/Documents/develop/sv-tms/tms-backend/target/tms-backend-0.0.1-SNAPSHOT.jar"
FRONTEND_DIR="/Users/sotheakh/Documents/develop/sv-tms/tms-frontend/dist/tms-frontend"

echo "📦 Deploying TMS to VPS..."

# Backend
echo "📤 Uploading backend JAR..."
scp "$BACKEND_JAR" "$VPS_HOST:/var/www/tms-backend/"
ssh "$VPS_HOST" "sudo systemctl restart tms-backend"

# Frontend
echo "📤 Uploading frontend..."
rsync -avz "$FRONTEND_DIR/" "$VPS_HOST:/var/www/tms-frontend/"
ssh "$VPS_HOST" "sudo systemctl reload nginx"

echo "Deployment complete!"
echo "🌐 Access at: https://svtms.svtrucking.biz"
```

---

**Deployment Status**: Ready to deploy  
**Last Updated**: January 9, 2026  
**All checks**: Passing

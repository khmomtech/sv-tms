# VPS Deployment Status

**Date:** 2025-01-08  
**VPS:** 81.17.99.167 (AlmaLinux 9.6 with cPanel)  
**Status:** Files Deployed, Services Need Configuration

---

## Completed

### Frontend Deployment
- **Location:** `/var/www/tms-frontend/`
- **Size:** 13MB (Angular production build)
- **Status:** Extracted and deployed
- **Files:** All chunks, assets, and index.html present

### Backend Deployment
- **Location:** `/var/www/tms-backend/tms-backend-0.0.1-SNAPSHOT.jar`
- **Size:** 162MB (Spring Boot with embedded static files)
- **Status:** Uploaded
- **Contains:** privacy.html, terms.html in BOOT-INF/classes/static/

---

## ⚠️ Required Configuration

### 1. Install Java 21
```bash
# On AlmaLinux 9.6
dnf install -y java-21-openjdk java-21-openjdk-devel
```

### 2. Configure Backend Service

**Create systemd service:** `/etc/systemd/system/tms-backend.service`

```ini
[Unit]
Description=TMS Backend Spring Boot Application
After=network.target mysql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/tms-backend
ExecStart=/usr/bin/java -jar tms-backend-0.0.1-SNAPSHOT.jar

# Environment variables (CRITICAL - update with real values)
Environment="SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/tms_db"
Environment="SPRING_DATASOURCE_USERNAME=tms_user"
Environment="SPRING_DATASOURCE_PASSWORD=your_mysql_password"
Environment="JWT_SECRET_KEY=your_jwt_secret_minimum_64_chars"
Environment="JWT_REFRESH_SECRET_KEY=your_jwt_refresh_secret_minimum_64_chars"
Environment="REDIS_HOST=localhost"
Environment="REDIS_PORT=6379"
Environment="FIREBASE_CREDENTIALS_PATH=/var/www/tms-backend/firebase-credentials.json"

# Performance tuning
Environment="JAVA_OPTS=-Xmx2G -Xms1G"

Restart=on-failure
RestartSec=10

StandardOutput=journal
StandardError=journal
SyslogIdentifier=tms-backend

[Install]
WantedBy=multi-user.target
```

**Enable and start:**
```bash
systemctl daemon-reload
systemctl enable tms-backend
systemctl start tms-backend
systemctl status tms-backend
```

### 3. Configure Apache Virtual Host

**Since cPanel manages Apache**, configure through cPanel or create custom conf:

**Option A: cPanel (Recommended)**
1. Login to WHM/cPanel
2. Create subdomain: `svtms.svtrucking.biz`
3. Point document root to `/var/www/tms-frontend`
4. Enable SSL via Let's Encrypt
5. Add reverse proxy rules for `/api`, `/ws`, `/uploads`

**Option B: Manual Apache Config** (if direct access available)

Create `/etc/apache2/conf.d/tms.conf`:

```apache
<VirtualHost *:80>
    ServerName svtms.svtrucking.biz
    DocumentRoot /var/www/tms-frontend

    # Redirect to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName svtms.svtrucking.biz
    DocumentRoot /var/www/tms-frontend

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/svtms.svtrucking.biz/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/svtms.svtrucking.biz/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/svtms.svtrucking.biz/chain.pem

    # Frontend static files
    <Directory /var/www/tms-frontend>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # API reverse proxy
    ProxyPreserveHost On
    ProxyPass /api http://localhost:8080/api
    ProxyPassReverse /api http://localhost:8080/api

    # WebSocket reverse proxy
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /ws(.*) ws://localhost:8080/ws$1 [P,L]
    ProxyPass /ws http://localhost:8080/ws
    ProxyPassReverse /ws http://localhost:8080/ws

    # Uploads
    ProxyPass /uploads http://localhost:8080/uploads
    ProxyPassReverse /uploads http://localhost:8080/uploads

    # Privacy/Terms (served by backend)
    ProxyPass /privacy.html http://localhost:8080/privacy.html
    ProxyPassReverse /privacy.html http://localhost:8080/privacy.html
    ProxyPass /terms.html http://localhost:8080/terms.html
    ProxyPassReverse /terms.html http://localhost:8080/terms.html

    # Fallback to Angular routing
    <Directory /var/www/tms-frontend>
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.html$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.html [L]
    </Directory>

    ErrorLog /var/log/httpd/tms-error.log
    CustomLog /var/log/httpd/tms-access.log combined
</VirtualHost>
```

**Enable modules and restart:**
```bash
a2enmod proxy proxy_http proxy_wstunnel rewrite ssl
systemctl restart httpd
```

### 4. SSL Certificate

**If using Let's Encrypt (recommended):**
```bash
dnf install -y certbot python3-certbot-apache
certbot --apache -d svtms.svtrucking.biz
```

---

## 🔧 Post-Deployment Verification

### Backend Health Check
```bash
curl http://localhost:8080/api/actuator/health
# Expected: {"status":"UP"}
```

### Frontend Accessibility
```bash
curl -I https://svtms.svtrucking.biz
# Expected: 200 OK
```

### Privacy/Terms Pages
```bash
curl https://svtms.svtrucking.biz/privacy.html | head -20
curl https://svtms.svtrucking.biz/terms.html | head -20
```

### WebSocket Connection
```bash
wscat -c wss://svtms.svtrucking.biz/ws
# (Requires token)
```

---

## 📝 Environment Variables Required

You'll need these values before starting backend:

1. **Database Credentials:**
   - MySQL host/port
   - Database name (`tms_db`)
   - Username/password

2. **JWT Secrets:**
   - Generate with: `openssl rand -base64 64`
   - Need two separate secrets (access + refresh)

3. **Redis Configuration:**
   - Host/port (likely localhost:6379)

4. **Firebase Credentials:**
   - Place `firebase-credentials.json` in `/var/www/tms-backend/`
   - Update path in service file

---

## 🚨 Critical Notes

1. **cPanel Environment:** This VPS uses cPanel, so prefer cPanel UI for domain/SSL management over manual Apache config
2. **Java Not Installed:** Must install Java 21 before backend can run
3. **Database Required:** Backend expects MySQL database at startup
4. **Firebase Required:** Push notifications need Firebase credentials file
5. **Firewall:** Ensure port 8080 is NOT exposed externally (only localhost access via Apache proxy)

---

## 📂 Current File Locations

```
/var/www/tms-backend/
├── tms-backend-0.0.1-SNAPSHOT.jar (162MB)
└── firebase-credentials.json (needs to be added)

/var/www/tms-frontend/
├── index.html
├── assets/
├── chunk-*.js (optimized bundles)
└── (all Angular production files)
```

---

## Next Steps

1. **Immediate:**
   - Install Java 21: `dnf install java-21-openjdk`
   - Get database credentials
   - Generate JWT secrets

2. **Backend Setup:**
   - Upload `firebase-credentials.json`
   - Create systemd service with environment variables
   - Start backend: `systemctl start tms-backend`

3. **Frontend Setup:**
   - Configure Apache/cPanel for domain
   - Install SSL certificate
   - Add proxy rules for `/api`, `/ws`, `/uploads`

4. **Testing:**
   - Verify backend health endpoint
   - Test frontend loads
   - Check privacy/terms URLs
   - Confirm WebSocket connectivity

---

**Deployment Status:** 🟡 Files Ready, Configuration Pending  
**Blocking Issues:** Java not installed, systemd service not configured  
**Estimated Time to Complete:** 30-60 minutes (with credentials available)

> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 📁 Uploads Configuration Guide

## Overview

The SV-TMS application includes a comprehensive file upload system that works across all environments (development, production, and testing). This guide covers the configuration, maintenance, and troubleshooting of the uploads functionality.

## 🏗️ Architecture

### Directory Structure
```
uploads/
├── proofs/          # Load delivery proofs
├── documents/       # General documents
├── licenses/        # Driver licenses
├── maintenance/     # Vehicle maintenance documents
└── temp/           # Temporary files (auto-cleaned)
```

### Environment Configuration

#### Development (`application-local.properties`)
```properties
file.upload.base-dir=uploads/
spring.servlet.multipart.max-file-size=50MB
spring.servlet.multipart.max-request-size=100MB
```

#### Production (`application-prod.properties`)
```properties
file.upload.base-dir=/app/uploads/
spring.servlet.multipart.max-file-size=50MB
spring.servlet.multipart.max-request-size=100MB
```

#### Testing (`application-test.properties`)
```properties
file.upload.base-dir=target/test-uploads/
spring.servlet.multipart.max-file-size=10MB
spring.servlet.multipart.max-request-size=20MB
```

## 🐳 Docker Configuration

### Development (`docker-compose.dev.yml`)
```yaml
services:
  backend:
    volumes:
      - ./uploads:/app/uploads:rw
    healthcheck:
      test: ["CMD", "test", "-w", "/app/uploads"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Production (`docker-compose.yml`)
```yaml
services:
  backend:
    volumes:
      - uploads-data:/app/uploads:rw
    healthcheck:
      test: ["CMD", "test", "-w", "/app/uploads"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  uploads-data:
```

## 🔧 Maintenance Scripts

### Initialization Script (`init-uploads.sh`)
Creates required directories with proper permissions during container startup.

```bash
#!/bin/bash
# Create uploads directories with proper permissions
mkdir -p /app/uploads/{proofs,documents,licenses,maintenance,temp}
chown -R spring:spring /app/uploads
chmod -R 755 /app/uploads
```

### Backup Script (`backup_docker_uploads.sh`)
Creates compressed backups of uploads from running containers.

**Usage:**
```bash
./backup_docker_uploads.sh
```

**Features:**
- Creates timestamped backups: `uploads-YYYY-MM-DD_HH-MM-SS.tar.gz`
- Automatic cleanup of backups older than 7 days
- Docker-aware (backs up from running containers)
- Colored output with progress indicators

### Restore Script (`restore_uploads.sh`)
Restores uploads from backup archives.

**Usage:**
```bash
./restore_uploads.sh uploads-2024-01-15_14-30-00.tar.gz
```

**Features:**
- Interactive confirmation before restore
- Creates safety backup before restore
- Automatic permission fixing after restore
- Docker-aware restore into running containers
- Rollback capability if restore fails

## 🏥 Health Monitoring

### Health Check Endpoints

#### Basic Health Check
```
GET /api/health
```
Response:
```json
{
  "status": "UP",
  "timestamp": 1705123456789,
  "service": "sv-tms-backend"
}
```

#### Detailed Health Check
```
GET /api/health/detailed
```
Response:
```json
{
  "status": "UP",
  "timestamp": 1705123456789,
  "service": "sv-tms-backend",
  "uploads": {
    "status": "UP",
    "path": "/app/uploads",
    "absolutePath": "/app/uploads",
    "fileCount": 42,
    "totalSpace": 1073741824,
    "freeSpace": 536870912,
    "usableSpace": 536870912,
    "readable": true,
    "writable": true
  }
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Upload Directory Not Writable
**Symptoms:** File uploads fail with permission errors
**Solution:**
```bash
# Check permissions
ls -la /app/uploads

# Fix permissions
chown -R spring:spring /app/uploads
chmod -R 755 /app/uploads
```

#### 2. Docker Volume Not Mounted
**Symptoms:** Files uploaded but not persisted
**Check:**
```bash
# Check if volume is mounted
docker exec svtms-backend df -h | grep uploads

# Check docker-compose volumes configuration
docker-compose config
```

#### 3. Health Check Failing
**Symptoms:** `/api/health/detailed` shows uploads status as DOWN
**Check:**
```bash
# Test directory access
docker exec svtms-backend ls -la /app/uploads

# Test write access
docker exec svtms-backend touch /app/uploads/test.txt
```

### File Size Limits

| Environment | Max File Size | Max Request Size |
|-------------|---------------|------------------|
| Development | 50MB         | 100MB           |
| Production  | 50MB         | 100MB           |
| Testing     | 10MB         | 20MB            |

### Supported File Types
- Images: JPG, PNG, GIF, WebP
- Documents: PDF, DOC, DOCX, XLS, XLSX
- Archives: ZIP, RAR (for bulk uploads)

## 📊 Monitoring

### Key Metrics to Monitor
- Upload success/failure rates
- File size distributions
- Storage space usage
- Health check status

### Log Files
- Application logs: `logs/spring.log`
- Upload-specific logs: Check controller logs for upload operations

## 🔐 Security Considerations

### File Upload Security
- File type validation on both client and server
- Size limits enforced
- Path traversal protection
- Secure file naming (UUID-based)

### Access Control
- Upload endpoints protected by authentication
- File serving through controlled static resource paths
- Directory permissions restrict access to application user only

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] Verify `application-*.properties` configurations
- [ ] Test Docker volume mounts
- [ ] Run initialization script
- [ ] Verify health check endpoints

### Post-Deployment
- [ ] Test file upload functionality
- [ ] Verify backup scripts work
- [ ] Check health monitoring
- [ ] Validate file permissions

## 📞 Support

For issues with uploads configuration:
1. Check health endpoint: `/api/health/detailed`
2. Review application logs
3. Verify Docker volume configuration
4. Test backup/restore procedures

---

**Last Updated:** January 2024
**Version:** 1.0
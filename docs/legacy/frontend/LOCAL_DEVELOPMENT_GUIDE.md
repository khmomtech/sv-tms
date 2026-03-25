> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Local Development Setup Guide

This guide shows how to run the TMS application locally for faster development, debugging, and testing.

## 🚀 Quick Start

### Option 1: Automated Setup
```bash
# Start databases and get setup instructions
./setup-local-dev.sh

# In separate terminals:
./start-backend-local.sh   # Terminal 1
./start-frontend-local.sh  # Terminal 2
```

### Option 2: Manual Setup

#### 1. Start Databases Only
```bash
docker-compose -f docker-compose.local-dev.yml up -d
```

#### 2. Start Backend Locally
```bash
cd tms-backend
export SPRING_PROFILES_ACTIVE=local
./mvnw spring-boot:run
```

#### 3. Start Frontend Locally
```bash
cd tms-frontend
npm ci --legacy-peer-deps  # First time only
npm run start -- --host 0.0.0.0 --port 4200
```

## 🔧 Configuration

### Database Connections (Docker)
- **MySQL**: `localhost:3307`
- **Redis**: `localhost:6379`

### Application URLs (Local)
- **Frontend**: http://localhost:4200
- **Backend API**: http://localhost:8080/api
- **Swagger UI**: http://localhost:8080/swagger-ui.html

### Environment Variables (Backend)
```bash
SPRING_PROFILES_ACTIVE=local
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3307/svlogistics_tms_db
SPRING_DATASOURCE_USERNAME=driver
SPRING_DATASOURCE_PASSWORD=driverpass
SPRING_DATA_REDIS_HOST=localhost
SPRING_DATA_REDIS_PORT=6379
```

## ⚡ Benefits of Local Development

### Performance
- **Faster startup**: ~30-60 seconds vs 2-3 minutes with full Docker
- **Instant reload**: Hot reload for both Spring Boot and Angular
- **No container overhead**: Direct process execution

### Development Experience
- **Better debugging**: Direct IDE integration with breakpoints
- **Live reload**: Automatic recompilation on code changes
- **Resource efficiency**: Lower CPU and memory usage
- **Network performance**: No Docker network overhead

### Workflow Improvements
- **Faster iteration**: Immediate feedback on code changes
- **Easy profiling**: Direct JVM access for performance analysis
- **Simplified logging**: Direct console output and file logging
- **Database access**: Direct connection for queries and debugging

## 🛠 Development Workflow

### Backend Development
```bash
# Start backend with auto-reload
cd tms-backend
./mvnw spring-boot:run

# The backend will automatically restart when you:
# - Modify Java files
# - Change configuration files
# - Update dependencies
```

### Frontend Development
```bash
# Start frontend with hot reload
cd tms-frontend
npm run start

# The frontend will automatically reload when you:
# - Modify TypeScript/HTML/CSS files
# - Update Angular components
# - Change configuration
```

## 🔍 Debugging

### Backend Debugging
1. **IDE Integration**: Set breakpoints directly in your IDE
2. **Remote Debug**: Add JVM debug flags if needed:
   ```bash
   ./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
   ```

### Frontend Debugging
1. **Browser DevTools**: Full access to Angular DevTools
2. **Source Maps**: Original TypeScript debugging in browser
3. **Network Tab**: Monitor API calls to backend

## 🗄 Database Management

### Access Database
```bash
# MySQL via Docker
docker exec -it svtms-mysql-local mysql -u driver -p svlogistics_tms_db

# Redis via Docker
docker exec -it svtms-redis-local redis-cli
```

### Backup/Restore
```bash
# Backup (uses existing scripts)
./backup_docker_mysql.sh

# Restore from backup
./restore_mysql.sh
```

## 🔄 Switching Between Modes

### Switch to Full Docker Mode
```bash
# Stop local processes (Ctrl+C in terminals)
# Stop local databases
docker-compose -f docker-compose.local-dev.yml down

# Start full Docker stack
docker-compose -f docker-compose.dev.yml up --build
```

### Switch to Local Development
```bash
# Stop full Docker stack
docker-compose -f docker-compose.dev.yml down

# Start local development
./setup-local-dev.sh
```

## 🐛 Troubleshooting

### Port Conflicts
- **3307**: MySQL (change in `docker-compose.local-dev.yml`)
- **6379**: Redis (change in `docker-compose.local-dev.yml`)
- **8080**: Backend (change in `application-local.properties`)
- **4200**: Frontend (change via `--port` flag)

### Database Connection Issues
```bash
# Check if databases are running
docker ps | grep svtms

# Check database logs
docker logs svtms-mysql-local
docker logs svtms-redis-local

# Restart databases if needed
docker-compose -f docker-compose.local-dev.yml restart
```

### Backend Issues
```bash
# Check Java version
java -version

# Clean and rebuild
cd tms-backend
./mvnw clean package

# Check application logs
tail -f logs/application.log
```

### Frontend Issues
```bash
# Clear node_modules and reinstall
cd tms-frontend
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps

# Check for Angular CLI updates
ng version
```

## 📊 Performance Comparison

| Aspect | Docker Mode | Local Mode | Improvement |
|--------|-------------|------------|-------------|
| Startup Time | 2-3 minutes | 30-60 seconds | 60-75% faster |
| Hot Reload | 10-30 seconds | 1-5 seconds | 80-90% faster |
| Memory Usage | ~4GB | ~1-2GB | 50% less |
| CPU Usage | High | Low | 40-60% less |
| Build Time | 3-5 minutes | 1-2 minutes | 50-70% faster |

## 🎯 Best Practices

1. **Use Local for Development**: Day-to-day coding and testing
2. **Use Docker for Integration**: Testing full stack interactions
3. **Use Docker for Production**: Deployment and CI/CD pipelines
4. **Keep Databases in Docker**: Consistent data and easier management
5. **Monitor Resource Usage**: Local development is more efficient

## 🔗 Related Files

- `docker-compose.local-dev.yml` - Database-only Docker setup
- `tms-backend/src/main/resources/application-local.properties` - Backend local config
- `tms-frontend/proxy.conf.json` - Frontend proxy configuration
- `setup-local-dev.sh` - Automated local setup
- `start-backend-local.sh` - Backend startup script
- `start-frontend-local.sh` - Frontend startup script
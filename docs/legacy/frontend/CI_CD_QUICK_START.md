> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 CI/CD Quick Start Guide

**Get up and running with CI/CD in 15 minutes**

---

## 📋 Prerequisites Check (5 minutes)

Run these commands to verify your setup:

```bash
# Check Git
git --version
# Expected: git version 2.x.x

# Check Docker
docker --version
docker compose version
# Expected: Docker version 24.x.x, Docker Compose version v2.x.x

# Check Java
java -version
# Expected: openjdk version "21.x.x"

# Check Node.js
node --version
npm --version
# Expected: v20.x.x, 10.x.x

# Check Flutter (if doing mobile work)
flutter --version
# Expected: Flutter 3.x.x • channel stable
```

**If any are missing**, see the [CI/CD Handbook - Prerequisites Section](./CI_CD_HANDBOOK.md#2-prerequisites)

---

## ⚡ Your First CI Run (5 minutes)

### Step 1: Make a Small Change

```bash
# Navigate to your project
cd /Users/sotheakh/Documents/develop/sv-tms

# Create a new branch
git checkout -b test/my-first-ci-run

# Make a small change (add a comment to a file)
echo "// Testing CI/CD pipeline" >> driver-app/src/main/java/com/example/Main.java

# Commit and push
git add .
git commit -m "test: verify CI/CD pipeline"
git push origin test/my-first-ci-run
```

### Step 2: Watch the CI Run

1. Go to GitHub: https://github.com/khetsothea/customer_app
2. Click **"Actions"** tab at the top
3. You'll see your workflow running with a yellow dot 🟡
4. Click on the workflow to see details
5. Watch each step complete ✅

### Step 3: Check Results

When complete, you'll see:
- **Backend CI** - Compiled and tested Java code
- **All checks passed** - Green checkmark on your commit

---

## 🔧 Running CI Checks Locally (5 minutes)

**Always test locally before pushing!**

### Quick Test Script

Create this file to test everything at once:

```bash
# Save as: run-ci-checks.sh
#!/bin/bash
set -e

echo "🔍 Running CI checks locally..."

# Backend
echo "📦 Testing Backend..."
cd driver-app
./mvnw clean test -B
cd ..

# Angular
echo "🅰️  Testing Angular..."
cd tms-frontend
npm ci --quiet
npm run build
cd ..

# Flutter (optional)
echo "📱 Testing Flutter..."
cd tms_driver_app
flutter pub get
flutter analyze
flutter test
cd ..

echo "All CI checks passed locally!"
```

Make it executable and run:

```bash
chmod +x run-ci-checks.sh
./run-ci-checks.sh
```

---

## 🐳 Docker Quick Commands

### Start Development Stack

```bash
# Start everything
docker compose -f docker-compose.dev.yml up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f backend
```

### Stop Development Stack

```bash
# Stop everything
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v
```

### Troubleshooting

```bash
# Container won't start?
docker compose logs backend

# Rebuild from scratch
docker compose down -v
docker compose build --no-cache
docker compose up -d

# Clean up space
docker system prune -af
```

---

## 🎯 Common Workflows

### Workflow 1: Fix a Bug

```bash
# 1. Create branch
git checkout -b fix/bug-description

# 2. Make changes in your editor

# 3. Test locally
cd driver-app && ./mvnw test

# 4. Commit
git add .
git commit -m "fix: description of bug fix"

# 5. Push and create PR
git push origin fix/bug-description
# Then create PR on GitHub

# 6. Wait for CI ✅

# 7. Merge when approved
```

### Workflow 2: Add New Feature

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Develop feature with iterative testing
cd driver-app
./mvnw spring-boot:run  # Test as you code

# 3. Run full test suite
./mvnw clean test

# 4. Commit and push
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 5. Create PR, wait for CI, get reviewed, merge
```

### Workflow 3: Update Dependencies

```bash
# Backend (Maven)
cd driver-app
./mvnw versions:display-dependency-updates
# Review updates, edit pom.xml
./mvnw clean test  # Verify everything works

# Frontend (npm)
cd tms-frontend
npm outdated
npm update  # Safe updates
npm test    # Verify

# Commit
git add pom.xml package.json package-lock.json
git commit -m "chore: update dependencies"
git push
```

---

## 📊 Understanding CI Results

### All Green - Success!

```
Backend CI
Angular CI  
Flutter CI
All checks passed
```

**You can merge!** Your code is ready.

### ❌ Red X - Failure

```
❌ Backend CI
  └─ Tests failed: 3 failures
```

**What to do:**
1. Click on the failed job
2. Read the error logs
3. Fix the issue locally
4. Push again

### 🟡 Yellow Circle - Running

```
🟡 Backend CI - In progress
```

**Wait for it to complete** (usually 2-5 minutes)

---

## 🆘 Quick Troubleshooting

### Issue: "Tests fail in CI but pass locally"

**Cause**: Environment differences

**Solution**:
```bash
# Run tests exactly as CI does
docker run --rm -v $(pwd)/driver-app:/app -w /app maven:3.9.5-eclipse-temurin-21 mvn clean test
```

### Issue: "Docker build fails - out of space"

**Cause**: Docker cache full

**Solution**:
```bash
docker system df  # Check usage
docker system prune -af  # Clean everything
docker volume prune  # Clean volumes
```

### Issue: "Can't push - protected branch"

**Cause**: Trying to push directly to `main`

**Solution**:
```bash
# Always use a branch
git checkout -b fix/my-fix
git push origin fix/my-fix
# Then create PR
```

### Issue: "Maven build fails - dependencies"

**Cause**: Network or cache issues

**Solution**:
```bash
# Clear Maven cache
rm -rf ~/.m2/repository
./mvnw clean install
```

---

## 📱 Mobile App Specifics

### Testing Flutter App

```bash
cd tms_driver_app

# Get dependencies
flutter pub get

# Run on simulator/emulator
flutter run

# Run tests
flutter test

# Build APK (Android)
flutter build apk

# Build iOS (requires macOS + Xcode)
flutter build ios
```

### Generate OpenAPI Client for Flutter

```bash
# Trigger from GitHub Actions UI:
# 1. Go to Actions tab
# 2. Click "Generate OpenAPI Dart Client"
# 3. Click "Run workflow"
# 4. Wait ~2 minutes
# 5. Pull changes: git pull origin main
```

---

## 🎓 Next Steps

1. **Read the full handbook**: [CI_CD_HANDBOOK.md](./CI_CD_HANDBOOK.md)
2. **Set up your IDE**:
   - Install Docker extension
   - Install GitHub Actions extension
   - Configure auto-format on save
3. **Practice the workflow**:
   - Make a branch
   - Make a change
   - Test locally
   - Push and watch CI
4. **Configure branch protection**:
   - Require PR reviews
   - Require CI to pass
5. **Set up deployment**:
   - Configure secrets
   - Test deployment to staging
   - Deploy to production

---

## 📚 Related Documents

- [CI/CD Handbook (Full Guide)](./CI_CD_HANDBOOK.md) - Complete A-Z reference
- [Developer Onboarding Checklist](./DEVELOPER_ONBOARDING_CHECKLIST.md) - For new team members
- [Daily Developer Guide](./DAILY_DEVELOPER_GUIDE.md) - Daily workflows
- [Quick Start](./🚀_QUICK_START.md) - Project quick start

---

## 💡 Pro Tips

1. **Run tests before committing**: Save time, catch issues early
2. **Use meaningful commit messages**: Helps with debugging and history
3. **Keep PRs small**: Easier to review, faster to merge
4. **Monitor CI run times**: If builds get slow, optimize
5. **Clean up branches**: Delete merged branches to stay organized

---

**Last Updated**: November 16, 2025  
**Time to Complete**: ~15 minutes  
**Difficulty**: Beginner-friendly

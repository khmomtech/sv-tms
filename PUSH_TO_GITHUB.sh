#!/usr/bin/env bash
# ============================================================
# SV-TMS → GitHub Push Script
#
# Run this from your Terminal (NOT in Cowork):
#
#   macOS:   Open Terminal, then:
#              cd "$(dirname "$0")" && bash PUSH_TO_GITHUB.sh
#
#   Windows: Open "Git Bash" in this folder, then:
#              bash PUSH_TO_GITHUB.sh
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
REMOTE="https://YOUR_GITHUB_USERNAME:YOUR_GITHUB_TOKEN_HERE@github.com/svtrucking/sv-tms.git"

# Verify repository exists
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "❌  Git repository not found: $REPO_DIR/.git"
  echo "    Make sure you are running this from the sv-tms project folder."
  exit 1
fi

echo ""
echo "================================================================"
echo "  SV-TMS → GitHub push"
echo "  Target: https://github.com/svtrucking/sv-tms"
echo "================================================================"
echo ""

cd "$REPO_DIR"

echo "▶ Configuring remote..."
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

echo "▶ Pushing to GitHub (this may take 1-2 minutes)..."
git push -u origin main --force

echo ""
echo "================================================================"
echo "  ✅ SUCCESS! Code is now on GitHub."
echo ""
echo "  GitHub Actions will now automatically:"
echo "    1. Run tests"
echo "    2. Build 8 Docker images"
echo "    3. Deploy to your VPS"
echo "    4. Make https://svtms.svtrucking.biz live"
echo ""
echo "  Watch progress: https://github.com/svtrucking/sv-tms/actions"
echo "================================================================"
echo ""

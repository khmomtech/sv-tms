#!/bin/bash
# =========================================
# 📁 Uploads Directory Initialization Script
# =========================================
# This script ensures that upload directories exist with proper permissions
# Run during container startup to prepare the file system for uploads

set -e

echo "🔧 Initializing uploads directories..."

# Base uploads directory
UPLOADS_DIR="/app/uploads"

# Create base directory if it doesn't exist
if [ ! -d "$UPLOADS_DIR" ]; then
    echo "📁 Creating uploads base directory: $UPLOADS_DIR"
    mkdir -p "$UPLOADS_DIR"
fi

# Create subdirectories
SUBDIRS=("documents" "licenses" "profiles" "temp")

for subdir in "${SUBDIRS[@]}"; do
    dir_path="$UPLOADS_DIR/$subdir"
    if [ ! -d "$dir_path" ]; then
        echo "📁 Creating subdirectory: $dir_path"
        mkdir -p "$dir_path" 2>/dev/null || echo "⚠️  Could not create $dir_path (may already exist or permission issue)"
    fi
done

# Set proper permissions (readable/writable by app user, readable by others)
echo "🔒 Setting directory permissions..."
chmod -R 755 "$UPLOADS_DIR" 2>/dev/null || echo "⚠️  Could not set permissions on $UPLOADS_DIR"

# Ensure appuser owns the directories (if running as appuser)
if id -u appuser > /dev/null 2>&1; then
    echo "👤 Setting ownership to appuser..."
    # Try to set ownership, but don't fail if we can't (volume permissions)
    chown -R appuser:appuser "$UPLOADS_DIR" 2>/dev/null || echo "⚠️  Could not set ownership on $UPLOADS_DIR (volume may override)"
    
    # If ownership failed, try to at least make directories writable
    if [ ! -w "$UPLOADS_DIR" ]; then
        echo "🔧 Attempting to fix permissions for volume-mounted directories..."
        chmod -R 777 "$UPLOADS_DIR" 2>/dev/null || echo "⚠️  Could not set write permissions on $UPLOADS_DIR"
    fi
fi

echo "Uploads directories initialization completed!"
echo "📊 Directory structure:"
find "$UPLOADS_DIR" -type d 2>/dev/null | sed 's|[^/]*/|- |g' || echo "   Could not list directories"
#!/usr/bin/env bash
set -euo pipefail

# infra/install_mysql.sh
# Installs MySQL Server on Ubuntu and creates a database + user for the app.
# Usage (recommended):
#   sudo bash infra/install_mysql.sh '<ROOT_PASS>' svlogistics_tms_db svtms '<SVTMS_PASS>' [ALLOW_REMOTE_FROM]
# Example:
#   sudo bash infra/install_mysql.sh 'ChangeMeRoot!' svlogistics_tms_db svtms 'S3cureP@ss' 203.0.113.10

ROOT_PASS=${1:-ChangeMeRoot!}
DB_NAME=${2:-svlogistics_tms_db}
DB_USER=${3:-svtms}
DB_PASS=${4:-svtms_password}
ALLOW_REMOTE_FROM=${5:-}

echo "Installing MySQL server..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo "Ensuring MySQL is running"
systemctl enable --now mysql

# Secure root: set password and switch to mysql_native_password
cat > /tmp/mysql_secure_setup.sql <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
SQL

mysql < /tmp/mysql_secure_setup.sql
rm -f /tmp/mysql_secure_setup.sql

# Create database and user
cat > /tmp/mysql_create_db.sql <<SQL
CREATE DATABASE IF NOT EXISTS \
  \\`${DB_NAME}\\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \\`${DB_NAME}\\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

mysql < /tmp/mysql_create_db.sql
rm -f /tmp/mysql_create_db.sql

# Configure remote access if requested
if [ -n "${ALLOW_REMOTE_FROM}" ]; then
  echo "Configuring MySQL to listen on all addresses (bind-address = 0.0.0.0)"
  CONF_FILE=/etc/mysql/mysql.conf.d/mysqld.cnf
  sudo sed -i "s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" "$CONF_FILE" || true
  systemctl restart mysql

  echo "Allowing ${ALLOW_REMOTE_FROM} to access port 3306 via UFW"
  if command -v ufw >/dev/null 2>&1; then
    ufw allow from ${ALLOW_REMOTE_FROM} to any port 3306 proto tcp || true
  fi
fi

cat <<EOF
MySQL installed and initialized.
Database: ${DB_NAME}
User: ${DB_USER}
Password: ${DB_PASS}
Connection URL (JDBC): jdbc:mysql://<DB_HOST>:3306/${DB_NAME}
Replace <DB_HOST> with 'localhost' if app runs on same host, or the server IP when remote.
EOF

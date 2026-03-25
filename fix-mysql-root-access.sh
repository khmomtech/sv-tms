#!/bin/bash
# This script will create and grant MySQL root user access from any host for local development.
# Usage: docker exec -i svtms-mysql bash < fix-mysql-root-access.sh

mysql -uroot -prootpass <<EOF
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'rootpass';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'192.168.65.1' IDENTIFIED BY 'rootpass';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.65.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

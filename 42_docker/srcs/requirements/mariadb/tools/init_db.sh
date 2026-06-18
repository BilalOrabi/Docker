#!/bin/bash

set -e

echo "Starting MariaDB initialization..."

# Ensure socket directory exists with proper permissions
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld
chmod 755 /var/run/mysqld

# Fail Fast: Check for required environment variables before doing anything
if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ]; then
    echo "Error: MYSQL_DATABASE or MYSQL_USER environment variables are missing."
    exit 1
fi

# Fail Fast: Check for Docker secrets
if [ ! -f "/run/secrets/db_root_password" ] || [ ! -f "/run/secrets/db_password" ]; then
    echo "Error: Secret files not found at /run/secrets/"
    exit 1
fi

ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Isolate first-time setup logic
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run detected. Initializing data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    echo "Starting temporary MariaDB server for setup..."
    mysqld --skip-networking --socket=/var/run/mysqld/mysqld.sock --user=mysql &
    pid="$!"

    echo "Waiting for temporary MariaDB to be ready..."
    until mysqladmin --socket=/var/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
        sleep 1
    done
    echo "Temporary MariaDB is ready!"

    echo "Running setup SQL..."
    # Encapsulating database names in backticks is a good habit in case of reserved words
    mysql --socket=/var/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary MariaDB..."
    mysqladmin --socket=/var/run/mysqld/mysqld.sock -u root -p"${ROOT_PASSWORD}" shutdown

    wait "$pid" || true
else
    echo "Database directory already exists. Skipping first-time setup."
fi

echo "Starting MariaDB in the foreground..."
# Remove old socket file if it exists
rm -f /var/run/mysqld/mysqld.sock

# Verify data directory exists
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Error: MySQL data directory not initialized!"
    exit 1
fi

echo "MariaDB ready to start..."
# Use exec to replace the shell with mysqld so container PID is mysqld
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysqld.sock --bind-address=0.0.0.0
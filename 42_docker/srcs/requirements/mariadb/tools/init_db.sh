#!/bin/bash

set -e

echo "Starting MariaDB initialization..."

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
    mysqld --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql &
    pid="$!"

    echo "Waiting for temporary MariaDB to be ready..."
    until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
        sleep 1
    done
    echo "Temporary MariaDB is ready!"

    echo "Running setup SQL..."
    # Encapsulating database names in backticks is a good habit in case of reserved words
    mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary MariaDB..."
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${ROOT_PASSWORD}" shutdown

    wait "$pid" || true
else
    echo "Database directory already exists. Skipping first-time setup."
fi

echo "MariaDB startup sequence initiated..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
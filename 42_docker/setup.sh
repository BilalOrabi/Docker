#!/bin/bash

echo "🚀 Starting Inception Setup..."

mkdir -p secrets

echo "--- Database Credentials ---"
read -s -p "Enter MariaDB Root Password: " DB_ROOT_PWD
echo ""
read -s -p "Enter WordPress Database Password: " DB_USER_PWD
echo ""

echo "--- WordPress Credentials ---"
read -p "Enter WordPress Admin Username: " WP_ADMIN_USER
read -s -p "Enter WordPress Admin Password: " WP_ADMIN_PWD
echo ""

echo "--- Infrastructure ---"
read -p "Enter your Domain Name (e.g., borabi.42.fr): " DOMAIN_NAME

# 5. Generate the secret files (Raw strings only)
# Using 'echo -n' is critical here so we don't add hidden newline characters to the passwords
echo -n "$DB_ROOT_PWD" > secrets/db_root_password.txt
echo -n "$DB_USER_PWD" > secrets/db_password.txt

# Credentials typically formatted with user on line 1, pass on line 2
echo "$WP_ADMIN_USER" > secrets/credentials.txt
echo "$WP_ADMIN_PWD" >> secrets/credentials.txt

# 6. Generate the .env file inside the srcs/ directory
cat << EOF > srcs/.env
DOMAIN_NAME=$DOMAIN_NAME
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_user
EOF

echo ""
echo "✅ Setup complete! The secrets/ directory and srcs/.env file have been generated."
echo "⚠️  CRITICAL: Ensure 'secrets/' and 'srcs/.env' are listed in your .gitignore!"
#!/bin/bash
set -e

WP_PATH="/var/www/html"

# 1. Read Database Password
if [ ! -f "/run/secrets/db_password" ]; then
    echo "Error: Secret file not found at /run/secrets/db_password"
    exit 1
fi

DB_PASSWORD=$(cat /run/secrets/db_password)

# 2. Read WordPress Credentials from the single credentials.txt secret
if [ ! -f "/run/secrets/credentials" ]; then
    echo "Error: Secret file not found at /run/secrets/credentials"
    exit 1
fi

# Use grep to find the line, and cut to split it at the '=' sign and take the 2nd part
WP_ADMIN_PASSWORD=$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/credentials | cut -d '=' -f2)
WP_USER_PASSWORD=$(grep '^WP_USER_PASSWORD=' /run/secrets/credentials | cut -d '=' -f2)

# Verify extraction worked (Fail Fast)
if [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_USER_PASSWORD" ]; then
    echo "Error: Failed to extract WordPress passwords from credentials file."
    exit 1
fi
# Validate DOMAIN_NAME format
if [ -z "${DOMAIN_NAME}" ]; then
    echo "Error: DOMAIN_NAME environment variable not set"
    exit 1
fi

if [[ ! "${DOMAIN_NAME}" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*\.42\.fr$ ]]; then
    echo "Warning: DOMAIN_NAME '${DOMAIN_NAME}' may not be in expected format (*.42.fr)"
fi

# Validate WordPress admin username against project rules
if [[ "${WORDPRESS_ADMIN_USER}" =~ ^[Aa]dmin ]]; then
    echo "Error: WORDPRESS_ADMIN_USER cannot contain 'admin' or 'Admin' at the beginning"
    exit 1
fi

if [[ "${WORDPRESS_ADMIN_USER}" =~ [Aa]dministrator ]]; then
    echo "Error: WORDPRESS_ADMIN_USER cannot contain 'administrator' or 'Administrator'"
    exit 1
fi

echo "Validated configuration successfully"

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "WordPress configuration not found. Starting fresh installation..."

    echo "Waiting for database to be ready..."
    until mysqladmin ping -h "${WORDPRESS_DB_HOST}" -u "${WORDPRESS_DB_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
        sleep 2
    done
    echo "Database is responsive!"

    wp core download --allow-root --path="$WP_PATH"

    wp config create --allow-root \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --path="$WP_PATH"

    wp core install --allow-root \
        --url="${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --path="$WP_PATH"

    wp user create --allow-root \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --role=author \
        --path="$WP_PATH"

    chown -R www-data:www-data "$WP_PATH"
    
    echo "WordPress setup complete."
else
    echo "WordPress already initialized, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
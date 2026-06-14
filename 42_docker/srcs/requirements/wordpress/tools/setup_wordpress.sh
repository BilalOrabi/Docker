#!/bin/bash
set -e

WP_PATH="/var/www/html"

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "WordPress configuration not found. Starting fresh installation..."

    echo "Waiting for database..."
    until mysqladmin ping -h "${WORDPRESS_DB_HOST}" -u "${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent 2>/dev/null; do
        sleep 2
    done
    echo "Database ready!"


    wp core download --allow-root --path="$WP_PATH"


    wp config create --allow-root \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
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
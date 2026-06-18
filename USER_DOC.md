# User Documentation

## Overview

This Inception infrastructure provides a complete WordPress website stack running in Docker containers. Below is a guide for end users and administrators to manage and access the system.

## Services Provided

The infrastructure provides the following services:

### 1. **Web Server (NGINX)**
- HTTPS reverse proxy on port 443
- TLS 1.2/1.3 encrypted connections
- Routes requests to WordPress application

### 2. **WordPress Content Management System**
- WordPress blog/website platform
- PHP 8.2 with FPM (FastCGI Process Manager)
- Run as `www-data` user for security

### 3. **Database Server (MariaDB)**
- MySQL-compatible database
- Stores WordPress posts, pages, users, and content
- Automatic backup through volume persistence

## Getting Started

### Starting the Services

```bash
cd /path/to/inception
make
```

This command will:
- Build all Docker images
- Create data directories
- Start all containers

**Expected output:**
```
Creating network "inception-network" with driver "bridge"
Creating volume "mariadb_data" with local driver
Creating volume "wordpress_data" with local driver
Creating mariadb  ... done
Creating wordpress ... done
Creating nginx     ... done
```

### Stopping the Services

```bash
make down
```

This stops all containers while preserving all data (volumes remain).

### Fully Stopping (Remove All Data)

```bash
make down-v
```

**Warning**: This removes all WordPress data and database content. Use only if you want to reset everything.

## Accessing the Website

### Website URL

Open your browser and navigate to:
```
https://borabi.42.fr
```

### Accepting Self-Signed Certificate

Since the project uses self-signed SSL certificates:
1. Browser will show a security warning
2. Click "Advanced" or "More Information"
3. Click "Proceed anyway" or "Accept Risk"

The certificate is valid and secure within your local environment.

## WordPress Administration

### Accessing the Admin Panel

1. Navigate to: `https://borabi.42.fr/wp-admin`
2. Enter credentials from `secrets/credentials.txt`

### User Credentials

```bash
cat secrets/credentials.txt
```

This file contains:
- Line 1: Administrator username
- Line 2: Administrator password

### Database Credentials

Database credentials are stored in:
- `secrets/db_root_password.txt` - MariaDB root password
- `secrets/db_password.txt` - WordPress database user password

**Security Note**: These files are NOT tracked by Git (in .gitignore) and should never be committed to version control.

## Managing Credentials

### Viewing Current Credentials

```bash
# View WordPress admin credentials
cat secrets/credentials.txt

# View database passwords (requires sudo)
sudo cat secrets/db_root_password.txt
sudo cat secrets/db_password.txt
```

### Changing WordPress Admin Password

1. Log into WordPress: `https://borabi.42.fr/wp-admin`
2. Go to Users → Your Profile
3. Scroll down to change password
4. Click "Update Profile"

### Accessing the Database

Connect to MariaDB from inside the WordPress container:

```bash
# Start interactive MariaDB shell
make ps  # Verify mariadb container is running
docker exec -it mariadb mysql -u wordpress_user -p
# Enter password from secrets/db_password.txt
```

## Monitoring Services

### Checking Service Status

```bash
make ps
```

**Expected output:**
```
NAME        COMMAND                  SERVICE      STATUS       PORTS
mariadb     "init_db.sh"             mariadb      Up 2 minutes 3306/tcp
wordpress   "setup_wordpress.sh"     wordpress    Up 2 minutes 9000/tcp
nginx       "generate_ssl.sh"        nginx        Up 2 minutes 0.0.0.0:443->443/tcp
```

All three services should be in `Up` status.

### Viewing Live Logs

```bash
make logs
```

This shows live output from all containers. Press `Ctrl+C` to exit.

### Viewing Logs for Specific Service

```bash
# View NGINX logs
docker compose -f srcs/docker-compose.yml logs -f nginx

# View WordPress/PHP logs
docker compose -f srcs/docker-compose.yml logs -f wordpress

# View Database logs
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

## Troubleshooting

### Services Not Starting

1. **Check container status:**
   ```bash
   make ps
   ```

2. **View detailed logs:**
   ```bash
   make logs
   ```

3. **Common issues:**
   - Port 443 already in use: Stop other HTTPS services
   - Domain not resolving: Check `/etc/hosts` has correct entry
   - Permissions error: Run with sudo if needed

### Website Not Loading

1. **Verify NGINX is running:**
   ```bash
   docker exec -it nginx nginx -t
   ```

2. **Check certificate:**
   ```bash
   docker exec -it nginx ls -la /etc/nginx/ssl/
   ```

3. **Restart NGINX:**
   ```bash
   docker compose -f srcs/docker-compose.yml restart nginx
   ```

### Database Connection Error

1. **Check MariaDB status:**
   ```bash
   docker compose -f srcs/docker-compose.yml logs mariadb
   ```

2. **Restart database:**
   ```bash
   docker compose -f srcs/docker-compose.yml restart mariadb
   ```

3. **Wait for initialization** (first start takes ~30 seconds):
   ```bash
   make logs
   ```
   Look for "Initialization complete" message.

### Forgot Admin Password

If you forgot the WordPress admin password:

1. Restart with fresh setup (warning: removes all content):
   ```bash
   make fclean
   make
   ```

2. Or use Docker to reset via WP-CLI:
   ```bash
   docker exec -it wordpress wp user update admin --prompt=user_pass
   ```

## Data Backup

### Backing Up WordPress Files

```bash
# Copy WordPress files from volume
docker run --rm -v wordpress_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/wordpress_backup.tar.gz -C /data .
```

### Backing Up Database

```bash
# Export database
docker exec mariadb mysqldump -u wordpress_user -p$(cat secrets/db_password.txt) \
  wordpress_db > wordpress_backup.sql
```

## Performance & Resource Usage

### Check Container Resource Usage

```bash
docker stats
```

Shows CPU, memory, and network usage for all containers.

### Expected Resource Usage

- **NGINX**: ~10-20 MB RAM
- **WordPress (PHP-FPM)**: ~50-100 MB RAM
- **MariaDB**: ~100-150 MB RAM
- **Total**: ~200-300 MB RAM

## Security Notes

1. **Self-Signed Certificates**: Used for local development. Replace with valid certificates for production.
2. **Default Credentials**: Change WordPress admin password immediately after first login.
3. **Database Access**: Only accessible within the Docker network, not from host.
4. **Secrets Storage**: Keep `/secrets` directory secure and never commit to Git.

## Getting Help

For more detailed technical information, see:
- `README.md` - Project overview and resources
- `DEV_DOC.md` - Developer setup and advanced configuration

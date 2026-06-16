# Developer Documentation

## Project Overview

Inception is a Docker-based infrastructure project implementing a WordPress stack with NGINX, PHP-FPM, and MariaDB. This document guides developers through setup, architecture, and development workflows.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Host Machine                      │
├─────────────────────────────────────────────────────┤
│  /home/<user>/data/                                 │
│  ├── mariadb/        → MariaDB persistent data      │
│  └── wordpress/      → WordPress files              │
│                                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │        Docker Network (inception-network)     │  │
│  │  ┌──────────┬─────────────┬────────────────┐  │  │
│  │  │ NGINX    │  WordPress  │   MariaDB      │  │  │
│  │  │ :443     │  :9000      │   :3306        │  │  │
│  │  └──────────┴─────────────┴────────────────┘  │  │
│  │                                                 │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

### System Requirements
- Linux OS (Ubuntu, Debian, Alpine, etc.) running on a Virtual Machine
- Docker 20.10+
- Docker Compose 2.0+
- `make` utility
- `git`
- sudo privileges

### Installation

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

## Project Structure

```
42_inception/
├── Makefile                          # Build orchestration
├── README.md                         # Project overview
├── USER_DOC.md                       # User guide
├── DEV_DOC.md                        # This file
├── .gitignore                        # Git exclusions
├── secrets/                          # Credentials (not in Git)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                          # Environment variables
    ├── docker-compose.yml            # Service definitions
    └── requirements/                 # Service Dockerfiles
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf    # MariaDB config
        │   └── tools/
        │       └── init_db.sh       # Database initialization
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── www.conf         # PHP-FPM config
        │   └── tools/
        │       └── setup_wordpress.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── nginx.conf       # NGINX config
        │   └── tools/
        │       └── generate_ssl.sh
        └── bonus/
            └── redis/                # Optional Redis service
```

## Initial Setup

### 1. Clone Repository

```bash
git clone <repo-url>
cd 42_inception
```

### 2. Configure Environment

Edit `srcs/.env` with your configuration:

```bash
DOMAIN_NAME=borabi.42.fr              
MYSQL_DATABASE=wordpress_db           # Keep or modify
MYSQL_USER=wordpress_user             # Keep or modify
WORDPRESS_ADMIN_USER=admin            # Change to non-standard name
WORDPRESS_ADMIN_PASSWORD=secure_pass  # Strong password
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=user
WORDPRESS_USER_EMAIL=user@example.com
WORDPRESS_USER_PASSWORD=user_pass
```

### 3. Create Secrets

Create `secrets/` directory with credential files:

```bash
mkdir -p secrets

# Create password files
echo -n "root_password_here" > secrets/db_root_password.txt
echo -n "wordpress_password_here" > secrets/db_password.txt

# Create credentials file
echo "admin_username" > secrets/credentials.txt
echo "admin_password" >> secrets/credentials.txt
```

**Important**: Files must be readable only by owner:
```bash
chmod 600 secrets/*
```

### 4. Configure Domain

Add entry to `/etc/hosts`:

```bash
sudo tee -a /etc/hosts > /dev/null <<< "127.0.0.1 borabi.42.fr"
```

### 5. Build and Launch

```bash
make
```

## Build Process

### Building Images

Each service has a dedicated Dockerfile built from Debian Bookworm:

#### MariaDB (`requirements/mariadb/Dockerfile`)
- Base: `debian:bookworm`
- Packages: mariadb-server
- Entry: Custom initialization script (`init_db.sh`)
- Port: 3306 (internal only)

#### WordPress (`requirements/wordpress/Dockerfile`)
- Base: `debian:bookworm`
- Packages: PHP 8.2, php-fpm, php-mysql, etc.
- Entry: Setup script (`setup_wordpress.sh`)
- Port: 9000 (FastCGI)

#### NGINX (`requirements/nginx/Dockerfile`)
- Base: `debian:bookworm`
- Packages: nginx, openssl
- Entry: SSL generation script (`generate_ssl.sh`)
- Port: 443 (HTTPS only)

### Building Images Manually

```bash
# Build specific service
docker compose -f srcs/docker-compose.yml build mariadb

# Build all services
docker compose -f srcs/docker-compose.yml build

# Build without cache
docker compose -f srcs/docker-compose.yml build --no-cache
```

## Container Management

### Starting Services

```bash
make up
```

Or manually:
```bash
docker compose -f srcs/docker-compose.yml up -d
```

### Stopping Services

```bash
make down                 # Keep volumes
make down-v              # Remove volumes
```

### Viewing Containers

```bash
make ps                  # List running containers
docker compose -f srcs/docker-compose.yml ps -a  # All containers
```

### Executing Commands in Container

```bash
# Interactive shell in WordPress container
docker exec -it wordpress /bin/bash

# Run MariaDB command
docker exec mariadb mysql -u wordpress_user -ppassword wordpress_db

# Run WP-CLI in WordPress container
docker exec wordpress wp --allow-root user list
```

### Viewing Container Logs

```bash
make logs                # All services, follow
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs --tail=50 mariadb
```

## Volume Management

### Docker Volumes

```bash
# List all volumes
docker volume ls

# Inspect volume details
docker volume inspect mariadb_data

# View volume mount path
docker volume inspect mariadb_data | grep Mountpoint
```

### Data Persistence Paths

- **Database**: `/home/<user>/data/mariadb`
- **WordPress**: `/home/<user>/data/wordpress`

### Backing Up Data

```bash
# Backup WordPress files
sudo tar -czf wordpress_backup.tar.gz /home/$(whoami)/data/wordpress

# Backup database
docker exec mariadb mysqldump -u wordpress_user -p$(cat secrets/db_password.txt) \
  wordpress_db > database_backup.sql
```

### Restoring Data

```bash
# Restore WordPress files
sudo tar -xzf wordpress_backup.tar.gz -C /home/$(whoami)/data

# Restore database
docker exec -i mariadb mysql -u wordpress_user -p$(cat secrets/db_password.txt) \
  wordpress_db < database_backup.sql
```

## Network Management

### Docker Network

```bash
# List networks
docker network ls

# Inspect inception-network
docker network inspect inception-network

# Test connectivity between containers
docker exec wordpress ping mariadb
docker exec wordpress ping nginx
```

### Service Discovery

Containers communicate using service names:
- `mariadb` → MariaDB container
- `wordpress` → WordPress container
- `nginx` → NGINX container

### Port Mapping

Only NGINX is exposed to host:
```
Host: 443 → Container: 443 (NGINX)
```

Other containers communicate internally:
- WordPress: 9000 (FastCGI, internal only)
- MariaDB: 3306 (internal only)

## Configuration Files

### MariaDB Config (`requirements/mariadb/conf/50-server.cnf`)

```ini
[mysqld]
bind-address = 0.0.0.0      # Listen on all interfaces
port = 3306                 # Standard MySQL port
socket = /var/run/mysqld/mysqld.sock
datadir = /var/lib/mysql
log-error = /var/log/mysql/error.log
pid-file = /var/run/mysqld/mysqld.pid
```

### PHP-FPM Config (`requirements/wordpress/conf/www.conf`)

```ini
[www]
user = www-data
group = www-data
listen = 9000               # FastCGI port
listen.owner = www-data
listen.group = www-data
pm = dynamic                # Process manager
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

### NGINX Config (`requirements/nginx/conf/nginx.conf`)

```nginx
server {
    listen 443 ssl http2;
    server_name borabi.42.fr;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;  # Connect to WordPress PHP-FPM
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

## Initialization Scripts

### MariaDB Initialization (`init_db.sh`)

1. Initializes data directory if empty
2. Starts temporary MariaDB instance
3. Creates database and users
4. Sets privileges
5. Shuts down temporary instance
6. Starts permanent daemon

**Key environment variables:**
- `MYSQL_ROOT_PASSWORD` (from secrets)
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD` (from secrets)

### WordPress Setup (`setup_wordpress.sh`)

1. Waits for database to be ready
2. Downloads WordPress core
3. Generates wp-config.php
4. Installs WordPress
5. Creates admin and regular users
6. Sets permissions
7. Starts PHP-FPM daemon

**Key environment variables:**
- `WORDPRESS_DB_HOST`
- `WORDPRESS_DB_NAME`
- `WORDPRESS_ADMIN_USER`
- `WORDPRESS_ADMIN_PASSWORD`
- `WORDPRESS_TITLE`

### NGINX SSL Generation (`generate_ssl.sh`)

1. Creates /etc/nginx/ssl directory
2. Generates self-signed certificate if missing
3. Tests NGINX configuration
4. Starts NGINX daemon

**Certificate details:**
- Type: Self-signed
- Validity: 365 days
- Algorithm: RSA 2048-bit
- Location: `/etc/nginx/ssl/nginx.{crt,key}`

## Development Workflow

### Making Code Changes

**Dockerfile changes:**
```bash
# Rebuild affected service
docker compose -f srcs/docker-compose.yml build --no-cache mariadb
docker compose -f srcs/docker-compose.yml up -d mariadb
```

**Configuration changes (.env):**
```bash
# Restart affected services
docker compose -f srcs/docker-compose.yml restart wordpress
```

**Script changes (init_db.sh, setup_wordpress.sh):**
```bash
# Rebuild and restart
make fclean
make
```

### Testing Changes

```bash
# Test database connection
docker exec wordpress mysql -h mariadb -u wordpress_user -p$(cat secrets/db_password.txt) -e "SELECT VERSION();"

# Test NGINX config
docker exec nginx nginx -t

# Test PHP
docker exec wordpress php -v
```

## Troubleshooting

### Containers Won't Start

```bash
# Check logs
make logs

# Remove containers and rebuild
docker compose -f srcs/docker-compose.yml down
docker compose -f srcs/docker-compose.yml build --no-cache
docker compose -f srcs/docker-compose.yml up -d
```

### Port Already in Use

```bash
# Check what's using port 443
sudo lsof -i :443

# Kill conflicting process
sudo kill -9 <PID>
```

### Database Connection Timeout

```bash
# Check MariaDB status
docker compose -f srcs/docker-compose.yml logs mariadb

# Wait longer for initialization
sleep 60
docker compose -f srcs/docker-compose.yml ps
```

### File Permissions Issues

```bash
# Fix data directory permissions
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data
chmod -R u+rw /home/$(whoami)/data
```

### SSL Certificate Issues

```bash
# Regenerate certificates
docker compose -f srcs/docker-compose.yml exec nginx \
  rm /etc/nginx/ssl/nginx.crt /etc/nginx/ssl/nginx.key
docker compose -f srcs/docker-compose.yml restart nginx
```

## Makefile Targets

```bash
make              # Build and start (default: all)
make build        # Build images only
make up           # Start services
make down         # Stop services (keep volumes)
make down-v       # Stop and remove volumes
make ps           # View running containers
make logs         # Follow logs
make clean        # Clean up images
make fclean       # Full clean (remove all data)
make re           # Rebuild from scratch
```

## Requirements Checklist

- ✅ NGINX with TLSv1.2/1.3 only
- ✅ WordPress + PHP-FPM (no NGINX)
- ✅ MariaDB (no NGINX)
- ✅ Two volumes (database + files)
- ✅ Custom Docker network
- ✅ Containers restart on crash
- ✅ Environment variables in .env
- ✅ Secrets for sensitive data
- ✅ No hardcoded passwords
- ✅ No latest tags
- ✅ Custom Dockerfiles (no image pulls)
- ✅ Makefile builds and orchestrates
- ✅ Two database users

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Spec](https://github.com/compose-spec/compose-spec)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [WordPress Development](https://developer.wordpress.org/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

## Getting Help

- Check logs: `make logs`
- View container status: `make ps`
- Inspect volumes: `docker volume inspect <name>`
- Test connectivity: `docker network inspect inception-network`

# Inception

*This activity has been created as part of the 42 curriculum by borabi.*

## Description

Inception is a Docker-based infrastructure project that sets up a complete WordPress environment with NGINX, MariaDB, and PHP-FPM running in isolated containers. This project teaches system administration concepts including containerization, networking, persistence, and infrastructure-as-code principles.

The infrastructure comprises:
- **NGINX**: Reverse proxy and web server with TLS/SSL encryption
- **WordPress + PHP-FPM**: Application server for WordPress content management
- **MariaDB**: Database backend for WordPress data persistence
- **Docker Network**: Custom bridge network enabling secure inter-container communication
- **Docker Volumes**: Named volumes for database and website file persistence

## Instructions

### Prerequisites
- Docker and Docker Compose installed
- A virtual machine or Linux environment
- `make` utility
- sudo privileges (for volume cleanup)

### Setup

1. **Clone/navigate to the project directory**
   ```bash
   cd 42_inception
   ```

2. **Configure your domain (hosts file)**
   Add the following line to `/etc/hosts`:
   ```
   127.0.0.1 borabi.42.fr
   ```

3. **Build and start services**
   ```bash
   make
   ```
   This will:
   - Create necessary data directories
   - Build Docker images
   - Start all containers

### Common Commands

```bash
make up           # Start services (if already built)
make down         # Stop services (keep volumes)
make down-v       # Stop and remove volumes
make ps           # View running containers
make logs         # Follow container logs
make clean        # Clean up images and containers
make fclean       # Full clean (remove all data)
make re           # Rebuild from scratch
```

### Access

- **Website**: https://borabi.42.fr
- **WordPress Admin**: https://borabi.42.fr/wp-admin
- **Default Admin**: Check `secrets/credentials.txt`

## Resources

### Docker Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

### WordPress & PHP
- [WordPress Official Documentation](https://wordpress.org/documentation/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB Official Documentation](https://mariadb.com/docs/)

### System Administration
- [NGINX Documentation](https://nginx.org/en/docs/)
- [TLS/SSL Certificates](https://www.ssl.com/article/how-ssl-certificates-work/)
- [Docker Networking](https://docs.docker.com/network/)

### AI Usage

AI was used in this project for:
- **Documentation**: README and technical documentation drafting
- **Debugging**: Troubleshooting Docker networking and volume mount issues
- **Configuration**: NGINX configuration templates and PHP-FPM pool configuration

All AI-generated content was reviewed, tested, and modified to ensure correctness and compliance with project requirements.

## Project Description

### Docker Architecture Overview

This project demonstrates core Docker concepts through a three-tier architecture:

1. **Frontend Layer**: NGINX container handling HTTP/HTTPS traffic
2. **Application Layer**: WordPress + PHP-FPM processing dynamic content
3. **Data Layer**: MariaDB storing application data

All containers communicate via a custom Docker bridge network, ensuring isolation and security.

### Design Choices & Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Overhead** | High (full OS per VM) | Low (shared kernel) |
| **Boot Time** | Minutes | Seconds |
| **Resource Use** | 500MB-2GB+ per VM | 10-100MB per container |
| **Portability** | Moderate (VM format dependent) | Excellent (container = image) |
| **Use Case** | Heavy isolation, legacy apps | Microservices, cloud-native |

**Choice**: Docker chosen for efficiency and modern infrastructure practices.

#### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|--------|----------------------|-----------------|
| **Visibility** | Accessible to processes, visible in `ps` | Only mounted, not in env |
| **Security** | Lower (process inspection) | Higher (file-based, not exposed) |
| **Persistence** | Ephemeral | Persisted in compose |
| **Use Case** | Non-sensitive config (domain, user IDs) | Sensitive data (passwords, keys) |

**Choice**: Secrets for passwords/credentials, environment variables for configuration.

#### Docker Network vs Host Network

| Aspect | Docker Network | Host Network |
|--------|---------------|--------------|
| **Isolation** | Full (containers isolated) | None (containers share host stack) |
| **Performance** | Slight overhead | Minimal overhead |
| **Security** | High (network namespace) | Lower (exposed to host) |
| **Service Discovery** | Built-in DNS (service name) | Localhost only |
| **Port Conflicts** | Managed per container | Can conflict with host |

**Choice**: Custom bridge network for security, DNS resolution, and proper isolation.

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|----------------|------------|
| **Management** | Docker-managed | Host filesystem path |
| **Portability** | High (OS-independent) | Lower (path-dependent) |
| **Performance** | Optimized | Good |
| **Persistence** | Managed by Docker | Manual management |
| **Use Case** | Stateful apps, databases | Development, source code |

**Choice**: Named volumes for database and website files (production-grade, managed persistence).

### Security Considerations

- **TLS/SSL**: Self-signed certificates generated at startup, TLSv1.2+ enforced
- **Network Isolation**: Only NGINX exposed via port 443; other services isolated
- **Secrets Management**: Passwords stored in Docker Secrets, not environment variables
- **Image Security**: No latest tags, specific versions pinned
- **Database**: Separate admin and application users with limited privileges

### Data Persistence

- **Database**: `mariadb_data` volume → `/home/<user>/data/mariadb`
- **Website Files**: `wordpress_data` volume → `/home/<user>/data/wordpress`
- **Automatic Startup**: Containers restart on failure via `restart: always`

### Troubleshooting

If services fail to start:
```bash
# Check logs
make logs

# View running containers
make ps

# Rebuild from scratch
make fclean
make
```

For certificate issues:
```bash
# Regenerate certificates
docker compose -f srcs/docker-compose.yml exec nginx rm /etc/nginx/ssl/*.crt
docker compose -f srcs/docker-compose.yml restart nginx
```

# Infrastructure Directory

This directory contains all production and development infrastructure configurations for the blog-nest monorepo.

## Files

### `Dockerfile`
Multi-stage Docker build configuration for backend (NestJS) and frontend (Next.js).
- **Base Image**: `node:24-alpine`
- **Stages**: backend-build → backend-prod, frontend-build → frontend-prod

**Build from root:**
```bash
docker build -f infra/Dockerfile -t blog-nest:latest .
```

### `docker-compose.prod.yml`
Production Docker Compose orchestration with PostgreSQL, Redis, Nginx, and both services.

**Usage:**
```bash
cd deploy
docker compose -f docker-compose.prod.yml up -d
```

**Or from root:**
```bash
docker compose -f deploy/docker-compose.prod.yml up -d
```

### `docker-compose.yml`
Development Docker Compose setup with hot-reload volumes and exposed ports.

**Usage:**
```bash
cd deploy
docker compose up -d
```

### `nginx.conf`
Nginx reverse proxy configuration with:
- SSL/TLS support (Let's Encrypt ready)
- Rate limiting (API: 100r/s, Web: 50r/s)
- Gzip compression
- Security headers
- Caching strategies
- Health check endpoint

## Quick Start (VPS)

### 1. Copy files to VPS
```bash
scp -r infra/ user@vps:/home/deploy/blog-nest/
```

### 2. Create environment file
```bash
# On VPS, in /home/deploy/blog-nest/infra/
cp .env.example .env
# Edit .env with your values
```

### 3. Setup SSL certificates
```bash
# From infra directory
mkdir -p ssl

# If using Let's Encrypt (run once)
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com

# Copy certs
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./ssl/key.pem
sudo chown deploy:deploy ./ssl/*
sudo chmod 600 ./ssl/key.pem
```

### 4. Start services
```bash
cd /home/deploy/blog-nest/infra
docker compose -f docker-compose.prod.yml up -d
```

### 5. Verify health
```bash
docker compose -f docker-compose.prod.yml ps
curl http://localhost/health
```

## Environment Variables

Create `.env` file in this directory:

```env
# Database
DB_USER=blog_user
DB_PASSWORD=your_secure_password_here
DB_NAME=blog_production

# Redis
REDIS_PASSWORD=your_redis_secure_password_here

# Frontend
NEXT_PUBLIC_API_URL=https://yourdomain.com/api

# Logging
LOG_LEVEL=info
```

## Production Checklist

- [ ] Ubuntu 24.04 LTS VPS deployed
- [ ] Docker & Docker Compose installed
- [ ] SSL certificates obtained (Let's Encrypt)
- [ ] `.env` file created with strong passwords
- [ ] Nginx config updated with your domain
- [ ] Database backups configured
- [ ] Firewall rules set (UFW)
- [ ] SSH hardened
- [ ] Services running and healthy
- [ ] DNS pointing to VPS IP
- [ ] Monitoring setup (optional)

## Common Commands

```bash
# View logs
docker compose -f docker-compose.prod.yml logs -f

# Restart services
docker compose -f docker-compose.prod.yml restart

# Stop all
docker compose -f docker-compose.prod.yml down

# Database backup
docker compose -f docker-compose.prod.yml exec postgres \
  pg_dump -U blog_user blog_production | gzip > backup.sql.gz

# SSH into container
docker compose -f docker-compose.prod.yml exec api sh
```

## See Also

- [../DEPLOY_VPS.md](../DEPLOY_VPS.md) — Complete VPS deployment guide

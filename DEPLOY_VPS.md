# VPS Deployment Guide - blog-nest Monorepo

**Node Version**: 24.x (see `.nvmrc`)  
**Docker Command**: `docker compose` (not `docker-compose`)

---

## Prerequisites

### On Your VPS (Ubuntu 24.04 LTS)

1. **Install Docker & Docker Compose**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Add your user to docker group
   sudo usermod -aG docker $USER
   newgrp docker

   # Verify Docker version (should be 20.10+)
   docker --version
   docker compose version
   ```

2. **Install Certbot (for HTTPS/SSL)**
   ```bash
   sudo apt-get update
   sudo apt-get install -y certbot
   ```

3. **Install fail2ban (security)**
   ```bash
   sudo apt-get install -y fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

4. **Create deploy user**
   ```bash
   sudo useradd -m -s /bin/bash deploy
   sudo usermod -aG docker deploy
   ```

---

## Setup Steps

### 1. Clone Repository

```bash
sudo -u deploy bash << 'EOF'
cd /home/deploy
git clone https://github.com/YOUR_USERNAME/blog-nest.git
cd blog-nest
EOF
```

All deployment files are in the `infra/` subdirectory.

### 2. Create Environment Files

```bash
# Create .env in infra directory
sudo tee /home/deploy/blog-nest/infra/.env > /dev/null << 'EOF'
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
EOF

# Restrict permissions
sudo chmod 600 /home/deploy/blog-nest/infra/.env
sudo chown deploy:deploy /home/deploy/blog-nest/infra/.env
```

### 3. Generate SSL Certificates

```bash
# Using Let's Encrypt
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email

# Copy to infra directory
sudo mkdir -p /home/deploy/blog-nest/infra/ssl
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /home/deploy/blog-nest/infra/ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /home/deploy/blog-nest/infra/ssl/key.pem
sudo chown -R deploy:deploy /home/deploy/blog-nest/infra/ssl
sudo chmod 600 /home/deploy/blog-nest/infra/ssl/key.pem
```

### 4. Update Nginx Configuration

Edit `/home/deploy/blog-nest/infra/nginx.conf`:

```bash
# Update the server_name and SSL paths
sed -i 's/server_name _/server_name yourdomain.com www.yourdomain.com/' /home/deploy/blog-nest/infra/nginx.conf
```

### 5. Build and Start Services

```bash
cd /home/deploy/blog-nest/infra

# Build images
docker compose -f docker-compose.prod.yml build

# Start services
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps
```

### 6. Setup SSL Auto-Renewal

```bash
# Create renewal hook
sudo tee /etc/letsencrypt/renewal-hooks/post/docker-restart.sh > /dev/null << 'EOF'
#!/bin/bash
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /home/deploy/blog-nest/deploy/ssl/cert.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /home/deploy/blog-nest/deploy/ssl/key.pem
chown deploy:deploy /home/deploy/blog-nest/deploy/ssl/*
cd /home/deploy/blog-nest/deploy
docker compose -f docker-compose.prod.yml restart nginx
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/post/docker-restart.sh

# Test renewal
sudo certbot renew --dry-run
```

### 7. Setup Systemd Service (Optional but Recommended)

```bash
sudo tee /etc/systemd/system/blog-nest.service > /dev/null << 'EOF'
[Unit]
Description=blog-nest Docker Compose
After=docker.service
Requires=docker.service

[Service]
Type=forking
User=deploy
WorkingDirectory=/home/deploy/blog-nest/infra
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable blog-nest
sudo systemctl start blog-nest
```

---

## Deployment Workflow

### Initial Deploy
```bash
cd /home/deploy/blog-nest/infra
git pull origin main
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f
```

### Deploy Updates
```bash
cd /home/deploy/blog-nest/infra
git pull origin main
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d api frontend
docker compose -f docker-compose.prod.yml logs -f
```

### Check Health
```bash
cd /home/deploy/blog-nest/infra

# Service status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs api
docker compose -f docker-compose.prod.yml logs frontend
docker compose -f docker-compose.prod.yml logs nginx

# Check database connection
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U blog_user -d blog_production -c "SELECT 1;"

# Check Redis connection
docker compose -f docker-compose.prod.yml exec redis \
  redis-cli -a $REDIS_PASSWORD ping
```

---

## Monitoring & Maintenance

### Logs Rotation
```bash
# Docker logs are auto-rotated; configure in docker-compose.prod.yml if needed
docker compose -f docker-compose.prod.yml restart
```

### Database Backups

```bash
# Daily backup script
sudo tee /usr/local/bin/backup-blog-db.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups/blog-nest"
mkdir -p $BACKUP_DIR

docker compose -f /home/deploy/blog-nest/infra/docker-compose.prod.yml exec -T postgres \
  pg_dump -U blog_user blog_production | gzip > "$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"

# Keep only last 7 days
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete
EOF

sudo chmod +x /usr/local/bin/backup-blog-db.sh

# Add to crontab
sudo tee /etc/cron.d/blog-backup > /dev/null << 'EOF'
0 2 * * * root /usr/local/bin/backup-blog-db.sh
EOF
```

### Monitor Resource Usage
```bash
# Real-time stats
docker stats

# Check disk usage
docker system df

# Prune unused images/volumes
docker system prune -a --volumes
```

### Update Node Version

If you need to update Node (e.g., from 24 to 25):

1. Update `.nvmrc`:
   ```bash
   echo "25" > .nvmrc
   ```

2. Update `infra/Dockerfile`:
   ```bash
   sed -i 's/node:24-alpine/node:25-alpine/g' infra/Dockerfile
   ```

3. Rebuild and deploy:
   ```bash
   cd infra
   docker compose -f docker-compose.prod.yml build --no-cache
   docker compose -f docker-compose.prod.yml up -d
   ```

---

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose -f docker-compose.prod.yml logs

# Check if ports are in use
sudo netstat -ltnp | grep -E ':(80|443|3000|3001|5432|6379)'

# Kill conflicting processes
sudo lsof -i :80
sudo kill -9 <PID>
```

### Database connection fails
```bash
# Check database is running
docker compose -f docker-compose.prod.yml ps postgres

# Check DATABASE_URL in .env
cat /home/deploy/blog-nest/deploy/.env | grep DATABASE_URL

# Test connection
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U blog_user -d blog_production -c "\conninfo"
```

### High memory usage
```bash
# Check which container
docker stats

# Reduce Node memory (in docker-compose.prod.yml):
# Add: environment: NODE_OPTIONS=--max-old-space-size=1024

# Restart container
docker compose -f docker-compose.prod.yml restart api
```

### SSL certificate issues
```bash
# Check cert status
sudo certbot certificates

# Manually renew
sudo certbot renew --force-renewal --quiet

# Check expiration
openssl s_client -connect yourdomain.com:443 < /dev/null | grep -A1 "Validity"
```

---

## Security Best Practices

1. **SSH Hardening**
   ```bash
   # Edit /etc/ssh/sshd_config
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   Port 2222  # Change default port
   ```

2. **Firewall Rules** (UFW)
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw enable
   ```

3. **Regular Updates**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   sudo apt-get autoremove -y
   ```

4. **Secrets Management**
   - Never commit `.env` to git
   - Use strong passwords (20+ chars, mixed case, symbols)
   - Rotate passwords quarterly
   - Store backups in secure, offsite location

---

## Performance Tuning

### Nginx Caching
Already configured in `deploy/nginx.conf`:
- Static assets cached for 1 year
- API responses cached for 5 minutes
- Rate limiting: 100r/s for API, 50r/s for web

### Database Optimization
```bash
# Connect to database
docker compose -f docker-compose.prod.yml exec postgres psql -U blog_user -d blog_production

# Analyze query performance
EXPLAIN ANALYZE SELECT * FROM users;

# Create indexes if needed
CREATE INDEX idx_users_email ON users(email);
```

### Redis Optimization
```bash
# Monitor Redis
docker compose -f docker-compose.prod.yml exec redis redis-cli MONITOR

# Check memory usage
docker compose -f docker-compose.prod.yml exec redis redis-cli INFO memory
```

---

## Rollback Strategy

### Quick Rollback
```bash
cd /home/deploy/blog-nest/deploy

# Revert code
git revert <commit-hash>

# Rebuild and redeploy
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### Database Rollback
```bash
# Restore from backup
gunzip < /backups/blog-nest/db_20260306_120000.sql.gz | \
  docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U blog_user blog_production
```

---

## Useful Commands

```bash
# Enter service shell
docker compose -f docker-compose.prod.yml exec api sh
docker compose -f docker-compose.prod.yml exec frontend sh

# Run migrations (if using Prisma)
docker compose -f docker-compose.prod.yml exec api \
  npx prisma migrate deploy

# Access database directly
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U blog_user -d blog_production

# Check API health
curl https://yourdomain.com/api/health

# View real-time logs
docker compose -f docker-compose.prod.yml logs -f --tail=50
```

---

## Additional Resources

- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Nginx Reverse Proxy](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [UFW Firewall](https://help.ubuntu.com/community/UFW)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/nodejs-performance/)

---

**Last Updated**: Thursday, March 6, 2026

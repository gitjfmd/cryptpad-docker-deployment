# CryptPad Docker Deployment with Nginx Proxy Manager

A complete production-ready deployment guide for CryptPad using Docker Swarm, Portainer, and Nginx Proxy Manager with Cloudflare tunnel integration.

## 🚀 Features

- **Zero-Knowledge Encryption**: End-to-end encrypted collaborative documents
- **Production Ready**: Docker Swarm deployment with health checks and auto-restart
- **Secure Sandbox**: Proper domain isolation for security
- **SSL/HTTPS**: Automatic SSL certificates via Nginx Proxy Manager
- **Cloudflare Integration**: Works with Cloudflare tunnels
- **Monitoring**: Built-in health checks and logging
- **Scalable**: Easy to scale and maintain

## 📋 Prerequisites

- Docker Swarm cluster
- Portainer for container management
- Nginx Proxy Manager (NPM) or similar reverse proxy
- Two domains/subdomains:
  - Main domain: `cryptpad.yourdomain.com`
  - Sandbox domain: `cryptpad-sandbox.yourdomain.com`
- Cloudflare tunnel (optional but recommended)

## 🏗️ Architecture

```
Internet → Cloudflare → Nginx Proxy Manager → CryptPad Container
                                          ↗ Main Domain (cryptpad.yourdomain.com)
                                          ↘ Sandbox Domain (cryptpad-sandbox.yourdomain.com)
```

## 📁 Repository Structure

```
cryptpad-docker-deployment/
├── README.md                          # This file
├── ADVANCED.md                        # Advanced configuration guide
├── TROUBLESHOOTING.md                 # Troubleshooting guide
├── docker/
│   ├── docker-compose.yml             # Main Docker Compose file
│   └── docker-compose-nginx-ui.yml    # Alternative for nginx UI integration
├── config/
│   ├── cryptpad-config.js             # CryptPad configuration template
│   └── cryptpad-config-optimized.js   # Optimized production config
├── nginx/
│   ├── npm-config.md                  # Nginx Proxy Manager setup
│   └── nginx-headers.conf             # Required nginx headers
├── scripts/
│   ├── deploy.sh                      # Automated deployment script
│   ├── setup-directories.sh           # Directory setup script
│   └── health-check.sh                # Health check script
└── docs/
    ├── SECURITY.md                    # Security considerations
    ├── BACKUP.md                      # Backup and recovery
    └── MONITORING.md                  # Monitoring and maintenance
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/cryptpad-docker-deployment.git
cd cryptpad-docker-deployment
```

### 2. Configure Domains

Edit the configuration files and replace placeholders:
- `cryptpad.yourdomain.com` → Your main domain
- `cryptpad-sandbox.yourdomain.com` → Your sandbox domain
- `admin@yourdomain.com` → Your admin email

### 3. Run Setup Script

```bash
chmod +x scripts/setup-directories.sh
sudo ./scripts/setup-directories.sh
```

### 4. Deploy with Portainer

1. Copy `docker/docker-compose.yml` content
2. Create new stack in Portainer
3. Paste the configuration
4. Deploy the stack

### 5. Configure Nginx Proxy Manager

Follow the instructions in `nginx/npm-config.md` to set up your reverse proxy.

### 6. Verify Deployment

```bash
# Check if CryptPad is responding
curl -v https://cryptpad.yourdomain.com/api/config

# Run health check
./scripts/health-check.sh
```

## 📖 Detailed Setup Guide

### Step 1: Domain Configuration

You need two domains pointing to your server:
- **Main Domain**: `cryptpad.yourdomain.com` - For the main interface
- **Sandbox Domain**: `cryptpad-sandbox.yourdomain.com` - For secure content isolation

Both domains should point to your Nginx Proxy Manager instance.

### Step 2: Directory Structure Setup

```bash
# Create required directories
sudo mkdir -p /var/lib/cryptpad/{config,data,blob,block,datastore,customize}
sudo mkdir -p /var/lib/cryptpad/data/logs

# Set proper permissions
sudo chown -R 4001:4001 /var/lib/cryptpad/
sudo chmod -R 755 /var/lib/cryptpad/
```

### Step 3: Configuration Files

Copy and customize the configuration:

```bash
# Copy CryptPad config
sudo cp config/cryptpad-config.js /var/lib/cryptpad/config/config.js

# Edit with your domains
sudo nano /var/lib/cryptpad/config/config.js
```

Replace these placeholders:
- `cryptpad.yourdomain.com` → Your actual main domain
- `cryptpad-sandbox.yourdomain.com` → Your actual sandbox domain
- `admin@yourdomain.com` → Your admin email

### Step 4: Docker Deployment

#### Option A: Using Portainer (Recommended)

1. Open Portainer web interface
2. Go to "Stacks" → "Add Stack"
3. Name: `cryptpad-stack`
4. Copy content from `docker/docker-compose.yml`
5. Replace domain placeholders with your actual domains
6. Deploy the stack

#### Option B: Command Line

```bash
# Initialize Docker Swarm (if not already done)
docker swarm init

# Deploy the stack
docker stack deploy -c docker/docker-compose.yml cryptpad-stack
```

### Step 5: Nginx Proxy Manager Setup

1. **Create Proxy Host for Main Domain**:
   - Domain: `cryptpad.yourdomain.com`
   - Forward to: `cryptpad:3000`
   - SSL: Enable with Let's Encrypt
   - Advanced: Add configuration from `nginx/nginx-headers.conf`

2. **Create Proxy Host for Sandbox Domain**:
   - Domain: `cryptpad-sandbox.yourdomain.com`
   - Forward to: `cryptpad:3000` (same container)
   - SSL: Enable with Let's Encrypt
   - Advanced: Add sandbox-specific configuration

See `nginx/npm-config.md` for detailed instructions.

### Step 6: Admin Setup

1. **Register Admin Account**:
   - Go to `https://cryptpad.yourdomain.com`
   - Register a new account
   - Go to Settings → Account
   - Copy your Public Signing Key

2. **Add Admin Key to Config**:
   ```bash
   sudo nano /var/lib/cryptpad/config/config.js
   ```
   
   Add your key to the `adminKeys` array:
   ```javascript
   adminKeys: [
     '[admin@yourdomain.com/YourPublicSigningKeyHere]'
   ],
   ```

3. **Restart CryptPad**:
   ```bash
   docker service update --force cryptpad-stack_cryptpad
   ```

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CPAD_MAIN_DOMAIN` | Main domain URL | `https://cryptpad.yourdomain.com` |
| `CPAD_SANDBOX_DOMAIN` | Sandbox domain URL | `https://cryptpad-sandbox.yourdomain.com` |
| `CPAD_HTTP_PORT` | Internal HTTP port | `3000` |
| `NODE_ENV` | Node environment | `production` |

### Resource Limits

Default resource allocation:
- **Memory**: 2GB limit, 1GB reserved
- **CPU**: 1.0 limit, 0.5 reserved

Adjust in `docker-compose.yml` based on your needs.

## 🔍 Verification

### Health Checks

```bash
# Check container status
docker service ls --filter name=cryptpad

# Check logs
docker service logs cryptpad-stack_cryptpad --tail 50

# Test API endpoint
curl -v https://cryptpad.yourdomain.com/api/config

# Run comprehensive health check
./scripts/health-check.sh
```

### CryptPad Checkup

Visit `https://cryptpad.yourdomain.com/checkup/` to run CryptPad's built-in diagnostics.

Expected results:
- ✅ 46+ tests passing initially
- ✅ 50+ tests passing after admin setup

## 🛡️ Security Considerations

- **Sandbox Isolation**: Ensures user content cannot access main application
- **HTTPS Only**: All traffic encrypted with SSL/TLS
- **HSTS Headers**: Prevents downgrade attacks
- **CSP Headers**: Content Security Policy protection
- **Rate Limiting**: Prevents abuse and DoS attacks

See `docs/SECURITY.md` for detailed security information.

## 📊 Monitoring

### Built-in Monitoring

- Docker health checks every 30 seconds
- Application logs in `/var/lib/cryptpad/data/logs`
- Nginx access logs via NPM

### External Monitoring

Consider adding:
- Uptime monitoring (UptimeRobot, Pingdom)
- Log aggregation (ELK stack, Grafana)
- Performance monitoring (New Relic, DataDog)

See `docs/MONITORING.md` for setup instructions.

## 💾 Backup and Recovery

### Automated Backups

```bash
# Create backup script
sudo cp scripts/backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup.sh

# Add to crontab for daily backups
echo "0 2 * * * /usr/local/bin/backup.sh" | sudo crontab -
```

### Manual Backup

```bash
# Backup data directory
sudo tar -czf cryptpad-backup-$(date +%Y%m%d).tar.gz /var/lib/cryptpad/

# Backup database (if using external DB)
docker exec cryptpad-stack_postgres pg_dump -U cryptpad cryptpad > cryptpad-db-backup.sql
```

See `docs/BACKUP.md` for complete backup procedures.

## 🔧 Troubleshooting

### Common Issues

1. **"Unexpected Error" on Login**
   - Check domain configuration in `config.js`
   - Verify both domains are accessible
   - Check nginx proxy headers

2. **Real-time Collaboration Not Working**
   - Verify WebSocket headers in nginx
   - Check firewall settings
   - Test WebSocket connections

3. **File Upload Failures**
   - Check `client_max_body_size` in nginx
   - Verify disk space
   - Check file permissions

See `TROUBLESHOOTING.md` for complete troubleshooting guide.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [CryptPad Team](https://cryptpad.fr/) for the amazing software
- [Nginx Proxy Manager](https://nginxproxymanager.com/) for easy reverse proxy management
- [Portainer](https://www.portainer.io/) for container management

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/cryptpad-docker-deployment/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/cryptpad-docker-deployment/discussions)
- **CryptPad Docs**: [Official Documentation](https://docs.cryptpad.fr/)

## 🔄 Updates

This deployment is tested with:
- **CryptPad**: 2025.6.0
- **Docker**: 20.10+
- **Docker Compose**: 3.8+
- **Nginx Proxy Manager**: 2.10+

Check for updates regularly and follow the upgrade procedures in `docs/UPGRADES.md`.

---

**⭐ If this helped you deploy CryptPad successfully, please star the repository!**


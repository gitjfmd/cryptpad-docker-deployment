# CryptPad Troubleshooting Guide

This guide covers common issues and their solutions when deploying CryptPad with Docker and Nginx Proxy Manager.

## 🚨 Common Issues

### 1. "An unexpected error occurred :(" Message

**Symptoms:**
- CryptPad loads but shows error message when trying to use
- Cannot create or edit documents
- Login/registration fails

**Causes:**
- Domain configuration mismatch
- Missing or incorrect proxy headers
- CORS issues

**Solutions:**

#### Check Domain Configuration
```bash
# Verify config.js domains match your actual domains
sudo cat /var/lib/cryptpad/config/config.js | grep -E "(mainDomain|sandboxDomain|httpUnsafeOrigin)"

# Should show:
# httpUnsafeOrigin: 'https://cryptpad.yourdomain.com',
# mainDomain: 'https://cryptpad.yourdomain.com',
# sandboxDomain: 'https://cryptpad-sandbox.yourdomain.com',
```

#### Fix Domain Mismatch
```bash
# Edit config with correct domains
sudo nano /var/lib/cryptpad/config/config.js

# Update these lines:
# httpUnsafeOrigin: 'https://your-actual-domain.com',
# mainDomain: 'https://your-actual-domain.com',
# sandboxDomain: 'https://your-actual-sandbox-domain.com',

# Restart CryptPad
docker service update --force cryptpad-stack_cryptpad
```

#### Verify Proxy Headers
Check that your Nginx Proxy Manager has these headers in the Advanced tab:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
```

### 2. Real-time Collaboration Not Working

**Symptoms:**
- Documents load but changes don't sync between users
- Cursor positions not visible
- Chat not working

**Causes:**
- WebSocket connection failures
- Missing WebSocket headers in proxy
- Firewall blocking WebSocket connections

**Solutions:**

#### Check WebSocket Headers
Ensure your Nginx Proxy Manager has:
```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
```

#### Test WebSocket Connection
```bash
# Test WebSocket upgrade headers
curl -H "Upgrade: websocket" -H "Connection: upgrade" -v https://cryptpad.yourdomain.com/

# Should return 101 Switching Protocols or similar
```

#### Enable WebSocket Support in NPM
1. Edit your proxy host in NPM
2. Go to Details tab
3. Enable "Websockets Support"
4. Save configuration

### 3. File Upload Failures

**Symptoms:**
- Cannot upload files to CryptPad
- Upload progress stops at certain percentage
- "File too large" errors

**Causes:**
- Nginx file size limits
- CryptPad file size limits
- Insufficient disk space

**Solutions:**

#### Increase Nginx File Size Limit
Add to NPM Advanced configuration:
```nginx
client_max_body_size 50M;  # Adjust as needed
```

#### Check CryptPad Limits
```bash
# Check current limits in config
sudo grep -E "(maxUploadSize|defaultStorageLimit)" /var/lib/cryptpad/config/config.js
```

#### Increase CryptPad Limits
```bash
sudo nano /var/lib/cryptpad/config/config.js

# Update these values:
maxUploadSize: 50 * 1024 * 1024, // 50MB
defaultStorageLimit: 100 * 1024 * 1024, // 100MB per user
```

### 4. Container Won't Start

**Symptoms:**
- Docker service shows as failed
- Container exits immediately
- No response from CryptPad

**Causes:**
- Configuration file syntax errors
- Permission issues
- Port conflicts
- Missing directories

**Solutions:**

#### Check Container Logs
```bash
# View recent logs
docker service logs cryptpad-stack_cryptpad --tail 50

# Follow logs in real-time
docker service logs cryptpad-stack_cryptpad --follow
```

#### Verify Configuration Syntax
```bash
# Test config.js syntax
node -c /var/lib/cryptpad/config/config.js

# Should return nothing if syntax is correct
```

#### Check File Permissions
```bash
# Fix permissions
sudo chown -R 4001:4001 /var/lib/cryptpad/
sudo chmod -R 755 /var/lib/cryptpad/
sudo chmod 644 /var/lib/cryptpad/config/config.js
```

#### Verify Directory Structure
```bash
# Check if all directories exist
ls -la /var/lib/cryptpad/
# Should show: blob, block, config, customize, data, datastore

# Create missing directories
sudo mkdir -p /var/lib/cryptpad/{blob,block,config,customize,data,datastore}
```

### 5. Sandbox Domain Issues

**Symptoms:**
- Main domain works but sandbox doesn't
- Security warnings in browser console
- Documents don't load properly

**Causes:**
- Sandbox domain not configured in proxy
- DNS issues with sandbox domain
- SSL certificate issues

**Solutions:**

#### Verify Sandbox Domain DNS
```bash
# Test DNS resolution
nslookup cryptpad-sandbox.yourdomain.com

# Test HTTP connectivity
curl -I https://cryptpad-sandbox.yourdomain.com/
```

#### Check NPM Configuration
1. Ensure you have TWO proxy hosts in NPM:
   - cryptpad.yourdomain.com
   - cryptpad-sandbox.yourdomain.com
2. Both should point to the same container (cryptpad:3000)
3. Both should have SSL certificates

#### Verify Sandbox in Browser
1. Open browser dev tools (F12)
2. Go to Console tab
3. Run: `Array.from(document.querySelectorAll('iframe')).map(f => f.src)`
4. Should see URLs with your sandbox domain

### 6. SSL/HTTPS Issues

**Symptoms:**
- "Not secure" warnings in browser
- SSL certificate errors
- Mixed content warnings

**Causes:**
- Let's Encrypt certificate issues
- Domain verification failures
- Cloudflare SSL conflicts

**Solutions:**

#### Check SSL Certificate Status
```bash
# Test SSL certificate
openssl s_client -connect cryptpad.yourdomain.com:443 -servername cryptpad.yourdomain.com

# Check certificate expiration
echo | openssl s_client -connect cryptpad.yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

#### Regenerate SSL Certificates
1. In NPM, edit your proxy host
2. Go to SSL tab
3. Delete existing certificate
4. Request new SSL certificate
5. Ensure domain is accessible from internet

#### Fix Cloudflare SSL Issues
If using Cloudflare:
1. Set SSL mode to "Full (strict)" in Cloudflare
2. Ensure origin certificates are valid
3. Check Cloudflare SSL/TLS settings

### 7. Performance Issues

**Symptoms:**
- Slow loading times
- Timeouts during operations
- High CPU/memory usage

**Causes:**
- Insufficient resources
- Network latency
- Database performance issues

**Solutions:**

#### Check Resource Usage
```bash
# Check container resource usage
docker stats cryptpad-stack_cryptpad

# Check system resources
htop
df -h
```

#### Increase Container Resources
Edit docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      memory: 4G      # Increase from 2G
      cpus: '2.0'     # Increase from 1.0
    reservations:
      memory: 2G      # Increase from 1G
      cpus: '1.0'     # Increase from 0.5
```

#### Optimize Configuration
```bash
sudo nano /var/lib/cryptpad/config/config.js

# Increase worker count
maxWorkers: 8,  // Increase based on CPU cores

# Adjust timeouts
channelExpirationMs: 60000,  // Increase from 30000
```

## 🔍 Diagnostic Commands

### Container Status
```bash
# List all services
docker service ls

# Check specific service
docker service ps cryptpad-stack_cryptpad

# View service details
docker service inspect cryptpad-stack_cryptpad
```

### Network Connectivity
```bash
# Test internal connectivity
docker exec $(docker ps -q -f name=cryptpad) curl -f http://localhost:3000/api/config

# Test external connectivity
curl -v https://cryptpad.yourdomain.com/api/config
curl -v https://cryptpad-sandbox.yourdomain.com/

# Test with specific headers
curl -H "Host: cryptpad.yourdomain.com" -v https://cryptpad.yourdomain.com/api/config
```

### Configuration Verification
```bash
# Check config syntax
node -c /var/lib/cryptpad/config/config.js

# View current configuration
sudo cat /var/lib/cryptpad/config/config.js | grep -E "(Domain|Origin|Email)"

# Check file permissions
ls -la /var/lib/cryptpad/config/config.js
```

### Log Analysis
```bash
# Container logs
docker service logs cryptpad-stack_cryptpad --tail 100

# System logs
sudo journalctl -u docker.service --tail 50

# Nginx logs (if using NPM)
docker logs nginx-proxy-manager --tail 50
```

## 🛠️ Advanced Troubleshooting

### Debug Mode
Enable verbose logging:
```bash
sudo nano /var/lib/cryptpad/config/config.js

# Add these lines:
logLevel: 'verbose',
verbose: true,
logToStdout: true,

# Restart container
docker service update --force cryptpad-stack_cryptpad
```

### Network Debugging
```bash
# Check Docker networks
docker network ls
docker network inspect tunnel_net

# Test container connectivity
docker exec -it $(docker ps -q -f name=cryptpad) /bin/sh
# Inside container:
curl localhost:3000/api/config
```

### Browser Debugging
1. Open browser dev tools (F12)
2. Check Console tab for JavaScript errors
3. Check Network tab for failed requests
4. Check Application tab for storage issues

### Database Issues (if using external DB)
```bash
# Check database connectivity
docker exec cryptpad-stack_postgres psql -U cryptpad -d cryptpad -c "SELECT version();"

# Check database size
docker exec cryptpad-stack_postgres psql -U cryptpad -d cryptpad -c "SELECT pg_size_pretty(pg_database_size('cryptpad'));"
```

## 📞 Getting Help

### Information to Collect
When seeking help, provide:

1. **System Information:**
   ```bash
   uname -a
   docker --version
   docker-compose --version
   ```

2. **Container Status:**
   ```bash
   docker service ls
   docker service ps cryptpad-stack_cryptpad
   ```

3. **Recent Logs:**
   ```bash
   docker service logs cryptpad-stack_cryptpad --tail 50
   ```

4. **Configuration (sanitized):**
   ```bash
   sudo cat /var/lib/cryptpad/config/config.js | grep -v -E "(adminKeys|password|secret)"
   ```

5. **Network Test Results:**
   ```bash
   curl -v https://cryptpad.yourdomain.com/api/config
   ```

### Support Channels
- **GitHub Issues**: For bugs and feature requests
- **CryptPad Forum**: For general questions
- **Docker Community**: For Docker-specific issues
- **Nginx Community**: For proxy-related issues

### Emergency Recovery
If CryptPad is completely broken:

1. **Stop the service:**
   ```bash
   docker service rm cryptpad-stack_cryptpad
   ```

2. **Backup data:**
   ```bash
   sudo tar -czf cryptpad-backup-$(date +%Y%m%d).tar.gz /var/lib/cryptpad/
   ```

3. **Reset configuration:**
   ```bash
   sudo cp /var/lib/cryptpad/config/config.js /var/lib/cryptpad/config/config.js.backup
   # Restore from known good configuration
   ```

4. **Redeploy:**
   ```bash
   docker stack deploy -c docker-compose.yml cryptpad-stack
   ```

Remember: Always backup your data before making significant changes!


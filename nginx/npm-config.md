# Nginx Proxy Manager Configuration for CryptPad

This guide shows how to configure Nginx Proxy Manager (NPM) for CryptPad with proper security headers and WebSocket support.

## 🔧 Prerequisites

- Nginx Proxy Manager installed and running
- Two domains pointing to your NPM instance:
  - `cryptpad.yourdomain.com` (main domain)
  - `cryptpad-sandbox.yourdomain.com` (sandbox domain)
- CryptPad container running and accessible on the same network

## 📋 Configuration Steps

### 1. Main Domain Configuration (cryptpad.yourdomain.com)

#### Details Tab:
- **Domain Names**: `cryptpad.yourdomain.com`
- **Scheme**: `http`
- **Forward Hostname/IP**: `cryptpad` (or your container name)
- **Forward Port**: `3000`
- **Cache Assets**: `NO`
- **Block Common Exploits**: `YES`
- **Websockets Support**: `YES`

#### SSL Tab:
- **SSL Certificate**: `Request a new SSL Certificate` (Let's Encrypt)
- **Force SSL**: `YES`
- **HTTP/2 Support**: `YES`
- **HSTS Enabled**: `YES`

#### Advanced Tab:
Copy and paste this entire configuration:

```nginx
# Essential proxy headers for CryptPad
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;

# WebSocket support (CRITICAL for CryptPad real-time features)
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;

# File upload and timeout settings
client_max_body_size 20M;
client_body_timeout 60s;
client_header_timeout 60s;
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
proxy_cache_bypass $http_upgrade;

# Buffer settings for performance
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
proxy_busy_buffers_size 8k;

# Rate limiting
limit_req_zone $binary_remote_addr zone=cryptpad_main:10m rate=10r/s;
limit_req zone=cryptpad_main burst=20 nodelay;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self'; connect-src 'self' wss: https:; media-src 'self' blob:; object-src 'none'; frame-src 'self' https:; worker-src 'self'; frame-ancestors 'self';" always;

# Static assets caching
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
}

# Connection upgrade map
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
```

### 2. Sandbox Domain Configuration (cryptpad-sandbox.yourdomain.com)

#### Details Tab:
- **Domain Names**: `cryptpad-sandbox.yourdomain.com`
- **Scheme**: `http`
- **Forward Hostname/IP**: `cryptpad` (same container as main)
- **Forward Port**: `3000`
- **Cache Assets**: `NO`
- **Block Common Exploits**: `YES`
- **Websockets Support**: `YES`

#### SSL Tab:
- **SSL Certificate**: `Request a new SSL Certificate` (Let's Encrypt)
- **Force SSL**: `YES`
- **HTTP/2 Support**: `YES`
- **HSTS Enabled**: `YES`

#### Advanced Tab:
Copy and paste this configuration (note the more permissive CSP for sandbox):

```nginx
# Essential proxy headers for CryptPad Sandbox
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;

# WebSocket support (CRITICAL for CryptPad real-time features)
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;

# File upload and timeout settings
client_max_body_size 20M;
client_body_timeout 60s;
client_header_timeout 60s;
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
proxy_cache_bypass $http_upgrade;

# Buffer settings for performance
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
proxy_busy_buffers_size 8k;

# Rate limiting (more permissive for sandbox)
limit_req_zone $binary_remote_addr zone=cryptpad_sandbox:10m rate=20r/s;
limit_req zone=cryptpad_sandbox burst=50 nodelay;

# Security headers (more permissive CSP for sandbox)
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' wss: https:; media-src 'self' blob:; object-src 'none'; frame-src 'self' https:; worker-src 'self' blob:; frame-ancestors 'self';" always;

# Connection upgrade map
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
```

## 🔍 Verification Steps

### 1. Test Basic Connectivity

```bash
# Test main domain
curl -I https://cryptpad.yourdomain.com

# Test sandbox domain
curl -I https://cryptpad-sandbox.yourdomain.com

# Test API endpoint
curl -v https://cryptpad.yourdomain.com/api/config
```

### 2. Verify Headers

Check that required headers are present:

```bash
# Check for proxy headers
curl -H "X-Forwarded-For: test" -v https://cryptpad.yourdomain.com/api/config

# Check for WebSocket support
curl -H "Upgrade: websocket" -H "Connection: upgrade" -v https://cryptpad.yourdomain.com/
```

### 3. Test WebSocket Connections

1. Open browser developer tools (F12)
2. Go to Network tab
3. Visit your CryptPad instance
4. Look for WebSocket connections (WS protocol)
5. Verify they connect successfully

## 🚨 Common Issues and Solutions

### Issue 1: 502 Bad Gateway

**Cause**: NPM cannot reach CryptPad container

**Solutions**:
- Verify container name is correct (`cryptpad` vs `cryptpad-stack_cryptpad`)
- Ensure both NPM and CryptPad are on the same Docker network
- Check if CryptPad container is running: `docker ps | grep cryptpad`

### Issue 2: WebSocket Connection Failed

**Cause**: Missing WebSocket headers

**Solutions**:
- Ensure `Websockets Support` is enabled in NPM
- Verify `proxy_set_header Upgrade` and `Connection` headers are present
- Check for conflicting nginx configurations

### Issue 3: File Upload Failures

**Cause**: File size limits

**Solutions**:
- Increase `client_max_body_size` in Advanced configuration
- Check CryptPad's `maxUploadSize` setting
- Verify disk space on server

### Issue 4: CORS Errors

**Cause**: Missing or incorrect headers

**Solutions**:
- Verify all proxy headers are configured
- Check `Access-Control-Allow-Origin` headers in CryptPad config
- Ensure domains match exactly (no trailing slashes)

## 🔧 Advanced Configuration

### Custom Rate Limiting

Adjust rate limiting based on your needs:

```nginx
# More restrictive
limit_req_zone $binary_remote_addr zone=cryptpad_strict:10m rate=5r/s;
limit_req zone=cryptpad_strict burst=10 nodelay;

# More permissive
limit_req_zone $binary_remote_addr zone=cryptpad_open:10m rate=30r/s;
limit_req zone=cryptpad_open burst=100 nodelay;
```

### IP Whitelisting

Restrict access to specific IPs:

```nginx
# Allow specific IPs only
allow 192.168.1.0/24;
allow 10.0.0.0/8;
deny all;
```

### Custom Error Pages

Add custom error pages:

```nginx
error_page 502 503 504 /maintenance.html;
location = /maintenance.html {
    root /var/www/html;
    internal;
}
```

## 📊 Monitoring

### Access Logs

NPM provides access logs for monitoring:
- Location: NPM container logs
- Format: Standard nginx access log format
- Includes: IP, timestamp, request, response code, size

### Health Monitoring

Add health check endpoint monitoring:

```nginx
location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
}
```

## 🔄 Updates and Maintenance

### Updating Configurations

1. **Backup current config**: Export NPM configuration
2. **Test changes**: Use staging environment if available
3. **Apply gradually**: Update one domain at a time
4. **Monitor**: Watch logs for errors after changes

### SSL Certificate Renewal

NPM handles Let's Encrypt renewal automatically, but monitor:
- Certificate expiration dates
- Renewal logs in NPM
- Email notifications from Let's Encrypt

## 📞 Support

If you encounter issues:

1. **Check NPM logs**: Container logs for error messages
2. **Verify DNS**: Ensure domains resolve correctly
3. **Test connectivity**: Use curl commands above
4. **Check CryptPad logs**: Container logs for application errors

For more help, see the main troubleshooting guide in the repository.


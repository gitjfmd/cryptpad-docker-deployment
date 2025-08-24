# Advanced CryptPad Configuration Guide

This guide covers advanced configuration options, security hardening, performance optimization, and enterprise deployment scenarios.

## 🔧 Advanced Configuration Options

### Custom Storage Limits

Configure different storage limits for different users:

```javascript
// In config.js
customLimits: {
  'admin@yourdomain.com': 1000 * 1024 * 1024,    // 1GB for admin
  'premium@yourdomain.com': 500 * 1024 * 1024,   // 500MB for premium users
  'team@yourdomain.com': 200 * 1024 * 1024,      // 200MB for team accounts
},

// Default limit for all other users
defaultStorageLimit: 50 * 1024 * 1024, // 50MB
```

### Rate Limiting Configuration

Implement sophisticated rate limiting:

```javascript
// In config.js
rateLimits: {
  // API request limits
  api: {
    window: 60000,      // 1 minute window
    max: 100,           // 100 requests per minute
  },
  
  // File upload limits
  upload: {
    window: 60000,      // 1 minute window
    max: 10,            // 10 uploads per minute
    size: 20 * 1024 * 1024, // 20MB max file size
  },
  
  // Registration limits
  register: {
    window: 3600000,    // 1 hour window
    max: 5,             // 5 registrations per hour per IP
  },
  
  // Login attempt limits
  login: {
    window: 900000,     // 15 minutes
    max: 10,            // 10 attempts per 15 minutes
  },
},
```

### Advanced Security Headers

Enhanced security configuration:

```javascript
// In config.js
httpHeaders: {
  // Basic security headers
  "X-XSS-Protection": "1; mode=block",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "SAMEORIGIN",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  
  // HSTS with preload
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
  
  // Advanced CSP
  "Content-Security-Policy": [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data:",
    "connect-src 'self' wss: https:",
    "media-src 'self' blob:",
    "object-src 'none'",
    "frame-src 'self' https:",
    "worker-src 'self' blob:",
    "frame-ancestors 'self'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join("; "),
  
  // Feature Policy
  "Permissions-Policy": [
    "geolocation=()",
    "microphone=()",
    "camera=()",
    "payment=()",
    "usb=()",
    "magnetometer=()",
    "gyroscope=()",
    "accelerometer=()"
  ].join(", "),
  
  // CORS headers
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
  "Access-Control-Max-Age": "86400",
},
```

### Database Configuration

For high-performance deployments, consider external database:

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: cryptpad
      POSTGRES_USER: cryptpad
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres.conf:/etc/postgresql/postgresql.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
```

PostgreSQL optimization (`postgres.conf`):
```ini
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Connection settings
max_connections = 100
shared_preload_libraries = 'pg_stat_statements'

# Performance settings
random_page_cost = 1.1
effective_io_concurrency = 200
wal_buffers = 16MB
checkpoint_completion_target = 0.9
```

## 🛡️ Security Hardening

### Network Security

#### Firewall Configuration
```bash
# UFW configuration
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Docker-specific rules
sudo ufw allow from 172.16.0.0/12 to any port 3000
```

#### Docker Network Isolation
```yaml
# docker-compose.yml
networks:
  frontend:
    driver: overlay
    attachable: true
  backend:
    driver: overlay
    internal: true
  
services:
  cryptpad:
    networks:
      - frontend
      - backend
  
  postgres:
    networks:
      - backend  # Only backend network
```

### Access Control

#### IP Whitelisting
```nginx
# In NPM Advanced configuration
# Allow specific IP ranges
allow 192.168.1.0/24;
allow 10.0.0.0/8;
allow 172.16.0.0/12;

# Block specific countries (example)
deny 192.0.2.0/24;

# Default deny
deny all;
```

#### Admin Access Restrictions
```javascript
// In config.js
adminKeys: [
  '[admin@yourdomain.com/AdminPublicKeyHere]'
],

// Restrict admin panel access
adminIps: [
  '192.168.1.0/24',  // Local network only
  '10.0.0.0/8',      // VPN network
],
```

### SSL/TLS Hardening

#### Advanced SSL Configuration
```nginx
# In NPM or custom nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

## 🚀 Performance Optimization

### Container Resource Optimization

#### CPU and Memory Tuning
```yaml
# docker-compose.yml
services:
  cryptpad:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2.0'
        reservations:
          memory: 2G
          cpus: '1.0'
      # CPU affinity for better performance
      placement:
        constraints:
          - node.labels.performance == high
```

#### Node.js Optimization
```javascript
// In config.js
// Increase worker processes
maxWorkers: 8,  // Match CPU cores

// Memory optimization
nodeOptions: [
  '--max-old-space-size=2048',  // 2GB heap
  '--optimize-for-size',
],

// Performance settings
channelExpirationMs: 60000,
openFileLimit: 4096,
```

### Caching Strategy

#### Redis Integration
```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

```javascript
// In config.js
redis: {
  host: 'redis',
  port: 6379,
  db: 0,
  // Optional authentication
  // password: 'your-redis-password',
},

// Enable caching
enableCache: true,
cacheExpiry: 3600, // 1 hour
```

#### CDN Configuration
```javascript
// In config.js
// Use CDN for static assets
cdnUrl: 'https://cdn.yourdomain.com',
staticAssetCache: 86400, // 24 hours
```

### Database Optimization

#### Connection Pooling
```javascript
// In config.js
database: {
  type: 'postgres',
  host: 'postgres',
  port: 5432,
  database: 'cryptpad',
  username: 'cryptpad',
  password: process.env.DB_PASSWORD,
  
  // Connection pooling
  pool: {
    min: 5,
    max: 20,
    acquire: 30000,
    idle: 10000,
  },
  
  // Query optimization
  logging: false, // Disable in production
  benchmark: false,
},
```

## 📊 Monitoring and Observability

### Application Monitoring

#### Health Check Endpoints
```javascript
// In config.js
healthCheck: {
  enabled: true,
  endpoint: '/health',
  checks: {
    database: true,
    redis: true,
    filesystem: true,
    memory: true,
  },
},
```

#### Metrics Collection
```yaml
# docker-compose.yml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
  
  grafana:
    image: grafana/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
```

### Log Management

#### Structured Logging
```javascript
// In config.js
logging: {
  level: 'info',
  format: 'json',
  outputs: [
    {
      type: 'file',
      filename: './data/logs/cryptpad.log',
      maxsize: 10485760, // 10MB
      maxFiles: 5,
    },
    {
      type: 'syslog',
      host: 'log-server.yourdomain.com',
      port: 514,
    },
  ],
},
```

#### ELK Stack Integration
```yaml
# docker-compose.yml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
  
  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch
  
  kibana:
    image: docker.elastic.co/kibana/kibana:8.8.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
```

## 🔄 Backup and Disaster Recovery

### Automated Backup Strategy

#### Database Backup
```bash
#!/bin/bash
# backup-database.sh

BACKUP_DIR="/var/backups/cryptpad"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_NAME="cryptpad-stack_postgres"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker exec $CONTAINER_NAME pg_dump -U cryptpad cryptpad | gzip > $BACKUP_DIR/database_$DATE.sql.gz

# Backup configuration
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /var/lib/cryptpad/config/

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

#### File System Backup
```bash
#!/bin/bash
# backup-files.sh

BACKUP_DIR="/var/backups/cryptpad"
DATE=$(date +%Y%m%d_%H%M%S)
SOURCE_DIR="/var/lib/cryptpad"

# Create incremental backup using rsync
rsync -av --link-dest=$BACKUP_DIR/latest $SOURCE_DIR/ $BACKUP_DIR/backup_$DATE/

# Update latest symlink
rm -f $BACKUP_DIR/latest
ln -s backup_$DATE $BACKUP_DIR/latest

echo "File backup completed: $DATE"
```

### Disaster Recovery

#### Recovery Procedures
```bash
#!/bin/bash
# restore-cryptpad.sh

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/cryptpad"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date>"
    echo "Available backups:"
    ls -la $BACKUP_DIR/backup_*
    exit 1
fi

# Stop services
docker service rm cryptpad-stack_cryptpad
docker service rm cryptpad-stack_postgres

# Restore files
rsync -av $BACKUP_DIR/backup_$BACKUP_DATE/ /var/lib/cryptpad/

# Restore database
gunzip -c $BACKUP_DIR/database_$BACKUP_DATE.sql.gz | docker exec -i cryptpad-stack_postgres psql -U cryptpad cryptpad

# Restart services
docker stack deploy -c docker-compose.yml cryptpad-stack

echo "Recovery completed from backup: $BACKUP_DATE"
```

## 🌐 Multi-Instance Deployment

### Load Balancer Configuration

#### HAProxy Setup
```yaml
# docker-compose.yml
services:
  haproxy:
    image: haproxy:2.8
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - cryptpad1
      - cryptpad2
```

```ini
# haproxy.cfg
global
    daemon
    maxconn 4096

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend cryptpad_frontend
    bind *:443 ssl crt /etc/ssl/certs/cryptpad.pem
    redirect scheme https if !{ ssl_fc }
    default_backend cryptpad_backend

backend cryptpad_backend
    balance roundrobin
    option httpchk GET /api/config
    server cryptpad1 cryptpad1:3000 check
    server cryptpad2 cryptpad2:3000 check
```

### Shared Storage

#### NFS Configuration
```yaml
# docker-compose.yml
volumes:
  cryptpad_shared:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.yourdomain.com,rw
      device: ":/var/nfs/cryptpad"
```

## 🔐 Enterprise Integration

### LDAP Authentication

```javascript
// In config.js
ldap: {
  enabled: true,
  server: 'ldap://ldap.yourdomain.com:389',
  bindDN: 'cn=cryptpad,ou=services,dc=yourdomain,dc=com',
  bindPassword: process.env.LDAP_PASSWORD,
  searchBase: 'ou=users,dc=yourdomain,dc=com',
  searchFilter: '(uid={{username}})',
  attributes: {
    username: 'uid',
    email: 'mail',
    displayName: 'cn',
  },
},
```

### SAML Integration

```javascript
// In config.js
saml: {
  enabled: true,
  entryPoint: 'https://sso.yourdomain.com/saml/login',
  issuer: 'cryptpad.yourdomain.com',
  cert: fs.readFileSync('/etc/ssl/certs/saml.crt', 'utf8'),
  privateKey: fs.readFileSync('/etc/ssl/private/saml.key', 'utf8'),
  attributes: {
    username: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
    email: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
  },
},
```

This advanced configuration guide provides enterprise-grade deployment options for CryptPad. Always test configurations in a staging environment before applying to production.


# Backup and Recovery Guide

This guide covers comprehensive backup strategies and disaster recovery procedures for CryptPad deployments.

## 📋 Backup Strategy Overview

### What to Backup
1. **User Data**: Documents, files, and user-generated content
2. **Configuration**: CryptPad configuration files
3. **Database**: User accounts and metadata (if using external DB)
4. **SSL Certificates**: Custom certificates and keys
5. **Container Images**: Custom or specific versions

### Backup Types
- **Full Backup**: Complete system backup (weekly)
- **Incremental Backup**: Changed files only (daily)
- **Configuration Backup**: Config files only (before changes)
- **Database Backup**: Database dump (daily)

## 🔄 Automated Backup Scripts

### Full System Backup
```bash
#!/bin/bash
# backup-full.sh - Complete CryptPad backup

set -e

# Configuration
BACKUP_DIR="/var/backups/cryptpad"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
SOURCE_DIR="/var/lib/cryptpad"
STACK_NAME="cryptpad-stack"

# Create backup directory
mkdir -p $BACKUP_DIR

echo "Starting full backup: $DATE"

# Backup CryptPad data
echo "Backing up CryptPad data..."
tar -czf $BACKUP_DIR/cryptpad_data_$DATE.tar.gz -C /var/lib cryptpad/

# Backup Docker volumes
echo "Backing up Docker volumes..."
docker run --rm -v cryptpad-stack_cryptpad_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/volumes_$DATE.tar.gz -C /data .

# Backup configuration
echo "Backing up configuration..."
cp -r /var/lib/cryptpad/config $BACKUP_DIR/config_$DATE/

# Backup database (if using external DB)
if docker service ls | grep -q postgres; then
    echo "Backing up database..."
    docker exec $(docker ps -q -f name=postgres) pg_dump -U cryptpad cryptpad | gzip > $BACKUP_DIR/database_$DATE.sql.gz
fi

# Backup Docker Compose files
echo "Backing up Docker Compose..."
cp docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml

# Create backup manifest
cat > $BACKUP_DIR/manifest_$DATE.txt <<EOF
Backup Date: $DATE
CryptPad Version: $(docker image inspect cryptpad:2025.6.0 --format '{{.Config.Labels.version}}' 2>/dev/null || echo "Unknown")
Backup Contents:
- cryptpad_data_$DATE.tar.gz (User data and files)
- volumes_$DATE.tar.gz (Docker volumes)
- config_$DATE/ (Configuration files)
- database_$DATE.sql.gz (Database dump)
- docker-compose_$DATE.yml (Docker configuration)
EOF

# Cleanup old backups
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -type d -name "config_*" -mtime +$RETENTION_DAYS -exec rm -rf {} +

echo "Full backup completed: $DATE"
```

### Incremental Backup
```bash
#!/bin/bash
# backup-incremental.sh - Daily incremental backup

set -e

BACKUP_DIR="/var/backups/cryptpad/incremental"
DATE=$(date +%Y%m%d_%H%M%S)
SOURCE_DIR="/var/lib/cryptpad"

mkdir -p $BACKUP_DIR

echo "Starting incremental backup: $DATE"

# Create incremental backup using rsync
rsync -av --link-dest=$BACKUP_DIR/latest $SOURCE_DIR/ $BACKUP_DIR/backup_$DATE/

# Update latest symlink
rm -f $BACKUP_DIR/latest
ln -s backup_$DATE $BACKUP_DIR/latest

# Cleanup old incremental backups (keep 7 days)
find $BACKUP_DIR -maxdepth 1 -type d -name "backup_*" -mtime +7 -exec rm -rf {} +

echo "Incremental backup completed: $DATE"
```

### Database-Only Backup
```bash
#!/bin/bash
# backup-database.sh - Database backup only

set -e

BACKUP_DIR="/var/backups/cryptpad/database"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER_NAME="cryptpad-stack_postgres"

mkdir -p $BACKUP_DIR

echo "Starting database backup: $DATE"

# Check if database container exists
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "Database container not found: $CONTAINER_NAME"
    exit 1
fi

# Create database backup
docker exec $CONTAINER_NAME pg_dump -U cryptpad cryptpad | gzip > $BACKUP_DIR/cryptpad_db_$DATE.sql.gz

# Verify backup
if [ -f $BACKUP_DIR/cryptpad_db_$DATE.sql.gz ]; then
    SIZE=$(stat -f%z $BACKUP_DIR/cryptpad_db_$DATE.sql.gz 2>/dev/null || stat -c%s $BACKUP_DIR/cryptpad_db_$DATE.sql.gz)
    echo "Database backup completed: $SIZE bytes"
else
    echo "Database backup failed!"
    exit 1
fi

# Cleanup old database backups (keep 14 days)
find $BACKUP_DIR -name "*.sql.gz" -mtime +14 -delete

echo "Database backup completed: $DATE"
```

## 📅 Backup Scheduling

### Cron Configuration
```bash
# Add to crontab: crontab -e

# Full backup every Sunday at 2 AM
0 2 * * 0 /usr/local/bin/backup-full.sh >> /var/log/cryptpad-backup.log 2>&1

# Incremental backup daily at 3 AM (except Sunday)
0 3 * * 1-6 /usr/local/bin/backup-incremental.sh >> /var/log/cryptpad-backup.log 2>&1

# Database backup every 6 hours
0 */6 * * * /usr/local/bin/backup-database.sh >> /var/log/cryptpad-backup.log 2>&1

# Configuration backup before any changes (manual trigger)
# /usr/local/bin/backup-config.sh
```

### Systemd Timer (Alternative)
```ini
# /etc/systemd/system/cryptpad-backup.timer
[Unit]
Description=CryptPad Backup Timer
Requires=cryptpad-backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/cryptpad-backup.service
[Unit]
Description=CryptPad Backup Service
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-full.sh
User=root
```

## 🔄 Disaster Recovery Procedures

### Complete System Recovery
```bash
#!/bin/bash
# restore-complete.sh - Complete system restoration

set -e

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/cryptpad"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date>"
    echo "Available backups:"
    ls -la $BACKUP_DIR/cryptpad_data_*.tar.gz | awk '{print $9}' | sed 's/.*cryptpad_data_\(.*\)\.tar\.gz/\1/'
    exit 1
fi

echo "Starting complete system recovery from backup: $BACKUP_DATE"

# Stop all services
echo "Stopping CryptPad services..."
docker stack rm cryptpad-stack || true
sleep 30

# Remove existing data (DANGEROUS - make sure you want to do this)
read -p "This will DELETE all existing CryptPad data. Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Recovery cancelled."
    exit 1
fi

# Backup current state before restoration
if [ -d "/var/lib/cryptpad" ]; then
    echo "Backing up current state..."
    mv /var/lib/cryptpad /var/lib/cryptpad.backup.$(date +%Y%m%d_%H%M%S)
fi

# Restore data
echo "Restoring CryptPad data..."
mkdir -p /var/lib
tar -xzf $BACKUP_DIR/cryptpad_data_$BACKUP_DATE.tar.gz -C /var/lib/

# Restore Docker volumes
echo "Restoring Docker volumes..."
docker volume create cryptpad-stack_cryptpad_data
docker run --rm -v cryptpad-stack_cryptpad_data:/data -v $BACKUP_DIR:/backup alpine tar -xzf /backup/volumes_$BACKUP_DATE.tar.gz -C /data

# Restore configuration
echo "Restoring configuration..."
if [ -d "$BACKUP_DIR/config_$BACKUP_DATE" ]; then
    cp -r $BACKUP_DIR/config_$BACKUP_DATE/* /var/lib/cryptpad/config/
fi

# Set proper permissions
echo "Setting permissions..."
chown -R 4001:4001 /var/lib/cryptpad/
chmod -R 755 /var/lib/cryptpad/
chmod 644 /var/lib/cryptpad/config/config.js

# Restore Docker Compose
echo "Restoring Docker Compose..."
if [ -f "$BACKUP_DIR/docker-compose_$BACKUP_DATE.yml" ]; then
    cp $BACKUP_DIR/docker-compose_$BACKUP_DATE.yml docker-compose.yml
fi

# Start services
echo "Starting services..."
docker stack deploy -c docker-compose.yml cryptpad-stack

# Wait for services to start
echo "Waiting for services to start..."
sleep 60

# Restore database (if backup exists)
if [ -f "$BACKUP_DIR/database_$BACKUP_DATE.sql.gz" ]; then
    echo "Restoring database..."
    # Wait for database to be ready
    sleep 30
    gunzip -c $BACKUP_DIR/database_$BACKUP_DATE.sql.gz | docker exec -i $(docker ps -q -f name=postgres) psql -U cryptpad cryptpad
fi

echo "Recovery completed. Please verify the system is working correctly."
echo "Check: https://cryptpad.yourdomain.com/checkup/"
```

### Partial Recovery Scripts

#### Configuration Only
```bash
#!/bin/bash
# restore-config.sh - Restore configuration only

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/cryptpad"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date>"
    exit 1
fi

# Backup current config
cp -r /var/lib/cryptpad/config /var/lib/cryptpad/config.backup.$(date +%Y%m%d_%H%M%S)

# Restore configuration
cp -r $BACKUP_DIR/config_$BACKUP_DATE/* /var/lib/cryptpad/config/

# Set permissions
chown -R 4001:4001 /var/lib/cryptpad/config/
chmod 644 /var/lib/cryptpad/config/config.js

# Restart CryptPad
docker service update --force cryptpad-stack_cryptpad

echo "Configuration restored from backup: $BACKUP_DATE"
```

#### Database Only
```bash
#!/bin/bash
# restore-database.sh - Restore database only

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/cryptpad/database"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date>"
    exit 1
fi

# Create database backup before restoration
docker exec $(docker ps -q -f name=postgres) pg_dump -U cryptpad cryptpad | gzip > /tmp/pre_restore_backup.sql.gz

# Restore database
echo "Restoring database from backup: $BACKUP_DATE"
gunzip -c $BACKUP_DIR/cryptpad_db_$BACKUP_DATE.sql.gz | docker exec -i $(docker ps -q -f name=postgres) psql -U cryptpad cryptpad

echo "Database restored from backup: $BACKUP_DATE"
echo "Pre-restoration backup saved to: /tmp/pre_restore_backup.sql.gz"
```

## 🔍 Backup Verification

### Backup Integrity Check
```bash
#!/bin/bash
# verify-backup.sh - Verify backup integrity

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/cryptpad"

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date>"
    exit 1
fi

echo "Verifying backup integrity for: $BACKUP_DATE"

# Check if backup files exist
FILES=(
    "cryptpad_data_$BACKUP_DATE.tar.gz"
    "volumes_$BACKUP_DATE.tar.gz"
    "database_$BACKUP_DATE.sql.gz"
    "docker-compose_$BACKUP_DATE.yml"
)

for file in "${FILES[@]}"; do
    if [ -f "$BACKUP_DIR/$file" ]; then
        echo "✓ $file exists"
        # Test archive integrity
        if [[ $file == *.tar.gz ]]; then
            if tar -tzf "$BACKUP_DIR/$file" >/dev/null 2>&1; then
                echo "✓ $file archive integrity OK"
            else
                echo "✗ $file archive integrity FAILED"
            fi
        elif [[ $file == *.sql.gz ]]; then
            if gunzip -t "$BACKUP_DIR/$file" >/dev/null 2>&1; then
                echo "✓ $file compression integrity OK"
            else
                echo "✗ $file compression integrity FAILED"
            fi
        fi
    else
        echo "✗ $file missing"
    fi
done

# Check manifest
if [ -f "$BACKUP_DIR/manifest_$BACKUP_DATE.txt" ]; then
    echo "✓ Backup manifest exists"
    cat "$BACKUP_DIR/manifest_$BACKUP_DATE.txt"
else
    echo "✗ Backup manifest missing"
fi
```

### Test Restoration
```bash
#!/bin/bash
# test-restore.sh - Test restoration in isolated environment

BACKUP_DATE=$1
TEST_DIR="/tmp/cryptpad-restore-test"

# Create test environment
mkdir -p $TEST_DIR
cd $TEST_DIR

# Extract backup
tar -xzf /var/backups/cryptpad/cryptpad_data_$BACKUP_DATE.tar.gz

# Verify critical files
if [ -f "cryptpad/config/config.js" ]; then
    echo "✓ Configuration file present"
    node -c cryptpad/config/config.js && echo "✓ Configuration syntax valid"
else
    echo "✗ Configuration file missing"
fi

# Check data directories
DIRS=("data" "blob" "block" "datastore")
for dir in "${DIRS[@]}"; do
    if [ -d "cryptpad/$dir" ]; then
        echo "✓ Directory $dir present"
    else
        echo "✗ Directory $dir missing"
    fi
done

# Cleanup
rm -rf $TEST_DIR
echo "Test restoration completed"
```

## 📊 Monitoring and Alerting

### Backup Monitoring Script
```bash
#!/bin/bash
# monitor-backups.sh - Monitor backup status

BACKUP_DIR="/var/backups/cryptpad"
ALERT_EMAIL="admin@yourdomain.com"
MAX_AGE_HOURS=25  # Alert if backup is older than 25 hours

# Check latest backup age
LATEST_BACKUP=$(ls -t $BACKUP_DIR/cryptpad_data_*.tar.gz | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_AGE=$(( ($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 3600 ))
    
    if [ $BACKUP_AGE -gt $MAX_AGE_HOURS ]; then
        echo "WARNING: Latest backup is $BACKUP_AGE hours old" | mail -s "CryptPad Backup Alert" $ALERT_EMAIL
    else
        echo "✓ Latest backup is $BACKUP_AGE hours old (OK)"
    fi
else
    echo "ERROR: No backups found!" | mail -s "CryptPad Backup CRITICAL" $ALERT_EMAIL
fi

# Check backup sizes
EXPECTED_MIN_SIZE=1048576  # 1MB minimum
for backup in $(ls $BACKUP_DIR/cryptpad_data_*.tar.gz | tail -5); do
    SIZE=$(stat -c %s "$backup")
    if [ $SIZE -lt $EXPECTED_MIN_SIZE ]; then
        echo "WARNING: Backup $backup is only $SIZE bytes" | mail -s "CryptPad Backup Size Alert" $ALERT_EMAIL
    fi
done
```

## 📋 Backup Checklist

### Daily Tasks
- [ ] Verify automated backups completed
- [ ] Check backup logs for errors
- [ ] Monitor backup storage space

### Weekly Tasks
- [ ] Test backup integrity
- [ ] Review backup retention policy
- [ ] Verify off-site backup sync

### Monthly Tasks
- [ ] Test restoration procedure
- [ ] Review and update backup scripts
- [ ] Audit backup access controls

### Quarterly Tasks
- [ ] Full disaster recovery test
- [ ] Review backup strategy
- [ ] Update documentation

Remember: Backups are only as good as your ability to restore from them. Regular testing is essential!


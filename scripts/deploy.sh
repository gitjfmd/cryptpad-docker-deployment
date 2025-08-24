#!/bin/bash

# CryptPad Docker Deployment Script
# This script automates the deployment of CryptPad with Docker Swarm and Portainer

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CRYPTPAD_VERSION="2025.6.0"
STACK_NAME="cryptpad-stack"
CONFIG_DIR="/var/lib/cryptpad"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons."
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Swarm is initialized
    if ! docker info | grep -q "Swarm: active"; then
        print_warning "Docker Swarm is not initialized."
        read -p "Do you want to initialize Docker Swarm? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Initializing Docker Swarm..."
            sudo docker swarm init
            print_success "Docker Swarm initialized successfully."
        else
            print_error "Docker Swarm is required for this deployment."
            exit 1
        fi
    fi
    
    # Check if curl is installed
    if ! command_exists curl; then
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    print_success "All prerequisites met."
}

# Function to collect user configuration
collect_configuration() {
    print_status "Collecting configuration..."
    
    # Main domain
    read -p "Enter your main domain (e.g., cryptpad.yourdomain.com): " MAIN_DOMAIN
    if [[ -z "$MAIN_DOMAIN" ]]; then
        print_error "Main domain is required."
        exit 1
    fi
    
    # Sandbox domain
    read -p "Enter your sandbox domain (e.g., cryptpad-sandbox.yourdomain.com): " SANDBOX_DOMAIN
    if [[ -z "$SANDBOX_DOMAIN" ]]; then
        print_error "Sandbox domain is required."
        exit 1
    fi
    
    # Admin email
    read -p "Enter admin email: " ADMIN_EMAIL
    if [[ -z "$ADMIN_EMAIL" ]]; then
        print_error "Admin email is required."
        exit 1
    fi
    
    # Instance name
    read -p "Enter instance name (default: CryptPad Instance): " INSTANCE_NAME
    INSTANCE_NAME=${INSTANCE_NAME:-"CryptPad Instance"}
    
    print_success "Configuration collected."
}

# Function to create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    # Create main directories
    sudo mkdir -p ${CONFIG_DIR}/{config,data,blob,block,datastore,customize}
    sudo mkdir -p ${CONFIG_DIR}/data/logs
    
    # Set proper permissions
    sudo chown -R 4001:4001 ${CONFIG_DIR}/
    sudo chmod -R 755 ${CONFIG_DIR}/
    
    print_success "Directory structure created."
}

# Function to generate configuration files
generate_config() {
    print_status "Generating CryptPad configuration..."
    
    # Create config.js
    sudo tee ${CONFIG_DIR}/config/config.js >/dev/null <<EOF
module.exports = {
  httpAddress: '0.0.0.0',
  httpPort: 3000,
  installMethod: 'docker',

  // Domain configuration
  httpUnsafeOrigin: 'https://${MAIN_DOMAIN}',
  mainDomain: 'https://${MAIN_DOMAIN}',
  sandboxDomain: 'https://${SANDBOX_DOMAIN}',
  httpSafeOrigin: 'https://${SANDBOX_DOMAIN}',

  // Admin configuration
  adminEmail: '${ADMIN_EMAIL}',
  supportMailbox: '${ADMIN_EMAIL}',
  
  // Admin keys (add after initial setup)
  adminKeys: [
    // Add your admin key here after registration
  ],

  // Terms and Privacy pages
  terms: {
    default: 'https://${MAIN_DOMAIN}/terms.html',
  },
  
  privacy: {
    default: 'https://${MAIN_DOMAIN}/privacy.html',
  },

  // Security headers
  httpHeaders: {
    "X-XSS-Protection": "1; mode=block",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With"
  },

  // Logging
  logPath: './data/logs',
  logLevel: 'info',
  logToStdout: true,
  verbose: false,

  // File storage and limits
  defaultStorageLimit: 50 * 1024 * 1024, // 50MB per user
  maxUploadSize: 20 * 1024 * 1024, // 20MB per file

  // Performance settings
  inactiveTime: 90,
  archiveRetentionTime: 15,
  maxWorkers: 4,

  // Registration and access control
  restrictRegistration: false,
  enableEmbedding: false,

  // WebSocket configuration
  websocketPath: '/cryptpad_websocket',

  // Database settings
  channelExpirationMs: 30000,
  openFileLimit: 2048,

  // File paths
  filePath: './datastore/',
  archivePath: './data/archive',
  pinPath: './data/pins',
  taskPath: './data/tasks',
  blockPath: './block',
  blobPath: './blob',
  blobStagingPath: './data/blobstage',
  decreePath: './data/decrees',

  // Backup settings
  enableBackups: true,
  backupInterval: 24 * 60 * 60 * 1000, // 24 hours

  // Instance information
  instanceName: '${INSTANCE_NAME}',
  instanceDescription: 'Secure collaborative document editing platform',
  
  // Content Security Policy
  contentSecurity: {
    padContentSecurity: {
      "default-src": "'self'",
      "style-src": "'self' 'unsafe-inline'",
      "script-src": "'self' 'unsafe-eval' 'unsafe-inline'",
      "child-src": "'self' *",
      "font-src": "'self' data:",
      "connect-src": "'self' wss: https:",
      "img-src": "'self' data: blob:",
      "media-src": "'self' blob:"
    }
  },

  // Disable some features that might cause issues initially
  suppressRPCErrors: false,
  disableIntegratedTasks: false,
  disableIntegratedEviction: false,
};
EOF

    # Set proper permissions
    sudo chown 4001:4001 ${CONFIG_DIR}/config/config.js
    sudo chmod 644 ${CONFIG_DIR}/config/config.js
    
    print_success "Configuration file generated."
}

# Function to create terms and privacy pages
create_legal_pages() {
    print_status "Creating terms and privacy pages..."
    
    # Create terms.html
    sudo tee ${CONFIG_DIR}/customize/www/terms.html >/dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Terms of Service - ${INSTANCE_NAME}</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2 { color: #333; }
        p, li { line-height: 1.6; }
    </style>
</head>
<body>
    <h1>Terms of Service</h1>
    <p>Last updated: $(date)</p>
    
    <h2>1. Acceptance of Terms</h2>
    <p>By using this CryptPad instance, you agree to these terms.</p>
    
    <h2>2. Service Description</h2>
    <p>This is a private CryptPad instance for secure document collaboration.</p>
    
    <h2>3. User Responsibilities</h2>
    <ul>
        <li>Use the service responsibly</li>
        <li>Do not upload illegal content</li>
        <li>Respect other users</li>
        <li>Keep your account secure</li>
    </ul>
    
    <h2>4. Privacy</h2>
    <p>We cannot read your documents due to zero-knowledge encryption.</p>
    
    <h2>5. Limitation of Liability</h2>
    <p>This service is provided "as is" without warranties.</p>
    
    <h2>6. Contact</h2>
    <p>For questions, contact: ${ADMIN_EMAIL}</p>
</body>
</html>
EOF

    # Create privacy.html
    sudo tee ${CONFIG_DIR}/customize/www/privacy.html >/dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy - ${INSTANCE_NAME}</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1, h2 { color: #333; }
        p, li { line-height: 1.6; }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p>Last updated: $(date)</p>
    
    <h2>1. Information We Collect</h2>
    <p>We collect minimal information necessary to operate the service:</p>
    <ul>
        <li>Account information (username, encrypted)</li>
        <li>Usage statistics (anonymous)</li>
        <li>Server logs (IP addresses, temporary)</li>
    </ul>
    
    <h2>2. Zero-Knowledge Architecture</h2>
    <p>Your documents are encrypted in your browser before being sent to our servers. We cannot read your content.</p>
    
    <h2>3. Data Storage</h2>
    <p>Data is stored securely and backed up regularly. We do not share data with third parties.</p>
    
    <h2>4. Cookies</h2>
    <p>We use essential cookies for functionality. No tracking cookies are used.</p>
    
    <h2>5. Data Retention</h2>
    <p>Data is retained according to our backup and archival policies.</p>
    
    <h2>6. Contact</h2>
    <p>For privacy questions, contact: ${ADMIN_EMAIL}</p>
</body>
</html>
EOF

    # Set permissions
    sudo chown -R 4001:4001 ${CONFIG_DIR}/customize/
    
    print_success "Legal pages created."
}

# Function to generate Docker Compose file
generate_docker_compose() {
    print_status "Generating Docker Compose file..."
    
    cat > docker-compose.yml <<EOF
version: '3.8'

networks:
  tunnel_net:
    external: true
  cryptpad_internal:
    driver: overlay
    internal: true

volumes:
  cryptpad_data:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/data }
  cryptpad_config:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/config }
  cryptpad_blob:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/blob }
  cryptpad_block:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/block }
  cryptpad_datastore:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/datastore }
  cryptpad_customize:
    driver: local
    driver_opts: { type: none, o: bind, device: ${CONFIG_DIR}/customize }

services:
  cryptpad:
    image: cryptpad:${CRYPTPAD_VERSION}
    networks: [tunnel_net]
    environment:
      CPAD_MAIN_DOMAIN: https://${MAIN_DOMAIN}
      CPAD_SANDBOX_DOMAIN: https://${SANDBOX_DOMAIN}
      CPAD_CONF: /cryptpad/config/config.js
      NODE_ENV: production
      CPAD_HTTP_ADDRESS: 0.0.0.0
      CPAD_HTTP_PORT: 3000
    volumes:
      - cryptpad_blob:/cryptpad/blob
      - cryptpad_block:/cryptpad/block
      - cryptpad_data:/cryptpad/data
      - cryptpad_datastore:/cryptpad/datastore
      - cryptpad_customize:/cryptpad/customize
      - cryptpad_config:/cryptpad/config:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/config"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      restart_policy:
        condition: any
        delay: 10s
        max_attempts: 5
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
        reservations:
          memory: 1G
          cpus: '0.5'
EOF

    print_success "Docker Compose file generated."
}

# Function to deploy the stack
deploy_stack() {
    print_status "Deploying CryptPad stack..."
    
    # Deploy the stack
    docker stack deploy -c docker-compose.yml ${STACK_NAME}
    
    print_success "Stack deployed successfully."
    
    # Wait for services to start
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service status
    docker service ls --filter name=${STACK_NAME}
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if container is running
    if docker service ps ${STACK_NAME}_cryptpad | grep -q "Running"; then
        print_success "CryptPad container is running."
    else
        print_error "CryptPad container is not running."
        docker service logs ${STACK_NAME}_cryptpad --tail 20
        return 1
    fi
    
    # Test internal connectivity
    print_status "Testing internal connectivity..."
    sleep 10
    
    if docker exec $(docker ps -q -f name=${STACK_NAME}_cryptpad) curl -f http://localhost:3000/api/config >/dev/null 2>&1; then
        print_success "Internal API is responding."
    else
        print_warning "Internal API test failed. This might be normal if the container is still starting."
    fi
    
    print_success "Deployment verification completed."
}

# Function to display next steps
show_next_steps() {
    print_success "CryptPad deployment completed!"
    echo
    print_status "Next steps:"
    echo "1. Configure your reverse proxy (Nginx Proxy Manager) with these domains:"
    echo "   - Main: https://${MAIN_DOMAIN}"
    echo "   - Sandbox: https://${SANDBOX_DOMAIN}"
    echo
    echo "2. Both domains should forward to: cryptpad:3000"
    echo
    echo "3. Add the required nginx headers (see nginx-proxy-manager-config.md)"
    echo
    echo "4. Test your deployment:"
    echo "   curl -v https://${MAIN_DOMAIN}/api/config"
    echo
    echo "5. Register an admin account and add your admin key to the config"
    echo
    echo "6. Run the checkup: https://${MAIN_DOMAIN}/checkup/"
    echo
    print_warning "Remember to configure your reverse proxy before testing!"
}

# Main execution
main() {
    echo "=========================================="
    echo "CryptPad Docker Deployment Script"
    echo "=========================================="
    echo
    
    check_prerequisites
    collect_configuration
    create_directories
    generate_config
    create_legal_pages
    generate_docker_compose
    deploy_stack
    verify_deployment
    show_next_steps
    
    print_success "Deployment script completed successfully!"
}

# Run main function
main "$@"


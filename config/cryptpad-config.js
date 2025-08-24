module.exports = {
  httpAddress: '0.0.0.0',
  httpPort: 3000,
  installMethod: 'docker',

  // CRITICAL: Replace with your actual domains
  httpUnsafeOrigin: 'https://cryptpad.yourdomain.com',
  mainDomain: 'https://cryptpad.yourdomain.com',
  sandboxDomain: 'https://cryptpad-sandbox.yourdomain.com',
  httpSafeOrigin: 'https://cryptpad-sandbox.yourdomain.com',

  // Admin configuration - Replace with your email
  adminEmail: 'admin@yourdomain.com',
  supportMailbox: 'support@yourdomain.com',
  
  // Add your admin keys here after generating them
  // To generate: visit your CryptPad, register, go to Settings > Account
  // Copy your public signing key and add it here
  adminKeys: [
    // Example: '[admin@yourdomain.com/YZgXQxKR0Rcb6r6CmxHPdAGLVludrAF2lEnkbx1vVOo=]'
    // Add your actual admin key here
  ],

  // Terms and Privacy pages
  terms: {
    default: 'https://cryptpad.yourdomain.com/terms.html',
  },
  
  privacy: {
    default: 'https://cryptpad.yourdomain.com/privacy.html',
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
  restrictRegistration: false, // Set to true if you want to restrict registration
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
  instanceName: 'Your CryptPad Instance',
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

  // Custom limits (optional)
  /*
  customLimits: {
    'admin@yourdomain.com': 500 * 1024 * 1024 // 500MB for admin
  },
  */

  // Rate limiting (optional)
  /*
  rateLimits: {
    upload: 10, // uploads per minute
    register: 5, // registrations per hour
  },
  */
};


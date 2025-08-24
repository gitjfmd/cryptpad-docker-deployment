module.exports = {
  httpAddress: '0.0.0.0',
  httpPort: 3000,
  installMethod: 'docker',

  // Domain configuration
  httpUnsafeOrigin: 'https://crypt.secsols.dev',
  mainDomain: 'https://crypt.secsols.dev',
  sandboxDomain: 'https://cryptsandbox.secsols.dev',
  httpSafeOrigin: 'https://cryptsandbox.secsols.dev',

  // Logging
  logPath: './data/logs',
  logLevel: 'info',
  logToStdout: true,
  verbose: false,

  // ADMIN CONFIGURATION - Addresses checkup issues #13, #14, #15
  adminEmail: 'admin@secsols.dev', // Fix for test #13
  supportMailbox: 'support@secsols.dev', // Fix for test #14
  
  // Add your admin keys here after generating them
  // To generate: visit your CryptPad, register, go to Settings > Account
  // Copy your public signing key and add it here
  adminKeys: [
    // Example: '[admin@secsols.dev/YZgXQxKR0Rcb6r6CmxHPdAGLVludrAF2lEnkbx1vVOo=]'
    // Add your actual admin key here
  ],

  // TERMS AND PRIVACY - Addresses checkup issues #33, #35
  terms: {
    default: 'https://crypt.secsols.dev/terms.html',
    // You can add other languages if needed
    // fr: 'https://crypt.secsols.dev/terms-fr.html'
  },
  
  privacy: {
    default: 'https://crypt.secsols.dev/privacy.html',
    // You can add other languages if needed
    // fr: 'https://crypt.secsols.dev/privacy-fr.html'
  },

  // SECURITY HEADERS - Addresses HSTS issue #53
  httpHeaders: {
    "X-XSS-Protection": "1; mode=block",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains; preload", // Fix for HSTS
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With"
  },

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

  // Instance information
  instanceName: 'SecSols CryptPad',
  instanceDescription: 'Secure collaborative document editing platform',
  
  // Disable some features that might cause issues
  suppressRPCErrors: false,
  disableIntegratedTasks: false,
  disableIntegratedEviction: false,

  // Custom limits (optional)
  /*
  customLimits: {
    'admin@secsols.dev': 500 * 1024 * 1024 // 500MB for admin
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


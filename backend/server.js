const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from the backend .env file explicitly
// This avoids cases where the process is started from a different working directory.
dotenv.config({ path: path.resolve(__dirname, '.env') });

const { connectDB } = require('./src/config/db');
const healthRoutes = require('./src/routes/healthRoutes');
const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const personalizationRoutes = require('./src/routes/personalizationRoutes');
const aiRoutes = require('./src/routes/aiRoutes');
const recipeRoutes = require('./src/routes/recipeRoutes');
const errorHandler = require('./src/middleware/errorHandler');
const notFound = require('./src/middleware/notFound');

// Initialize Express app
const app = express();

// =============================================================================
// Middleware Setup
// =============================================================================

// CORS Configuration - Permissive for Flutter mobile apps, emulators, and web
const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(
  cors({
    origin: corsOrigin === '*' ? '*' : corsOrigin.split(',').map((o) => o.trim()),
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
    credentials: true,
  })
);

// Body Parsing Middleware
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// HTTP Request Logger
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// =============================================================================
// API Routes
// =============================================================================

const apiPrefix = process.env.API_PREFIX || '/api';

// Health Check Route
app.use(`${apiPrefix}/health`, healthRoutes);

// Authentication Routes
app.use(`${apiPrefix}/auth`, authRoutes);

// User Profile Routes
app.use(`${apiPrefix}/profile`, profileRoutes);

// Personalization Preferences Routes
app.use(`${apiPrefix}/personalization`, personalizationRoutes);

// AI Nutrition Intelligence & Coach Routes
app.use(`${apiPrefix}/ai`, aiRoutes);

// Personalized Recipe Generator Routes (Phase 6D)
app.use(`${apiPrefix}/recipes`, recipeRoutes);




// Root Welcome Route
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    name: 'DietCompass Backend API',
    version: '1.0.0',
    description: 'AI-Powered Nutrition & Diet Assistant Backend',
    documentation: `${apiPrefix}/health`,
    timestamp: new Date().toISOString(),
  });
});

// =============================================================================
// Error Handling Middleware
// =============================================================================

// 404 Route Not Found Handler
app.use(notFound);

// Centralized Error Handler
app.use(errorHandler);

// =============================================================================
// Server Bootstrap & Lifecycle
// =============================================================================

const PORT = process.env.PORT || 5000;

let server;

const startServer = async () => {
  // Attempt MongoDB Connection
  await connectDB();

  server = app.listen(PORT, () => {
    console.log(`\n🚀 [DietCompass Server Running]`);
    console.log(`   • Port:        ${PORT}`);
    console.log(`   • Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`   • Health Check: http://localhost:${PORT}${apiPrefix}/health`);
    console.log(`   • Base URL:     http://localhost:${PORT}/\n`);
  });
};

// Graceful Shutdown
const handleShutdown = (signal) => {
  console.log(`\n🛑 [${signal} received] Closing HTTP server gracefully...`);
  if (server) {
    server.close(() => {
      console.log('✅ [Server Closed] HTTP server terminated.');
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
};

process.on('SIGINT', () => handleShutdown('SIGINT'));
process.on('SIGTERM', () => handleShutdown('SIGTERM'));

// Start the server
startServer();

module.exports = app;

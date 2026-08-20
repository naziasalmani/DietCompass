const { getDBStatus } = require('../config/db');

/**
 * @desc    Get API & Database health status
 * @route   GET /api/health
 * @access  Public
 */
const getHealthStatus = (req, res) => {
  const dbStatus = getDBStatus();

  res.status(200).json({
    success: true,
    message: 'DietCompass API server is healthy and running.',
    data: {
      server: {
        status: 'UP',
        environment: process.env.NODE_ENV || 'development',
        uptimeSeconds: Math.floor(process.uptime()),
        timestamp: new Date().toISOString(),
        nodeVersion: process.version,
      },
      database: dbStatus,
    },
  });
};

module.exports = { getHealthStatus };

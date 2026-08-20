const mongoose = require('mongoose');

/**
 * Connect to MongoDB Atlas via Mongoose
 */
const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (!uri || uri.includes('<username>') || uri.includes('<password>')) {
    console.warn(
      '⚠️  [Database Warning] MONGODB_URI is missing or contains placeholder values in .env.\n' +
      '   Please configure a valid MongoDB Atlas connection string in backend/.env to enable database operations.'
    );
    return false;
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000,
    });

    console.log(`✅ [MongoDB Connected] Host: ${conn.connection.host} | Database: ${conn.connection.name}`);
    return true;
  } catch (error) {
    console.error(`❌ [MongoDB Connection Error] ${error.message}`);
    return false;
  }
};

/**
 * Helper to get current connection state
 */
const getDBStatus = () => {
  const states = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };

  return {
    state: states[mongoose.connection.readyState] || 'unknown',
    readyState: mongoose.connection.readyState,
    isConnected: mongoose.connection.readyState === 1,
    host: mongoose.connection.host || null,
    databaseName: mongoose.connection.name || null,
  };
};

// Listen to Mongoose connection events
mongoose.connection.on('disconnected', () => {
  console.warn('⚠️  [MongoDB] Disconnected from database.');
});

mongoose.connection.on('reconnected', () => {
  console.log('🔄 [MongoDB] Reconnected to database.');
});

module.exports = { connectDB, getDBStatus };

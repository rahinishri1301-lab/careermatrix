const mongoose = require('mongoose');

/**
 * Establishes connection to MongoDB using Mongoose.
 * Tries the primary MONGO_URI first. If local MongoDB service is unavailable,
 * attempts to spin up an in-memory MongoDB instance for seamless local dev.
 */
const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/career_matrix';

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 3000,
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);

    mongoose.connection.on('error', (err) => {
      console.error(`MongoDB connection error: ${err.message}`);
    });

    return conn;
  } catch (error) {
    console.warn(`Primary MongoDB (${uri}) not reachable: ${error.message}`);
    console.log('Attempting in-memory MongoDB fallback for local development...');

    try {
      const { MongoMemoryServer } = require('mongodb-memory-server');
      const mongod = await MongoMemoryServer.create();
      const memoryUri = mongod.getUri();

      const conn = await mongoose.connect(memoryUri);
      console.log(`In-Memory MongoDB Connected: ${conn.connection.host}`);
      return conn;
    } catch (memErr) {
      console.error(`Could not start in-memory MongoDB server: ${memErr.message}`);
      console.error('Please ensure MongoDB is running or set a valid MONGO_URI in backend/.env');
      process.exit(1);
    }
  }
};

module.exports = connectDB;

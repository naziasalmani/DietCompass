const dotenv = require('dotenv');

dotenv.config();

const geminiConfig = {
  apiKey: process.env.GEMINI_API_KEY || '',
  model: process.env.GEMINI_MODEL || 'gemini-3.6-flash',
  baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
};

module.exports = geminiConfig;

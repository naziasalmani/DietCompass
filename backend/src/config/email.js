const nodemailer = require('nodemailer');

/**
 * Create and return a configured Nodemailer transporter
 */
const createTransporter = () => {
  const host = process.env.EMAIL_HOST;
  const port = parseInt(process.env.EMAIL_PORT, 10) || 587;
  const user = process.env.EMAIL_USER;
  const pass = process.env.EMAIL_PASS;

  // Check if SMTP credentials are provided
  if (!host || !user || !pass || user.includes('your_email') || pass.includes('your_email_app_password')) {
    return null; // Signals to service that SMTP is in mock/unconfigured mode
  }

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465, // true for 465, false for 587
    auth: {
      user,
      pass,
    },
  });
};

module.exports = { createTransporter };

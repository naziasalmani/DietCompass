const { createTransporter } = require('../config/email');

/**
 * Send Password Reset Email with responsive, branded HTML template
 * @param {Object} options - { to, name, resetUrl, expiresInMinutes }
 */
const sendPasswordResetEmail = async ({ to, name, resetUrl, expiresInMinutes = 60 }) => {
  const from = process.env.EMAIL_FROM || '"DietCompass Support" <noreply@dietcompass.com>';
  const subject = 'Reset Your DietCompass Password';

  const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reset Your Password</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          background-color: #F3F0FB;
          margin: 0;
          padding: 30px 15px;
          color: #1B1B2E;
        }
        .container {
          max-width: 540px;
          margin: 0 auto;
          background: #ffffff;
          border-radius: 20px;
          overflow: hidden;
          box-shadow: 0 10px 30px rgba(108, 78, 245, 0.08);
          border: 1px solid #E8E2FA;
        }
        .header {
          background: linear-gradient(135deg, #6C4EF5 0%, #1E8A4C 100%);
          padding: 32px 24px;
          text-align: center;
          color: #ffffff;
        }
        .header h1 {
          margin: 0;
          font-size: 26px;
          font-weight: 800;
          letter-spacing: -0.5px;
        }
        .header p {
          margin: 6px 0 0 0;
          font-size: 14px;
          opacity: 0.9;
        }
        .content {
          padding: 36px 30px;
        }
        .greeting {
          font-size: 18px;
          font-weight: 700;
          color: #1B1B2E;
          margin-bottom: 12px;
        }
        .message {
          font-size: 15px;
          line-height: 1.6;
          color: #555268;
          margin-bottom: 28px;
        }
        .btn-wrapper {
          text-align: center;
          margin: 30px 0;
        }
        .btn {
          display: inline-block;
          background: linear-gradient(135deg, #6C4EF5 0%, #5B3FE0 100%);
          color: #ffffff !important;
          text-decoration: none;
          padding: 14px 34px;
          border-radius: 30px;
          font-weight: 700;
          font-size: 15px;
          box-shadow: 0 6px 18px rgba(108, 78, 245, 0.35);
        }
        .expiry-badge {
          display: block;
          text-align: center;
          font-size: 12px;
          color: #8B87A0;
          margin-top: 14px;
        }
        .divider {
          border-top: 1px solid #EDEAF7;
          margin: 28px 0;
        }
        .fallback-text {
          font-size: 12px;
          color: #8B87A0;
          word-break: break-all;
          line-height: 1.5;
        }
        .footer {
          background-color: #FAFAFD;
          padding: 20px 30px;
          text-align: center;
          font-size: 12px;
          color: #8B87A0;
          border-top: 1px solid #F0EEF8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>DietCompass</h1>
          <p>AI-Powered Nutrition Assistant</p>
        </div>
        <div class="content">
          <div class="greeting">Hello ${name || 'there'},</div>
          <div class="message">
            We received a request to reset the password for your DietCompass account.
            Click the button below to set up a new, secure password.
          </div>
          
          <div class="btn-wrapper">
            <a href="${resetUrl}" class="btn" target="_blank">Reset Password</a>
            <span class="expiry-badge">⏱️ This link will expire in <strong>${expiresInMinutes} minutes</strong>.</span>
          </div>

          <div class="divider"></div>

          <div class="fallback-text">
            If the button above doesn't work, copy and paste the following URL into your browser:<br>
            <a href="${resetUrl}" style="color: #6C4EF5;">${resetUrl}</a>
          </div>

          <div class="divider"></div>

          <div class="message" style="font-size: 13px; color: #8B87A0; margin-bottom: 0;">
            🛡️ <strong>Did not request this?</strong> You can safely ignore this email. Your current password remains secure and will not change.
          </div>
        </div>
        <div class="footer">
          &copy; ${new Date().getFullYear()} DietCompass. All rights reserved.<br>
          Making healthy eating simple and transparent.
        </div>
      </div>
    </body>
    </html>
  `;

  const text = `
Hello ${name || 'there'},

We received a request to reset your DietCompass password.

Please use the following link to reset your password (valid for ${expiresInMinutes} minutes):
${resetUrl}

If you did not request this password reset, please ignore this email.

— The DietCompass Team
  `.trim();

  const transporter = createTransporter();

  if (!transporter) {
    console.log('\n===================================================================');
    console.log(`📧 [Email Service - SMTP Not Configured / Dev Mode]`);
    console.log(`   • To:        ${to}`);
    console.log(`   • Subject:   ${subject}`);
    console.log(`   • Reset URL: ${resetUrl}`);
    console.log(`   • Note: Configure EMAIL_HOST, EMAIL_USER & EMAIL_PASS in .env to send real SMTP emails.`);
    console.log('===================================================================\n');
    return { success: true, messageId: 'mock-dev-message-id', devMode: true };
  }

  try {
    const info = await transporter.sendMail({
      from,
      to,
      subject,
      text,
      html,
    });

    console.log(`✅ [Email Sent] Message ID: ${info.messageId} to ${to}`);
    return { success: true, messageId: info.messageId, devMode: false };
  } catch (error) {
    console.error(`❌ [Email Error] Failed to send email to ${to}:`, error.message);
    throw new Error(`Email delivery failed: ${error.message}`);
  }
};

module.exports = {
  sendPasswordResetEmail,
};

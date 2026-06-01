const nodemailer = require('nodemailer');

const host = process.env.EMAIL_HOST;
const port = Number(process.env.EMAIL_PORT || 587);
const secure = process.env.EMAIL_SECURE === 'true';
const authUser = process.env.EMAIL_USER;
const authPass = process.env.EMAIL_PASS;
const fromAddress = process.env.EMAIL_FROM;

const isConfigured = !!(host && port && authUser && authPass && fromAddress);

const transporter = isConfigured
  ? nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user: authUser,
        pass: authPass,
      },
    })
  : null;

const sendEmail = async (to, subject, text) => {
  if (!isConfigured || !transporter) {
    throw new Error(
      'Email provider is not configured. Set EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS, and EMAIL_FROM.',
    );
  }

  return transporter.sendMail({
    from: fromAddress,
    to,
    subject,
    text,
  });
};

module.exports = {
  isConfigured,
  sendEmail,
};
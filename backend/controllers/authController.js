const { poolPromise } = require('../config/db');
const dns = require('dns').promises;
const bcrypt = require('bcrypt');
const emailService = require('../services/emailService');

// SIGNUP
exports.signup = async (req, res) => {
  try {
    const { full_name, contact_number, email, password, role } = req.body;

    // Basic email domain validation (ensure domain can receive mail)
    if (email) {
      try {
        const domain = email.split('@').pop();
        const mx = await dns.resolveMx(domain);
        if (!mx || mx.length === 0) {
          // fallback to A record lookup
          await dns.resolve4(domain);
        }
      } catch (err) {
        return res.status(400).json({ message: 'Email domain cannot receive mail or is invalid' });
      }
    }

    const pool = await poolPromise;

    const checkUser = await pool.request()
      .input('contact_number', contact_number)
      .input('email', email)
      .query(`SELECT * FROM users WHERE contact_number = @contact_number OR email = @email`);

    if (checkUser.recordset.length > 0) {
      return res.status(400).json({
        message: "A user already exists with this phone number or email"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Step 1: insert the new user
    await pool.request()
      .input('full_name', full_name)
      .input('contact_number', contact_number)
      .input('email', email)
      .input('password', hashedPassword)
      .input('role', role)
      .query(`
        INSERT INTO users (full_name, contact_number, email, password, role, profile_picture, avg_rating)
        VALUES (@full_name, @contact_number, @email, @password, @role, '', 0.0)
      `);

    // Step 2: get the new row's id (MySQL equivalent of SCOPE_IDENTITY)
    const idResult = await pool.request()
      .query(`SELECT LAST_INSERT_ID() AS id`);

    return res.json({
      message: "User created successfully",
      userId: idResult.recordset[0].id,
      role: role
    });

  } catch (err) {
    return res.status(500).json({
      message: "Signup failed",
      error: "Something went wrong. Please try again."
    });
  }
};

exports.checkEmailExists = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const pool = await poolPromise;
    const result = await pool.request()
      .input('email', email)
      .query(`SELECT id FROM users WHERE email = @email`);

    const exists = result.recordset.length > 0;
    return res.json({ exists });
  } catch (err) {
    return res.status(500).json({
      message: "Email check failed",
      error: "Something went wrong. Please try again."
    });
  }
};

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

// REQUEST PASSWORD RESET OTP
exports.requestPasswordReset = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const pool = await poolPromise;
    const result = await pool.request()
      .input('email', email)
      .query(`SELECT * FROM users WHERE email = @email`);

    const user = result.recordset[0];
    if (!user) {
      return res.status(400).json({ message: "User does not exist" });
    }

    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await pool.request()
      .input('otp', otp)
      .input('expiresAt', expiresAt)
      .input('email', email)
      .query(`
        UPDATE users
        SET password_reset_code = @otp,
            password_reset_expires_at = @expiresAt,
            password_reset_used = 0
        WHERE email = @email
      `);

    const message = `Your Helpr password reset code is ${otp}. It expires in 10 minutes.`;
    if (emailService.isConfigured) {
      await emailService.sendEmail(email, 'Helpr password reset code', message);
      return res.json({ message: "OTP sent via email. Use it to reset your password." });
    }

    return res.json({
      message: "OTP generated successfully. Use it to reset your password.",
      otp,
    });
  } catch (err) {
    return res.status(500).json({
      message: "OTP generation failed",
      error: "Something went wrong. Please try again."
    });
  }
};

// CONFIRM PASSWORD RESET WITH OTP
exports.confirmPasswordReset = async (req, res) => {
  try {
    const { email, otp_code, password } = req.body;

    if (!email || !otp_code || !password) {
      return res.status(400).json({ message: "Email, OTP code and new password are required" });
    }

    const pool = await poolPromise;
    const result = await pool.request()
      .input('email', email)
      .input('otp_code', otp_code)
      .query(`SELECT * FROM users WHERE email = @email AND password_reset_code = @otp_code`);

    const user = result.recordset[0];
    if (!user) {
      return res.status(400).json({ message: "Invalid OTP code or email" });
    }

    if (user.password_reset_used) {
      return res.status(400).json({ message: "This OTP has already been used. Request a new one." });
    }

    const expiresAt = new Date(user.password_reset_expires_at);
    if (expiresAt < new Date()) {
      return res.status(400).json({ message: "OTP has expired. Please request a new one." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.request()
      .input('hashedPassword', hashedPassword)
      .input('email', email)
      .query(`
        UPDATE users
        SET password = @hashedPassword,
            password_reset_used = 1
        WHERE email = @email
      `);

    return res.json({ message: "Password reset successful. Please log in with your new password." });
  } catch (err) {
    return res.status(500).json({
      message: "Password reset failed",
      error: "Something went wrong. Please try again."
    });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    const { contact_number, password } = req.body;

    const pool = await poolPromise;

    const result = await pool.request()
      .input('contact_number', contact_number)
      .query(`SELECT * FROM users WHERE contact_number = @contact_number`);

    const user = result.recordset[0];

    if (!user) {
      return res.status(400).json({ message: "User does not exist" });
    }

    let isMatch = false;
    if (user.password && user.password.startsWith("$2b$")) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = (password === user.password);
    }

    if (!isMatch) {
      return res.status(400).json({ message: "Incorrect password" });
    }

    // Upgrade plain text password to hashed on next login
    if (user.password && !user.password.startsWith("$2b$")) {
      const hashedPassword = await bcrypt.hash(password, 10);
      await pool.request()
        .input('hashedPassword', hashedPassword)
        .input('contact_number', contact_number)
        .query(`UPDATE users SET password = @hashedPassword WHERE contact_number = @contact_number`);
    }

    res.json({
      message: "Login successful",
      user: {
        id:   user.id,
        name: user.full_name,
        role: user.role
      }
    });

  } catch (err) {
    res.status(500).json({ message: "Login failed", error: "Server error" });
  }
};
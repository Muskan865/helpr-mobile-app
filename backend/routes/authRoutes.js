const express = require('express');
const router = express.Router();

const {
  signup,
  login,
  requestPasswordReset,
  confirmPasswordReset
} = require('../controllers/authController');

router.post('/signup', signup);
router.post('/login', login);
router.post('/request-password-reset', requestPasswordReset);
router.post('/confirm-password-reset', confirmPasswordReset);

module.exports = router;
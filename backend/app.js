const express = require('express');
const cors = require('cors');

const workerRoutes = require('./routes/workerRoutes');
const chatRoutes = require('./routes/chatRoutes');
const requesterRoutes = require('./routes/requesterRoutes');
const profileRoutes = require('./routes/profileRoutes');
const profileCompletionRoutes = require('./routes/profileCompletionRoutes');

const app = express();

app.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Helpr API is running'
  });
});

// Logger middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url} - Origin: ${req.headers.origin}`);
  next();
});

// CORS 
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());

// Routes
app.use('/api/profile', profileRoutes);
app.use('/api/profile-completion', profileCompletionRoutes);
app.use('/api/worker', workerRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/requester', requesterRoutes);

module.exports = app;
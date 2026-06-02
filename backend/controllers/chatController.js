

const { poolPromise } = require('../config/db');

exports.getMessages = async (req, res) => {
  try {
    const { jobId } = req.params;
    const pool = await poolPromise;

    const result = await pool.request()
      .input('jobId', jobId)
      .query(`
        SELECT id, job_id, sender_id, content, sent_at
        FROM message
        WHERE job_id = @jobId
        ORDER BY id ASC
      `);

    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching messages');
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { jobId, senderId, content } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input('jobId', jobId)
      .input('senderId', senderId)
      .input('content', content)
      .query(`
        INSERT INTO message (job_id, sender_id, content, sent_at)
        VALUES (@jobId, @senderId, @content, NOW())
      `);

    res.json({ success: true, message: 'Message sent' });
  } catch (err) {
    console.error(err);
    res.status(500).send('Error sending message');
  }
};
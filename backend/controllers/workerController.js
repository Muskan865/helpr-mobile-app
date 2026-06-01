const { poolPromise } = require("../config/db");

// Validate worker exists by users.id (worker.user_id)
async function ensureWorkerExists(pool, userId) {
  const workerRow = await pool.request()
    .input("userId", userId)
    .query("SELECT id, user_id FROM worker WHERE user_id = @userId");

  if (workerRow.recordset.length === 0) {
    throw new Error("Worker not found");
  }

  return workerRow.recordset[0];
}

// ===================== GET WORKER JOBS =====================
exports.getWorkerJobs = async (req, res) => {
  try {
    const userId = parseInt(req.params.id, 10);
    const pool = await poolPromise;
    const workerRecord = await ensureWorkerExists(pool, userId);

    const result = await pool.request()
      .input("workerUserId", userId)
      .input("workerTableId", workerRecord.id)
      .query(`
        SELECT
          j.id,
          j.request_id,
          j.worker_id,
          j.status,
          sr.service_type,
          sr.description,
          sr.location,
          sr.date,
          sr.time,
          u.full_name AS client_name,
          u.id AS client_id,
          b.bid_amount
        FROM job j
        JOIN service_request sr ON j.request_id = sr.id
        JOIN users u ON sr.requester_id = u.id
        LEFT JOIN bid b
          ON b.request_id = j.request_id
         AND b.worker_id = j.worker_id
         AND b.status = 'accepted'
        WHERE j.worker_id = @workerUserId OR j.worker_id = @workerTableId
        ORDER BY j.id DESC
      `);

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== GET WORKER BIDS =====================
exports.getWorkerBids = async (req, res) => {
  try {
    const userId = parseInt(req.params.id, 10);
    const pool = await poolPromise;
    const workerRecord = await ensureWorkerExists(pool, userId);

    const result = await pool.request()
      .input("workerUserId", userId)
      .input("workerTableId", workerRecord.id)
      .query(`
        SELECT
          b.id AS bid_id,
          b.request_id,
          b.worker_id,
          b.bid_amount,
          b.status AS bid_status,
          r.requester_id,
          r.service_type,
          r.description,
          r.date,
          r.time,
          r.location
        FROM bid b
        JOIN service_request r ON b.request_id = r.id
        WHERE (b.worker_id = @workerUserId OR b.worker_id = @workerTableId)
          AND NOT EXISTS (
            SELECT 1
            FROM job j
            WHERE j.request_id = b.request_id
              AND j.worker_id = b.worker_id
              AND LOWER(j.status) = 'completed'
          )
        ORDER BY b.id DESC
      `);

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== GET WORKER PROFILE =====================
exports.getWorkerProfile = async (req, res) => {
  try {
    const userId = req.params.id;
    const pool = await poolPromise;

    const result = await pool.request()
      .input("userId", userId)
      .query(`
        SELECT u.full_name, u.avg_rating, w.profession, w.skills, w.experience_years
        FROM worker w
        JOIN users u ON w.user_id = u.id
        WHERE w.user_id = @userId
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ message: "Worker not found" });
    }

    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== GET ALL REQUESTS =====================
exports.getAllRequests = async (req, res) => {
  try {
    const pool = await poolPromise;

    const result = await pool.request().query(`
      SELECT * FROM service_request r WHERE r.status = 'open'
    `);

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== GET MATCHING REQUESTS =====================
exports.getMatchingRequests = async (req, res) => {
  try {
    const userId = parseInt(req.params.id, 10);
    const pool = await poolPromise;
    const workerRecord = await ensureWorkerExists(pool, userId);

    const workerResult = await pool.request()
      .input("workerUserId", userId)
      .query("SELECT profession, skills FROM worker WHERE user_id = @workerUserId");

    if (workerResult.recordset.length === 0) {
      return res.status(404).json({ error: "Worker not found" });
    }

    const worker = workerResult.recordset[0];
    if (!worker.profession || !worker.skills) {
      return res.status(400).json({ error: "Worker profile incomplete" });
    }

    const profession = worker.profession.toLowerCase();
    const skills = worker.skills.toLowerCase().split(",").map((s) => s.trim());

    const requestsResult = await pool.request()
      .input("workerUserId", userId)
      .input("workerTableId", workerRecord.id)
      .query(`
        SELECT * FROM service_request r
        WHERE r.status = 'open'
          AND NOT EXISTS (
            SELECT 1
            FROM bid b
            WHERE b.request_id = r.id
              AND (b.worker_id = @workerUserId OR b.worker_id = @workerTableId)
          )
      `);

    const matchingRequests = requestsResult.recordset.filter((request) => {
      const serviceType = (request.service_type || "").toLowerCase();
      return (
        serviceType.includes(profession) ||
        skills.some((skill) => skill && serviceType.includes(skill))
      );
    });

    res.json(matchingRequests);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== CREATE / UPDATE WORKER PROFILE =====================
exports.createWorkerProfile = async (req, res) => {
  try {
    const { user_id, profession, skills, experience_years } = req.body;
    const pool = await poolPromise;

    const existing = await pool.request()
      .input("user_id", user_id)
      .query("SELECT * FROM worker WHERE user_id = @user_id");

    if (existing.recordset.length > 0) {
      await pool.request()
        .input("user_id", user_id)
        .input("profession", profession)
        .input("skills", skills)
        .input("experience_years", experience_years)
        .query(`
          UPDATE worker
          SET profession = @profession,
              skills = @skills,
              experience_years = @experience_years
          WHERE user_id = @user_id
        `);
      return res.json({ message: "Profile updated successfully" });
    }

    await pool.request()
      .input("user_id", user_id)
      .input("profession", profession)
      .input("skills", skills)
      .input("experience_years", experience_years)
      .query(`
        INSERT INTO worker (user_id, profession, skills, experience_years)
        VALUES (@user_id, @profession, @skills, @experience_years)
      `);

    res.json({ message: "Profile created successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== PLACE BID =====================
exports.placeBid = async (req, res) => {
  try {
    const userId = parseInt(req.params.id, 10);
    const pool = await poolPromise;
    const workerRecord = await ensureWorkerExists(pool, userId);

    const { request_id, bid_amount, bid_date, bid_time, status } = req.body;

    await pool.request()
      .input("request_id", request_id)
      .input("worker_id", workerRecord.id)
      .input("bid_amount", bid_amount)
      .input("bid_date", bid_date)
      .input("bid_time", bid_time)
      .input("status", status)
      .query(`
        INSERT INTO bid (request_id, worker_id, bid_amount, bid_date, bid_time, status)
        VALUES (@request_id, @worker_id, @bid_amount, @bid_date, @bid_time, @status)
      `);

    res.json({ success: true, message: "Bid placed successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== CANCEL BID =====================
exports.cancelBid = async (req, res) => {
  try {
    const bidId = req.params.id;
    const pool = await poolPromise;

    const check = await pool.request()
      .input("bidId", bidId)
      .query("SELECT status FROM bid WHERE id = @bidId");

    if (check.recordset.length === 0) {
      return res.status(404).json({ message: "Bid not found" });
    }

    if (check.recordset[0].status !== "pending") {
      return res.status(400).json({ message: "Only pending bids can be cancelled" });
    }

    await pool.request()
      .input("bidId", bidId)
      .query("DELETE FROM bid WHERE id = @bidId");

    return res.json({ message: "Bid cancelled successfully" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

// ===================== UPDATE JOB STATUS =====================
exports.updateJobStatus = async (req, res) => {
  try {
    const jobId = req.params.id;
    const { status } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("jobId", jobId)
      .input("status", status)
      .query("UPDATE job SET status = @status WHERE id = @jobId");

    res.json({ message: "Status updated" });
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

// ===================== SUBMIT REVIEW =====================
exports.submitReview = async (req, res) => {
  try {
    const { reviewer_id, reviewee_id, rating, comment } = req.body;
    const pool = await poolPromise;

    await pool.request()
      .input("reviewer_id", reviewer_id)
      .input("reviewee_id", reviewee_id)
      .input("rating", rating)
      .input("comment", comment)
      .query(`
        INSERT INTO rating_review (reviewer_id, reviewee_id, rating, comment)
        VALUES (@reviewer_id, @reviewee_id, @rating, @comment)
      `);

    await pool.request()
      .input("reviewee_id", reviewee_id)
      .query(`
        UPDATE users
        SET avg_rating = (
          SELECT AVG(CAST(rating AS FLOAT))
          FROM rating_review
          WHERE reviewee_id = @reviewee_id
        )
        WHERE id = @reviewee_id
      `);

    res.json({ message: "Review submitted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ===================== GET WORKER RATINGS =====================
exports.getWorkerRatings = async (req, res) => {
  try {
    const userId = req.params.id;
    const pool = await poolPromise;

    const result = await pool.request()
      .input("userId", userId)
      .query(`
        SELECT rr.id, rr.rating, rr.comment, u.full_name AS reviewer_name
        FROM rating_review rr
        JOIN users u ON rr.reviewer_id = u.id
        WHERE rr.reviewee_id = @userId
        ORDER BY rr.id DESC
      `);

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

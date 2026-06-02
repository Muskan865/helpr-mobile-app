
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  port:     parseInt(process.env.DB_PORT || '3306', 10),
  waitForConnections: true,
  connectionLimit: 10,
  decimalNumbers: true,   
});

pool.getConnection()
  .then(conn => { console.log('Connected to DB ✅'); conn.release(); })
  .catch(err  => { console.log('DB Connection Failed ❌', err.message); });

function makeRequest() {
  const params = {};   // { name: value }

  const req = {
    input(name, typeOrValue, value) {
      params[name] = (value !== undefined) ? value : typeOrValue;
      return req;   // chainable
    },

    async query(sqlText) {
      const values = [];
      const converted = sqlText.replace(/@(\w+)/g, (_, name) => {
        if (!(name in params)) {
          throw new Error(`mysql-shim: param @${name} was used in query but never .input()'d`);
        }
        values.push(params[name]);
        return '?';
      });

      const mysqlSql = converted
        .replace(/SELECT\s+SCOPE_IDENTITY\(\)\s+AS\s+\w+/gi, 'SELECT LAST_INSERT_ID() AS id')
        .replace(/GETDATE\(\)/gi, 'NOW()')
        // INSERT ... ; SELECT LAST_INSERT_ID() — keep as two statements via multipleStatements
        ;

      const [rows] = await pool.execute(mysqlSql, values);

      if (Array.isArray(rows) && Array.isArray(rows[0])) {
        const last = rows[rows.length - 1];
        return { recordset: last };
      }

      if (Array.isArray(rows)) {
        return { recordset: rows };
      }

      return { recordset: [], rowsAffected: rows.affectedRows };
    }
  };

  return req;
}

const poolPromise = Promise.resolve({ request: makeRequest });


const sql = new Proxy({}, {
  get: () => null,         
});

module.exports = { pool, poolPromise, sql };
// Conexión a SQL Server mediante el driver mssql
const sql = require('mssql');

const config = {
  server:   process.env.DB_SERVER   || 'localhost',
  database: process.env.DB_NAME     || 'securebank',
  user:     process.env.DB_USER     || 'sa',
  password: process.env.DB_PASSWORD || 'Your_strong_password1',
  port:     parseInt(process.env.DB_PORT || '1433', 10),
  options: {
    encrypt: true,                 // requerido por SQL Server moderno
    trustServerCertificate: true,  // laboratorio local (certificado autofirmado)
  },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

let poolPromise;
function getPool() {
  if (!poolPromise) {
    poolPromise = sql.connect(config)
      .then((pool) => { console.log('✔ Conectado a SQL Server'); return pool; })
      .catch((err) => { poolPromise = null; throw err; });
  }
  return poolPromise;
}

module.exports = { sql, getPool };

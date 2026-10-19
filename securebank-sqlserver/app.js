/* ============================================================
   SecureBank-v8 (SQL Server) - API de laboratorio
   Reproduce la superficie de ataque descrita en la guía:
   - Login con sesión (cookie connect.sid)
   - Buscador de transacciones (endpoint vulnerable)
   - Variante remediada para pruebas de regresión
   Entorno LOCAL. Vulnerable a propósito. NO producción.
   ============================================================ */
const express = require('express');
const session = require('express-session');
const { sql, getPool } = require('./db');

const app = express();
app.disable('x-powered-by');   // SonarQube S5689: evita filtrar el framework/versión (CWE-200)
app.use(express.json());
app.use(session({
  secret: 'lab-secret-no-produccion',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true },   // connect.sid
}));

// --- Middleware: exige sesión iniciada ---
function requireAuth(req, res, next) {
  if (!req.session.userId) return res.status(401).json({ error: 'No autenticado' });
  next();
}

// --- Login lícito ---
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    const pool = await getPool();
    const r = await pool.request()
      .input('u', sql.NVarChar, username)
      .input('p', sql.NVarChar, password)
      .query('SELECT id, full_name FROM dbo.users WHERE username = @u AND password = @p');
    if (r.recordset.length === 0) return res.status(401).json({ error: 'Credenciales inválidas' });
    req.session.userId = r.recordset[0].id;
    res.json({ ok: true, user: r.recordset[0].full_name, userId: r.recordset[0].id });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// --- FASES I y II: buscador VULNERABLE ---
// La consulta se arma concatenando el input del usuario en JS (sin parámetros).
// -> SonarLint lo marca como SQL Injection (regla S3649, CWE-89) = evidencia Fase I.
// -> Es explotable en tiempo de ejecución con OWASP ZAP = Fase II.
app.post('/api/transactions/search', requireAuth, async (req, res) => {
  const { term } = req.body;
  try {
    const pool = await getPool();
    const query =
      "SELECT * FROM dbo.transactions WHERE user_id = " + req.session.userId +
      " AND description LIKE '%" + term + "%'";   // VULNERABLE: concatenación directa
    const r = await pool.request().query(query);
    res.json({ results: r.recordset });
  } catch (e) {
    // Error-based (CWE-209): se expone el error crudo del backend a propósito
    res.status(500).json({ error: e.message });
  }
});

// --- FASE III: mismo buscador, versión REMEDIADA (regresión) ---
app.post('/api/transactions/search-secure', requireAuth, async (req, res) => {
  const { term } = req.body;
  try {
    const pool = await getPool();
    const r = await pool.request()
      .input('user_id', sql.Int, req.session.userId)
      .input('search_term', sql.NVarChar, term)
      .execute('dbo.get_transactions_by_desc_secure');  // SP seguro
    res.json({ results: r.recordset });
  } catch (e) {
    console.error('Error en búsqueda segura:', e);   // SonarQube S2486: se registra en el servidor
    res.status(500).json({ error: 'Error procesando la solicitud' }); // sin fuga de detalle al cliente
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`SecureBank escuchando en http://localhost:${PORT}`));

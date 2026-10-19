# SecureBank-v8 — versión SQL Server (laboratorio Sesión 8)

App fintech **deliberadamente vulnerable** para practicar el ciclo S-SDLC de la guía:
SAST (SonarLint) → DAST (OWASP ZAP) → remediación en T-SQL. **Entorno 100% local y controlado. No usar en producción ni contra sistemas de terceros.**

## Requisitos
- SQL Server 2022 (Developer/Express) + SSMS o Azure Data Studio
- Node.js LTS
- VS Code + SonarLint
- OWASP ZAP 2.14+

## Montaje (orden exacto)

### 1) Base de datos
Ejecuta los scripts en orden, con SSMS o con `sqlcmd`:
```bash
sqlcmd -S localhost -U sa -P "Your_strong_password1" -C -i sql/01_schema.sql
sqlcmd -S localhost -U sa -P "Your_strong_password1" -C -i sql/02_seed.sql
sqlcmd -S localhost -U sa -P "Your_strong_password1" -C -i sql/03_vulnerable_procedures.sql
```
> `04_secure_procedures.sql` y `05_trigger_sanitize.sql` se ejecutan en la **Fase III** (remediación).

### 2) Aplicación
```bash
cp .env.example .env     # ajusta tus credenciales
npm install
npm start                # http://localhost:3000
```

## Uso rápido (para la Fase II)
```bash
# 1. Login (guarda la cookie de sesión)
curl -i -c cookie.txt -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"cliente1","password":"Password123"}'

# 2. Búsqueda legítima
curl -b cookie.txt -X POST http://localhost:3000/api/transactions/search \
  -H "Content-Type: application/json" -d '{"term":"Pago"}'
```
En OWASP ZAP interceptas ese mismo `POST /api/transactions/search` y pruebas:
- **Error-based (CWE-209):** `term` con una comilla simple → el endpoint devuelve el error crudo de SQL Server.
- **Boolean-blind / bypass (CWE-89):** `{"term": "%' OR 1=1--"}` → aparecen transacciones de **cliente2** (user_id=2) aunque estás logueado como **cliente1**.

## Remediación (Fase III)
El endpoint vulnerable arma la consulta concatenando en JS (`.query(...)`). La versión
remediada usa parámetros tipados y el procedimiento seguro con `sp_executesql`.
1. Ejecuta `sql/04_secure_procedures.sql` y `sql/05_trigger_sanitize.sql`.
2. Usa el endpoint ya incluido `/api/transactions/search-secure`, que llama al SP
   parametrizado `dbo.get_transactions_by_desc_secure` con `.input().execute()`.
3. **Regresión:** repite los payloads anteriores contra `/api/transactions/search-secure`
   → el `OR 1=1--` ya no devuelve datos ajenos y no se filtra el error.

## Mapa de archivos
| Archivo | Fase | Qué contiene |
|---|---|---|
| `sql/01_schema.sql` | 0 | Tablas `users`, `transactions`, `audit_logs` |
| `sql/02_seed.sql` | 0 | 2 usuarios + 5 transacciones |
| `sql/03_vulnerable_procedures.sql` | I/II | SP vulnerable (`EXEC` concatenado, `EXECUTE AS OWNER`) |
| `sql/04_secure_procedures.sql` | III | SP seguro (`sp_executesql`, `EXECUTE AS CALLER`) |
| `sql/05_trigger_sanitize.sql` | III | Trigger `INSTEAD OF INSERT` anti-SQLi de 2º orden |
| `app.js` | II/III | API con endpoints vulnerable y remediado |

## Nota sobre `EXECUTE AS OWNER`
Demuestra la escalación de privilegios (CWE-250). Si al crear el SP vulnerable obtienes un error de permisos, ejecuta como administrador:
```sql
ALTER DATABASE securebank SET TRUSTWORTHY ON;
```
La inyección SQL en sí se reproduce igual aunque uses `CALLER`; `OWNER` solo eleva la *severidad* del impacto.

## Matriz OWASP WSTG v4.2 (para el informe)
| Componente | CWE | Remediación | WSTG v4.2 |
|---|---|---|---|
| Buscador de transacciones | CWE-89 (1er orden) | `sp_executesql` parametrizado | WSTG-INPV-05 |
| Auditoría de logs (trigger) | CWE-89 (2º orden) | Validación + `THROW` en `INSTEAD OF INSERT` | WSTG-BUSL-02 |
| Ejecución de procedimientos | CWE-250 | `EXECUTE AS OWNER` → `CALLER` | WSTG-ATHZ-02 |

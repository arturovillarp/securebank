/* ============================================================
   SecureBank-v8 (SQL Server) - Esquema
   Laboratorio académico - Seguridad en Aplicaciones Software
   Entorno LOCAL y controlado. NO usar en producción.
   ============================================================ */

IF DB_ID('securebank') IS NULL
    CREATE DATABASE securebank;
GO

USE securebank;
GO

/* Limpieza idempotente (permite re-ejecutar el script) */
IF OBJECT_ID('dbo.audit_logs', 'U')  IS NOT NULL DROP TABLE dbo.audit_logs;
IF OBJECT_ID('dbo.transactions','U') IS NOT NULL DROP TABLE dbo.transactions;
IF OBJECT_ID('dbo.users','U')        IS NOT NULL DROP TABLE dbo.users;
GO

CREATE TABLE dbo.users (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    username      NVARCHAR(50)  NOT NULL UNIQUE,
    password      NVARCHAR(100) NOT NULL,        -- texto plano SOLO para el laboratorio
    full_name     NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.transactions (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    user_id       INT NOT NULL REFERENCES dbo.users(id),
    amount        DECIMAL(12,2) NOT NULL,
    description   NVARCHAR(255) NOT NULL,
    created_at    DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.audit_logs (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    user_id       INT NULL,
    detail        NVARCHAR(500) NOT NULL,
    created_at    DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

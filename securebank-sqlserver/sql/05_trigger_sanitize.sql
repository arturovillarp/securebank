/* ============================================================
   FASE III - Mitigación de SQLi de Segundo Orden (Stored SQLi)
   SQL Server no tiene triggers BEFORE: se usa INSTEAD OF INSERT
   para validar ANTES de persistir en audit_logs.
   ============================================================ */
USE securebank;
GO

IF OBJECT_ID('dbo.trg_sanitize_logs','TR') IS NOT NULL
    DROP TRIGGER dbo.trg_sanitize_logs;
GO

CREATE TRIGGER dbo.trg_sanitize_logs
ON dbo.audit_logs
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    /* Bloquea metacaracteres típicos de inyección en texto libre */
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE detail LIKE '%''%'   -- comilla simple
           OR detail LIKE '%--%'   -- comentario de línea
           OR detail LIKE '%;%'    -- separador de sentencias
           OR detail LIKE '%/*%'   -- comentario de bloque
    )
    BEGIN
        THROW 50000, 'Entrada rechazada: metacaracteres no permitidos.', 1;
        RETURN;
    END;

    /* Entrada limpia -> persiste normalmente */
    INSERT INTO dbo.audit_logs (user_id, detail, created_at)
    SELECT user_id, detail, ISNULL(created_at, SYSDATETIME())
    FROM inserted;
END;
GO

PRINT 'Trigger INSTEAD OF INSERT creado: dbo.trg_sanitize_logs';
GO

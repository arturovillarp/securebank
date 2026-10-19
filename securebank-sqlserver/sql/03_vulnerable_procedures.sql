/* ============================================================
   FASE I/II - Lógica VULNERABLE (para auditar con SonarLint/ZAP)
   Equivalente T-SQL de la función PL/pgSQL de la guía.
   >>> Vulnerable a propósito. Solo laboratorio local. <<<
   ============================================================ */
USE securebank;
GO

IF OBJECT_ID('dbo.get_transactions_by_desc','P') IS NOT NULL
    DROP PROCEDURE dbo.get_transactions_by_desc;
GO

CREATE PROCEDURE dbo.get_transactions_by_desc
    @user_id     INT,
    @search_term NVARCHAR(255)
WITH EXECUTE AS OWNER       -- ⚠ CWE-250: corre con privilegios del dueño (dbo)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @q NVARCHAR(MAX);

    /* VULNERABILIDAD CRÍTICA (CWE-89):
       concatenación directa del input dentro del SQL dinámico. */
    SET @q = N'SELECT * FROM dbo.transactions WHERE user_id = '
           + CAST(@user_id AS NVARCHAR(20))
           + N' AND description LIKE ''' + @search_term + N'''';

    EXEC (@q);   -- ejecuta la cadena armada dinámicamente
END;
GO

PRINT 'Procedimiento VULNERABLE creado: dbo.get_transactions_by_desc';
GO

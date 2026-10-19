/* ============================================================
   FASE III - Remediación: procedimiento SEGURO (T-SQL)
   - Parametrización con sp_executesql (equivale a USING).
   - EXECUTE AS CALLER (mínimo privilegio) vs OWNER.
   ============================================================ */
USE securebank;
GO

IF OBJECT_ID('dbo.get_transactions_by_desc_secure','P') IS NOT NULL
    DROP PROCEDURE dbo.get_transactions_by_desc_secure;
GO

CREATE PROCEDURE dbo.get_transactions_by_desc_secure
    @user_id     INT,
    @search_term NVARCHAR(255)
WITH EXECUTE AS CALLER      -- ✔ CWE-250 mitigado: permisos del invocador
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @q NVARCHAR(MAX) =
        N'SELECT * FROM dbo.transactions
          WHERE user_id = @uid AND description LIKE @term';

    /* REMEDIACIÓN (CWE-89): parámetros tipados, el input es DATO, no SQL */
    EXEC sys.sp_executesql
        @q,
        N'@uid INT, @term NVARCHAR(255)',
        @uid  = @user_id,
        @term = @search_term;
END;
GO

PRINT 'Procedimiento SEGURO creado: dbo.get_transactions_by_desc_secure';
GO

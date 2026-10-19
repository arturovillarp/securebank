/* ============================================================
   SecureBank-v8 (SQL Server) - Datos de prueba
   Dos clientes distintos: permite demostrar el bypass de
   autorización (ver transacciones de OTRO usuario).
   ============================================================ */
USE securebank;
GO

INSERT INTO dbo.users (username, password, full_name) VALUES
    (N'cliente1', N'Password123', N'Ana Torres'),
    (N'cliente2', N'Password123', N'Luis Ramírez');
GO

/* Transacciones de cliente1 (user_id = 1) */
INSERT INTO dbo.transactions (user_id, amount, description) VALUES
    (1,  -150.00, N'Pago de servicios'),
    (1,  2500.00, N'Abono de sueldo'),
    (1,   -45.90, N'Pago tarjeta');

/* Transacciones de cliente2 (user_id = 2) - NO deberían verse desde cliente1 */
INSERT INTO dbo.transactions (user_id, amount, description) VALUES
    (2,  9999.00, N'Pago confidencial cliente2'),
    (2, -1200.00, N'Transferencia cliente2');
GO

PRINT 'Seed cargado: 2 usuarios, 5 transacciones.';
GO

/* SSMS normal: execute com F5. Não habilite Modo SQLCMD.
Servidor desta máquina: NOTE-GSV (ou localhost), autenticação Windows.
Este arquivo somente consulta dados: não instala nem reprocessa nada.
*/
USE [DataNexoERP_Lab];
GO
SELECT @@SERVERNAME AS Servidor, DB_NAME() AS BancoAtual;
SELECT COUNT(*) AS LinhasBrutas FROM raw.Vendas;
SELECT TOP (10) * FROM raw.Vendas ORDER BY LinhaId;
SELECT TOP (10) * FROM bi.FatoVendas ORDER BY DataVenda,VendaId,Item;
SELECT SUM(ReceitaLiquida) AS Faturamento FROM bi.FatoVendas;

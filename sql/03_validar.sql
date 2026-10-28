USE DataNexoERP_Lab;
GO
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM raw.Vendas)<>1210 THROW 51100,'Quantidade bruta inesperada para a carga original.',1;
IF (SELECT COUNT(*) FROM erp.ItemVenda)<>1200 THROW 51101,'Esperados 1200 itens aceitos.',1;
IF (SELECT COUNT(*) FROM erp.Venda)<>600 THROW 51102,'Esperadas 600 vendas.',1;
IF (SELECT COUNT(*) FROM erp.Cliente)<>120 THROW 51103,'Esperados 120 clientes.',1;
IF (SELECT COUNT(*) FROM erp.Produto)<>30 THROW 51104,'Esperados 30 produtos.',1;
IF (SELECT COUNT(*) FROM erp.ItemCompra)<>90 THROW 51105,'Esperados 90 itens de compra.',1;
IF (SELECT COUNT(*) FROM bi.Calendario)<>365 THROW 51106,'Calendário incompleto.',1;
DECLARE @E int=(SELECT MAX(ExecucaoId) FROM audit.Execucao);
IF (SELECT COUNT(*) FROM audit.Rejeicao WHERE ExecucaoId=@E)<>10 THROW 51107,'Esperadas 10 rejeições.',1;
IF EXISTS(SELECT 1 FROM audit.Execucao WHERE ExecucaoId=@E AND Brutos<>Aceitos+Rejeitados)
 THROW 51108,'Brutos não conciliam com aceitos + rejeitados.',1;
IF EXISTS(SELECT 1 FROM raw.Vendas r WHERE NOT EXISTS(SELECT 1 FROM audit.Rejeicao a WHERE a.ExecucaoId=@E AND a.LinhaId=r.LinhaId)
 AND NOT EXISTS(SELECT 1 FROM stg.VendasTipadas s JOIN erp.ItemVenda i ON i.VendaId=s.VendaId AND i.Item=s.Item WHERE s.LinhaId=r.LinhaId))
 THROW 51109,'Linha bruta sem destino.',1;
IF (SELECT SUM(ReceitaLiquida) FROM bi.FatoVendas)<>(SELECT SUM(Valor) FROM erp.ContaReceber)
 THROW 51110,'Faturamento difere dos títulos.',1;
IF (SELECT SUM(Valor) FROM erp.ContaReceber)<>(SELECT SUM(Recebido+Saldo) FROM bi.ContasReceber)
 THROW 51111,'Recebíveis não conciliam.',1;
IF EXISTS(SELECT 1 FROM bi.ContasReceber WHERE Saldo<0) THROW 51112,'Pagamento maior que o título.',1;
IF (SELECT SUM(Quantidade) FROM erp.MovimentoEstoque WHERE Tipo='VENDA')<>-(SELECT SUM(Quantidade) FROM erp.ItemVenda)
 THROW 51113,'Saídas diferem das vendas.',1;
IF (SELECT SUM(Quantidade) FROM erp.MovimentoEstoque WHERE Tipo='COMPRA')<>(SELECT SUM(Quantidade) FROM erp.ItemCompra)
 THROW 51114,'Entradas diferem das compras.',1;
IF EXISTS(SELECT 1 FROM bi.Estoque WHERE SaldoQuantidade<0) THROW 51115,'Estoque final negativo.',1;
IF EXISTS(SELECT 1 FROM (
 SELECT SUM(Quantidade) OVER(PARTITION BY ProdutoId ORDER BY DataMovimento,
 CASE Tipo WHEN 'ABERTURA' THEN 0 WHEN 'COMPRA' THEN 1 ELSE 2 END,MovimentoId ROWS UNBOUNDED PRECEDING) Saldo
 FROM erp.MovimentoEstoque) e WHERE Saldo<0) THROW 51116,'Estoque histórico negativo.',1;
IF EXISTS(SELECT 1 FROM erp.Recebimento r JOIN erp.ContaReceber c ON c.ContaId=r.ContaId JOIN erp.Venda v ON v.VendaId=c.VendaId WHERE r.DataRecebimento<v.DataVenda OR r.DataRecebimento>'20261028')
 THROW 51117,'Data de recebimento inconsistente.',1;
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
SELECT N'PASSOU: contagens, rejeições, conciliação financeira e estoque' Resultado,
 (SELECT SUM(ReceitaLiquida) FROM bi.FatoVendas) Receita,
 (SELECT SUM(Recebido) FROM bi.ContasReceber) Recebido,
 (SELECT SUM(Saldo) FROM bi.ContasReceber) Saldo;

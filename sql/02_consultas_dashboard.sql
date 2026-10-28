USE DataNexoERP_Lab;
GO
-- 1. Inspecionar bruto, interpretação e rejeições. Nenhum dado bruto é apagado.
SELECT TOP(20) * FROM raw.Vendas ORDER BY LinhaId DESC;
SELECT TOP(20) * FROM stg.VendasTipadas ORDER BY LinhaId DESC;
SELECT r.LinhaId,r.Motivo,v.* FROM audit.Rejeicao r
JOIN raw.Vendas v ON v.LinhaId=r.LinhaId
WHERE r.ExecucaoId=(SELECT MAX(ExecucaoId) FROM audit.Execucao) ORDER BY r.LinhaId;
-- 2. Faturamento mensal, ticket por venda e margem (não representa lucro líquido).
SELECT CONVERT(char(7),DataVenda,126) Mes, COUNT(DISTINCT VendaId) Vendas,
 SUM(ReceitaLiquida) Faturamento,
 CONVERT(decimal(14,2),SUM(ReceitaLiquida)/NULLIF(COUNT(DISTINCT VendaId),0)) TicketMedio,
 SUM(MargemValor) Margem,
 CONVERT(decimal(9,2),100.0*SUM(MargemValor)/NULLIF(SUM(ReceitaLiquida),0)) MargemPct
FROM bi.FatoVendas GROUP BY CONVERT(char(7),DataVenda,126) ORDER BY Mes;
-- 3. Recebíveis: grão do título; não junte com os itens antes de somar valores.
SELECT Situacao,COUNT(*) Titulos,SUM(Valor) ValorOriginal,SUM(Recebido) Recebido,SUM(Saldo) EmAberto
FROM bi.ContasReceber GROUP BY Situacao;
SELECT SUM(CASE WHEN Situacao='VENCIDO' THEN Saldo ELSE 0 END) Vencido,
 CONVERT(decimal(9,2),100.0*SUM(CASE WHEN Situacao='VENCIDO' THEN Saldo ELSE 0 END)/NULLIF(SUM(Saldo),0)) PercentualVencidoSobreSaldo
FROM bi.ContasReceber;
-- 4. Ranking de clientes.
SELECT TOP(10) c.ClienteId,c.Nome,SUM(f.ReceitaLiquida) Faturamento
FROM bi.FatoVendas f JOIN erp.Cliente c ON c.ClienteId=f.ClienteId
GROUP BY c.ClienteId,c.Nome ORDER BY Faturamento DESC,c.ClienteId;
-- 5. Estoque e compras.
SELECT * FROM bi.Estoque ORDER BY SaldoQuantidade,ProdutoId;
SELECT CONVERT(char(7),DataCompra,126) Mes,SUM(ValorCompra) ValorComprado
FROM bi.Compras GROUP BY CONVERT(char(7),DataCompra,126) ORDER BY Mes;
-- 6. Janela: evolução mensal acumulada.
WITH M AS(SELECT CONVERT(char(7),DataVenda,126) Mes,SUM(ReceitaLiquida) Receita FROM bi.FatoVendas GROUP BY CONVERT(char(7),DataVenda,126))
SELECT Mes,Receita,SUM(Receita) OVER(ORDER BY Mes ROWS UNBOUNDED PRECEDING) Acumulado FROM M ORDER BY Mes;
-- 7. Recebimentos por mês: não confundir faturamento com entrada de caixa.
SELECT CONVERT(char(7),DataRecebimento,126) Mes,SUM(Valor) Recebimentos
FROM erp.Recebimento GROUP BY CONVERT(char(7),DataRecebimento,126) ORDER BY Mes;

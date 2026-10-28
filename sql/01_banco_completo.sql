/* Instalação em SSMS normal. Execute o arquivo inteiro.
Uma única unidade: se o banco existir, nenhuma carga ou alteração será executada.
Não recrie uma base já instalada; use 02 para consultar e 04 para reprocessar.
*/
SET NOCOUNT ON;
IF DB_ID(N'DataNexoERP_Lab') IS NOT NULL
BEGIN
    THROW 51000, 'A base DataNexoERP_Lab já existe. Instalação cancelada sem alterações. Abra 02_consultas_dashboard.sql.', 1;
END;
EXEC(N'CREATE DATABASE DataNexoERP_Lab;');
BEGIN TRY
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE TABLE dbo.IdentidadeLaboratorio(Versao int NOT NULL PRIMARY KEY, CriadoEm datetime2 NOT NULL DEFAULT SYSUTCDATETIME());
INSERT dbo.IdentidadeLaboratorio(Versao) VALUES(1);'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE SCHEMA raw;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE SCHEMA stg;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE SCHEMA erp;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE SCHEMA audit;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE SCHEMA bi;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE TABLE raw.Vendas (
    LinhaId int IDENTITY PRIMARY KEY,
    VendaTexto nvarchar(30), ItemTexto nvarchar(20), DataTexto nvarchar(30),
    ClienteTexto nvarchar(30), NomeCliente nvarchar(120), UF nvarchar(10),
    ProdutoTexto nvarchar(30), QuantidadeTexto nvarchar(30), PrecoTexto nvarchar(30),
    DescontoTexto nvarchar(30), AtualizadoEm datetime2 NOT NULL
);
CREATE TABLE audit.Execucao (
    ExecucaoId int IDENTITY PRIMARY KEY, InicioUTC datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FimUTC datetime2, Brutos int, Aceitos int, Rejeitados int
);
CREATE TABLE audit.Rejeicao (
    ExecucaoId int NOT NULL REFERENCES audit.Execucao(ExecucaoId),
    LinhaId int NOT NULL REFERENCES raw.Vendas(LinhaId), Motivo nvarchar(150) NOT NULL,
    PRIMARY KEY(ExecucaoId,LinhaId)
);
CREATE TABLE erp.Cliente (
    ClienteId int PRIMARY KEY, Nome nvarchar(120) NOT NULL,
    UF char(2) NOT NULL CHECK(UF IN (''''SP'''',''''RJ'''',''''MG'''',''''PR'''',''''SC'''',''''RS''''))
);
CREATE TABLE erp.Produto (
    ProdutoId int PRIMARY KEY, Nome nvarchar(100) NOT NULL,
    Categoria nvarchar(40) NOT NULL, Custo decimal(12,2) NOT NULL CHECK(Custo>0),
    PrecoLista decimal(12,2) NOT NULL CHECK(PrecoLista>0), EstoqueMinimo int NOT NULL CHECK(EstoqueMinimo>=0)
);
CREATE TABLE erp.Fornecedor (FornecedorId int PRIMARY KEY, Nome nvarchar(100) NOT NULL);
CREATE TABLE erp.Venda (
    VendaId int PRIMARY KEY, ClienteId int NOT NULL REFERENCES erp.Cliente(ClienteId),
    DataVenda date NOT NULL
);
CREATE TABLE erp.ItemVenda (
    VendaId int NOT NULL REFERENCES erp.Venda(VendaId), Item int NOT NULL CHECK(Item>0),
    ProdutoId int NOT NULL REFERENCES erp.Produto(ProdutoId),
    Quantidade int NOT NULL CHECK(Quantidade>0), PrecoUnitario decimal(12,2) NOT NULL CHECK(PrecoUnitario>0),
    Desconto decimal(12,2) NOT NULL CHECK(Desconto>=0),
    CustoUnitario decimal(12,2) NOT NULL CHECK(CustoUnitario>0),
    PRIMARY KEY(VendaId,Item), CHECK(Desconto<=Quantidade*PrecoUnitario)
);
CREATE TABLE erp.ContaReceber (
    ContaId int PRIMARY KEY, VendaId int NOT NULL UNIQUE REFERENCES erp.Venda(VendaId),
    Vencimento date NOT NULL, Valor decimal(14,2) NOT NULL CHECK(Valor>0)
);
CREATE TABLE erp.Recebimento (
    RecebimentoId int PRIMARY KEY, ContaId int NOT NULL REFERENCES erp.ContaReceber(ContaId),
    DataRecebimento date NOT NULL, Valor decimal(14,2) NOT NULL CHECK(Valor>0)
);
CREATE TABLE erp.Compra (
    CompraId int PRIMARY KEY, FornecedorId int NOT NULL REFERENCES erp.Fornecedor(FornecedorId), DataCompra date NOT NULL
);
CREATE TABLE erp.ItemCompra (
    CompraId int NOT NULL REFERENCES erp.Compra(CompraId), Item int NOT NULL,
    ProdutoId int NOT NULL REFERENCES erp.Produto(ProdutoId), Quantidade int NOT NULL CHECK(Quantidade>0),
    CustoUnitario decimal(12,2) NOT NULL CHECK(CustoUnitario>0), PRIMARY KEY(CompraId,Item)
);
CREATE TABLE erp.MovimentoEstoque (
    MovimentoId int IDENTITY PRIMARY KEY, ProdutoId int NOT NULL REFERENCES erp.Produto(ProdutoId),
    DataMovimento date NOT NULL, Tipo varchar(10) NOT NULL CHECK(Tipo IN (''''ABERTURA'''',''''COMPRA'''',''''VENDA'''')),
    Quantidade int NOT NULL CHECK(Quantidade<>0), DocumentoId int,
    CHECK((Tipo=''''VENDA'''' AND Quantidade<0) OR (Tipo IN (''''ABERTURA'''',''''COMPRA'''') AND Quantidade>0))
);
CREATE INDEX IX_Venda_Data ON erp.Venda(DataVenda) INCLUDE(ClienteId);
CREATE INDEX IX_Conta_Vencimento ON erp.ContaReceber(Vencimento) INCLUDE(Valor,VendaId);
CREATE INDEX IX_Recebimento_Conta ON erp.Recebimento(ContaId,DataRecebimento) INCLUDE(Valor);
CREATE INDEX IX_Estoque_ProdutoData ON erp.MovimentoEstoque(ProdutoId,DataMovimento) INCLUDE(Quantidade);'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''-- 600 vendas x 2 itens. Fonte fictícia com datas brasileiras e decimal com vírgula.
;WITH N AS (
 SELECT TOP(600) ROW_NUMBER() OVER(ORDER BY a.object_id,b.object_id) n
 FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT raw.Vendas
SELECT CONVERT(nvarchar(30),n),CONVERT(nvarchar(20),i.Item),
       CONVERT(char(10),DATEADD(day,(n-1)%270,CONVERT(date,''''20260101'''',112)),103),
       CONVERT(nvarchar(30),1+(n-1)%120),
       N''''  Cliente fictício ''''+CONVERT(nvarchar(10),1+(n-1)%120)+N''''  '''',
       CASE n%6 WHEN 0 THEN '''' sp '''' WHEN 1 THEN ''''rj'''' WHEN 2 THEN '''' MG '''' WHEN 3 THEN ''''pr'''' WHEN 4 THEN ''''sc'''' ELSE ''''rs'''' END,
       CONVERT(nvarchar(30),1+(n+i.Item-2)%30),
       CONVERT(nvarchar(30),1+n%5),
       REPLACE(CONVERT(varchar(30),CONVERT(decimal(12,2),50+(1+(n+i.Item-2)%30)*10)),''''.'''','''',''''),
       CASE WHEN n%4=0 THEN ''''5,00'''' ELSE ''''0,00'''' END, ''''20261027''''
FROM N CROSS JOIN (VALUES(1),(2)) i(Item);
-- Duplicidades: a versão mais recente da mesma venda/item deve prevalecer.
INSERT raw.Vendas
SELECT VendaTexto,ItemTexto,DataTexto,ClienteTexto,NomeCliente,UF,ProdutoTexto,QuantidadeTexto,PrecoTexto,DescontoTexto,''''20261028''''
FROM raw.Vendas WHERE LinhaId IN (1,2);
-- Oito problemas, cada um em uma chave nova, sem substituir vendas válidas.
INSERT raw.Vendas VALUES
(''''9001'''',''''1'''',''''31/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''RJ'''',''''1'''',''''2'''',''''60,00'''',''''0'''',''''20261028''''),
(''''9002'''',''''1'''',''''01/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''RJ'''',''''1'''',''''-2'''',''''60,00'''',''''0'''',''''20261028''''),
(''''9003'''',''''1'''',''''01/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''RJ'''',''''1'''',''''2'''',''''abc'''',''''0'''',''''20261028''''),
(''''9004'''',''''1'''',''''01/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''RJ'''',''''999'''',''''2'''',''''60,00'''',''''0'''',''''20261028''''),
(''''9005'''',''''1'''',''''01/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''XX'''',''''1'''',''''2'''',''''60,00'''',''''0'''',''''20261028''''),
(''''9006'''',''''1'''',''''01/02/2026'''',''''1'''',''''   '''',''''RJ'''',''''1'''',''''2'''',''''60,00'''',''''0'''',''''20261028''''),
(''''9007'''',''''1'''',''''01/02/2026'''',''''1'''',''''Cliente fictício 1'''',''''RJ'''',''''1'''',''''2'''',''''60,00'''',''''999'''',''''20261028''''),
(''''9008'''',''''1'''',''''01/02/2026'''','''''''',''''Cliente sem código'''',''''RJ'''',''''1'''',''''2'''',''''60,00'''',''''0'''',''''20261028'''');'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''-- Staging é uma view: preserva o dado bruto e expõe a interpretação tipada.
CREATE OR ALTER VIEW stg.VendasTipadas AS
SELECT LinhaId,AtualizadoEm,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(VendaTexto)),'''''''')) VendaId,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(ItemTexto)),'''''''')) Item,
 TRY_CONVERT(date,DataTexto,103) DataVenda,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(ClienteTexto)),'''''''')) ClienteId,
 NULLIF(LTRIM(RTRIM(REPLACE(NomeCliente,NCHAR(160),'''' ''''))),'''''''') NomeCliente,
 UPPER(LTRIM(RTRIM(UF))) UF,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(ProdutoTexto)),'''''''')) ProdutoId,
 TRY_CONVERT(int,NULLIF(LTRIM(RTRIM(QuantidadeTexto)),'''''''')) Quantidade,
 TRY_CONVERT(decimal(12,2),NULLIF(REPLACE(LTRIM(RTRIM(PrecoTexto)),'''','''',''''.''''),'''''''')) Preco,
 TRY_CONVERT(decimal(12,2),NULLIF(REPLACE(LTRIM(RTRIM(DescontoTexto)),'''','''',''''.''''),'''''''')) Desconto
FROM raw.Vendas;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER PROCEDURE erp.ReprocessarLaboratorio
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 BEGIN TRY
  BEGIN TRANSACTION;
  -- Serializa recargas para evitar duas sessões alterando o laboratório juntas.
  DECLARE @lock int;
  EXEC @lock=sys.sp_getapplock @Resource=''''DataNexoERP_Recarga'''',@LockMode=''''Exclusive'''',@LockOwner=''''Transaction'''',@LockTimeout=0;
  IF @lock<0 THROW 51002,''''Outra recarga está em andamento.'''',1;
  INSERT audit.Execucao DEFAULT VALUES;
  DECLARE @Execucao int=CONVERT(int,SCOPE_IDENTITY());
  -- Somente tabelas curadas do laboratório são reconstruídas; raw e auditoria são preservados.
  DELETE erp.MovimentoEstoque; DELETE erp.Recebimento; DELETE erp.ContaReceber;
  DELETE erp.ItemVenda; DELETE erp.Venda; DELETE erp.ItemCompra; DELETE erp.Compra;
  DELETE erp.Fornecedor; DELETE erp.Cliente; DELETE erp.Produto;
  ;WITH N AS(SELECT TOP(30) ROW_NUMBER() OVER(ORDER BY object_id) n FROM sys.all_objects)
  INSERT erp.Produto
  SELECT n,N''''Produto fictício ''''+CONVERT(nvarchar(10),n),
    CASE n%3 WHEN 0 THEN N''''Informática'''' WHEN 1 THEN N''''Escritório'''' ELSE N''''Acessórios'''' END,
    (50+n*10)*0.6,50+n*10,50 FROM N;
  INSERT erp.Fornecedor VALUES(1,N''''Fornecedor fictício A''''),(2,N''''Fornecedor fictício B''''),(3,N''''Fornecedor fictício C'''');
  SELECT t.*,CONVERT(nvarchar(150),CASE
   WHEN VendaId IS NULL OR VendaId<=0 OR Item IS NULL OR Item<=0 THEN N''''Chave de venda/item inválida''''
   WHEN DataVenda IS NULL OR DataVenda<''''20260101'''' OR DataVenda>''''20261028'''' THEN N''''Data inválida ou fora do período''''
   WHEN ClienteId IS NULL OR ClienteId NOT BETWEEN 1 AND 120 THEN N''''Código de cliente inválido''''
   WHEN NomeCliente IS NULL THEN N''''Nome de cliente vazio''''
   WHEN UF IS NULL OR UF NOT IN (''''SP'''',''''RJ'''',''''MG'''',''''PR'''',''''SC'''',''''RS'''') THEN N''''UF inválida''''
   WHEN p.ProdutoId IS NULL THEN N''''Produto inexistente''''
   WHEN Quantidade IS NULL OR Quantidade NOT BETWEEN 1 AND 1000 THEN N''''Quantidade inválida''''
   WHEN Preco IS NULL OR Preco<=0 THEN N''''Preço inválido''''
   WHEN Desconto IS NULL OR Desconto<0 OR Desconto>Quantidade*Preco THEN N''''Desconto inválido''''
   END) Motivo
  INTO #Validacao
  FROM stg.VendasTipadas t LEFT JOIN erp.Produto p ON p.ProdutoId=t.ProdutoId;
  INSERT audit.Rejeicao SELECT @Execucao,LinhaId,Motivo FROM #Validacao WHERE Motivo IS NOT NULL;
  -- Apenas versões válidas participam da deduplicação; raw continua intacta.
  SELECT *,ROW_NUMBER() OVER(PARTITION BY VendaId,Item ORDER BY AtualizadoEm DESC,LinhaId DESC) rn
  INTO #Ranking FROM #Validacao WHERE Motivo IS NULL;
  INSERT audit.Rejeicao SELECT @Execucao,LinhaId,N''''Duplicidade: versão válida mais recente mantida'''' FROM #Ranking WHERE rn>1;
  SELECT * INTO #Aceitos FROM #Ranking WHERE rn=1;
  -- Divergências de cabeçalho não são corrigidas silenciosamente.
  IF EXISTS(SELECT VendaId FROM #Aceitos GROUP BY VendaId HAVING COUNT(DISTINCT ClienteId)>1 OR COUNT(DISTINCT DataVenda)>1)
    THROW 51003,''''Itens de uma venda divergem no cliente ou data. Corrija a fonte.'''',1;
  IF EXISTS(SELECT ClienteId FROM #Aceitos GROUP BY ClienteId HAVING COUNT(DISTINCT NomeCliente)>1 OR COUNT(DISTINCT UF)>1)
    THROW 51004,''''Cadastro de cliente conflitante. Corrija a fonte.'''',1;
  INSERT erp.Cliente SELECT ClienteId,MIN(NomeCliente),MIN(UF) FROM #Aceitos GROUP BY ClienteId;
  INSERT erp.Venda SELECT VendaId,MIN(ClienteId),MIN(DataVenda) FROM #Aceitos GROUP BY VendaId;
  INSERT erp.ItemVenda
  SELECT a.VendaId,a.Item,a.ProdutoId,a.Quantidade,a.Preco,a.Desconto,p.Custo FROM #Aceitos a JOIN erp.Produto p ON p.ProdutoId=a.ProdutoId;
  INSERT erp.ContaReceber
  SELECT v.VendaId,v.VendaId,DATEADD(day,30,v.DataVenda),SUM(i.Quantidade*i.PrecoUnitario-i.Desconto)
  FROM erp.Venda v JOIN erp.ItemVenda i ON i.VendaId=v.VendaId GROUP BY v.VendaId,v.DataVenda;
  -- 1 título por venda; pagamento total, parcial ou inexistente, respeitando a data de referência.
  INSERT erp.Recebimento
  SELECT c.ContaId,c.ContaId,DATEADD(day,CASE WHEN c.ContaId%4=0 THEN 45 ELSE 15 END,v.DataVenda),
    CONVERT(decimal(14,2),CASE WHEN c.ContaId%4=1 THEN c.Valor*0.5 ELSE c.Valor END)
  FROM erp.ContaReceber c JOIN erp.Venda v ON v.VendaId=c.VendaId
  WHERE c.ContaId%4<>2 AND DATEADD(day,CASE WHEN c.ContaId%4=0 THEN 45 ELSE 15 END,v.DataVenda)<=''''20261028'''';
  INSERT erp.Compra VALUES(1,1,''''20260101''''),(2,2,''''20260401''''),(3,3,''''20260701'''');
  INSERT erp.ItemCompra SELECT c.CompraId,p.ProdutoId,p.ProdutoId,100,p.Custo FROM erp.Compra c CROSS JOIN erp.Produto p;
  INSERT erp.MovimentoEstoque(ProdutoId,DataMovimento,Tipo,Quantidade,DocumentoId)
  SELECT ProdutoId,''''20260101'''',''''ABERTURA'''',500,NULL FROM erp.Produto;
  INSERT erp.MovimentoEstoque(ProdutoId,DataMovimento,Tipo,Quantidade,DocumentoId)
  SELECT i.ProdutoId,c.DataCompra,''''COMPRA'''',i.Quantidade,c.CompraId FROM erp.ItemCompra i JOIN erp.Compra c ON c.CompraId=i.CompraId;
  INSERT erp.MovimentoEstoque(ProdutoId,DataMovimento,Tipo,Quantidade,DocumentoId)
  SELECT i.ProdutoId,v.DataVenda,''''VENDA'''',-i.Quantidade,v.VendaId FROM erp.ItemVenda i JOIN erp.Venda v ON v.VendaId=i.VendaId;
  UPDATE audit.Execucao SET FimUTC=SYSUTCDATETIME(),Brutos=(SELECT COUNT(*) FROM raw.Vendas),
   Aceitos=(SELECT COUNT(*) FROM #Aceitos),Rejeitados=(SELECT COUNT(*) FROM audit.Rejeicao WHERE ExecucaoId=@Execucao)
  WHERE ExecucaoId=@Execucao;
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH
END;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''EXEC erp.ReprocessarLaboratorio;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER VIEW bi.FatoVendas AS
SELECT v.VendaId,i.Item,v.DataVenda,v.ClienteId,i.ProdutoId,i.Quantidade,i.PrecoUnitario,i.Desconto,
 CONVERT(decimal(14,2),i.Quantidade*i.PrecoUnitario) ReceitaBruta,
 CONVERT(decimal(14,2),i.Quantidade*i.PrecoUnitario-i.Desconto) ReceitaLiquida,
 CONVERT(decimal(14,2),i.Quantidade*i.CustoUnitario) CustoTotal,
 CONVERT(decimal(14,2),i.Quantidade*(i.PrecoUnitario-i.CustoUnitario)-i.Desconto) MargemValor
FROM erp.Venda v JOIN erp.ItemVenda i ON i.VendaId=v.VendaId;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER VIEW bi.ContasReceber AS
WITH Pagos AS(SELECT ContaId,SUM(Valor) Pago FROM erp.Recebimento WHERE DataRecebimento<=''''20261028'''' GROUP BY ContaId)
SELECT c.ContaId,c.VendaId,v.ClienteId,v.DataVenda,c.Vencimento,c.Valor,
 COALESCE(p.Pago,0) Recebido,c.Valor-COALESCE(p.Pago,0) Saldo,
 CASE WHEN c.Valor-COALESCE(p.Pago,0)<=0 THEN ''''QUITADO''''
      WHEN c.Vencimento<''''20261028'''' THEN ''''VENCIDO'''' ELSE ''''A VENCER'''' END Situacao,
 CONVERT(date,''''20261028'''',112) DataReferencia
FROM erp.ContaReceber c JOIN erp.Venda v ON v.VendaId=c.VendaId LEFT JOIN Pagos p ON p.ContaId=c.ContaId;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER VIEW bi.Estoque AS
SELECT p.ProdutoId,p.Nome,p.Categoria,p.EstoqueMinimo,
 COALESCE(SUM(m.Quantidade),0) SaldoQuantidade,
 CONVERT(decimal(14,2),COALESCE(SUM(m.Quantidade),0)*p.Custo) ValorAoCusto
FROM erp.Produto p LEFT JOIN erp.MovimentoEstoque m ON m.ProdutoId=p.ProdutoId AND m.DataMovimento<=''''20261028''''
GROUP BY p.ProdutoId,p.Nome,p.Categoria,p.EstoqueMinimo,p.Custo;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER VIEW bi.Compras AS
SELECT c.CompraId,c.DataCompra,c.FornecedorId,i.Item,i.ProdutoId,i.Quantidade,i.CustoUnitario,
 CONVERT(decimal(14,2),i.Quantidade*i.CustoUnitario) ValorCompra
FROM erp.Compra c JOIN erp.ItemCompra i ON i.CompraId=c.CompraId;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''CREATE OR ALTER VIEW bi.Calendario AS
WITH N AS(SELECT TOP(365) ROW_NUMBER() OVER(ORDER BY a.object_id,b.object_id)-1 n FROM sys.all_objects a CROSS JOIN sys.all_objects b),
D AS(SELECT DATEADD(day,CONVERT(int,n),CONVERT(date,''''20260101'''',112)) Data FROM N)
SELECT Data,YEAR(Data) Ano,MONTH(Data) Mes,DAY(Data) Dia,CONVERT(char(7),Data,126) AnoMes,DATEPART(quarter,Data) Trimestre FROM D;'');');
    EXEC(N'USE DataNexoERP_Lab; EXEC(N''SELECT * FROM audit.Execucao;
SELECT Motivo,COUNT(*) Quantidade FROM audit.Rejeicao WHERE ExecucaoId=(SELECT MAX(ExecucaoId) FROM audit.Execucao) GROUP BY Motivo;'');');
END TRY
BEGIN CATCH
    -- Se houver falha, a base parcial é preservada para diagnóstico.
    THROW;
END CATCH;

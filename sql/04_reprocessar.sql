USE DataNexoERP_Lab;
GO
-- Execute apenas neste laboratório. Recria o ERP curado a partir da raw.
-- Preserva os brutos e o histórico de auditoria. Alterações manuais no ERP serão substituídas.
EXEC erp.ReprocessarLaboratorio;
SELECT * FROM audit.Execucao ORDER BY ExecucaoId;

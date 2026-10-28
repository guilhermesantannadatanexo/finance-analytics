# Validação local — 28/10/2026

Ambiente: SQL Server 2025, versão 17.0.1145.4, autenticação Windows.

- Instalação completa executada com sucesso em base nova `DataNexoERP_Lab`.
- 1.210 registros brutos: 1.200 aceitos, duas duplicidades e oito linhas inválidas rejeitadas.
- 600 vendas, 120 clientes, 30 produtos, 90 itens de compra e calendário de 365 dias.
- Faturamento líquido: R$ 748.500,00; recebido: R$ 457.480,00; saldo: R$ 291.020,00.
- Validador de contagens, referências, conciliação financeira, recebimentos e estoque final/histórico aprovado; DBCC CHECKCONSTRAINTS sem violações.
- Reprocessamento executado; totais preservados e nova execução registrada na auditoria.
- Todas as consultas do arquivo 02 executadas sem erro.
- Nova tentativa de instalação bloqueada por base já existente; validador aprovado novamente após o bloqueio.

Valores se referem à carga original sintética e à data de referência fixa 28/10/2026. Não constituem validação do sistema como ERP de produção nem da performance em grande volume. Não foi criado arquivo PBIX nesta etapa.

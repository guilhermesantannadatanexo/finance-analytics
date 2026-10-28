# Finance Analytics — laboratório ERP SQL Server

Projeto DataNexo para estudar SQL, saneamento de dados e dashboards de ERP com faturamento, recebíveis, compras e estoque. Dados inteiramente sintéticos; não utiliza dados de empresas ou pessoas reais.

## Começar

1. Leia o [guia de execução e saneamento](docs/GUIA-DO-LABORATORIO.md).
2. Execute [01_banco_completo.sql](sql/01_banco_completo.sql) pelo SSMS em **Modo SQLCMD** ou pelo sqlcmd. A instalação interrompe se o banco já existir.
3. Confira [03_validar.sql](sql/03_validar.sql).
4. Explore [02_consultas_dashboard.sql](sql/02_consultas_dashboard.sql).
5. Para refazer a carga curada, use [04_reprocessar.sql](sql/04_reprocessar.sql).

O banco `DataNexoERP_Lab` contém raw preservada, staging tipada, auditoria de qualidade, tabelas relacionais e views de BI. A carga original possui 1.210 linhas brutas, 1.200 itens aceitos e 10 rejeições rastreáveis. Referência financeira fixa em 28/10/2026.

**Status:** banco e consultas implementados e validados em SQL Server 2025 local. Dashboard Power BI, publicação no Service e estudos de gateway/RLS ainda pendentes. Os testes de SQL estão em `sql/03_validar.sql`; o guia explica os limites do modelo.

## Plano original e próximos passos


Dias 1–14 · SQL Server + Power BI

Pergunta de negócio: Como acompanhar caixa, inadimplência e orçamento?

## Backlog

- [ ] Gerar dados sintéticos de contas, recebimentos, pagamentos e orçamento.
- [ ] Definir grão e modelo estrela com calendário e plano de contas.
- [ ] Criar consultas e medidas para caixa, DRE gerencial e orçamento versus realizado.
- [ ] Conciliar os totais do relatório com consultas SQL e testar períodos sem movimento.

## Critérios de entrega

- [ ] Dados fictícios e dicionário documentados.
- [ ] Código/configuração e passos para reproduzir.
- [ ] Validações com entradas, resultados esperados e resultados obtidos.
- [ ] Diagrama, capturas ou demonstração.
- [ ] README com decisões, limites e próximos passos.
- [ ] Texto de estudo de caso para site e resumo para LinkedIn.

## Registro de execução

Data | Atividade | Evidência | Próximo passo
---|---|---|---

Status atual acima; os itens do plano original ainda não implementados permanecem como próximos passos.

# Banco ERP para estudar SQL e Power BI

## O que foi criado

Base exclusiva `DataNexoERP_Lab`, com dados 100% fictícios. Os scripts não baixam dados nem usam informações pessoais. SQL Server 2016 SP1 ou superior; validado nesta máquina em SQL Server 2025 (17.0.1145.4).

| Camada | Objetivo |
|---|---|
| raw.Vendas | 1.210 linhas originais, sem correção ou exclusão |
| stg.VendasTipadas | Interpretação com TRY_CONVERT, trim, UF maiúscula e decimal com vírgula |
| audit.Execucao / Rejeicao | Contagens e motivo da rejeição de cada linha por execução |
| erp | Clientes, produtos, fornecedores, vendas/itens, títulos/recebimentos, compras/itens e movimentos de estoque |
| bi | Views de vendas, recebíveis, compras, estoque e calendário para análise |

São 600 vendas, 1.200 itens aceitos, 120 clientes, 30 produtos, três compras com 90 itens e 365 dias de calendário. Datas de venda: janeiro a setembro de 2026. Posição de recebíveis e estoque: **28/10/2026**, fixa para tornar os resultados reproduzíveis.

## Como executar pelo SSMS

1. Abra o SQL Server Management Studio e conecte à sua instância. Nesta máquina foi usada `localhost`, com autenticação do Windows.
2. Abra `sql/01_banco_completo.sql`. Em **Consulta > Modo SQLCMD**, habilite o modo SQLCMD: a diretiva `:ON ERROR EXIT` interrompe em erros, inclusive se a base já existir.
3. Clique em **Executar / F5**. É necessário ter permissão de criação de banco. Atualize o Explorador de Objetos para ver `DataNexoERP_Lab`.
4. Abra `sql/03_validar.sql`, habilite o modo SQLCMD e execute. O resultado deve mostrar `PASSOU`.
5. Execute `sql/02_consultas_dashboard.sql` para explorar as consultas. Você pode selecionar uma consulta e executar somente o trecho.
6. Para reaplicar o saneamento depois de estudar a fonte, use `sql/04_reprocessar.sql`, não o script de instalação. A recarga substitui somente o ERP curado deste laboratório e preserva raw e auditoria. Não apaga o banco.

**Nesta máquina a instalação e as validações já foram executadas.** Você pode começar pelo passo 4 ou 5. Executar novamente o script 01 retorna erro de base existente e interrompe; isso é esperado.

Alternativa no terminal, a partir da pasta do projeto:

```powershell
sqlcmd -S localhost -E -C -b -f 65001 -i sql/01_banco_completo.sql
sqlcmd -S localhost -E -C -b -f 65001 -i sql/03_validar.sql
```

`-E` usa autenticação Windows; `-C` confia no certificado local para este laboratório. Não coloque senhas em scripts versionados.

## Como o saneamento funciona

1. Preserva os textos da origem em `raw`.
2. Converte datas brasileiras explicitamente com estilo 103 e números com TRY_CONVERT. Nesta fonte, decimal usa vírgula **sem separador de milhar**: `1.234,56` não faz parte do contrato e é rejeitado. O objetivo é não adivinhar formatos ambíguos.
3. Remove espaços nas extremidades dos nomes e códigos; padroniza UF em maiúsculas. Não inventa nome ou código ausente.
4. Rejeita data impossível, cliente sem código, nome vazio, UF desconhecida, produto inexistente, quantidade não positiva, preço não numérico e desconto maior que o total bruto.
5. Entre versões válidas da mesma venda/item, mantém a mais recente por AtualizadoEm e LinhaId. A versão válida anterior fica registrada como duplicidade. **Política específica do laboratório:** versões inválidas não substituem uma versão válida anterior.
6. Detecta divergências de cliente/data no cabeçalho e de nome/UF no cadastro. Se ocorrerem, desfaz toda a recarga; não escolhe um valor arbitrário.
7. Carrega tabelas com chaves, relacionamentos e CHECKs, e registra a conciliação de linhas.

Resultado original: **1.210 brutas = 1.200 aceitas + 10 rejeitadas** (duas duplicidades e oito erros). Cada linha recebe apenas o primeiro motivo encontrado. As rejeições são consultáveis com a linha original; falhas que desfazem a transação aparecem como erro do SQL Server e não deixam auditoria de sucesso.

A transação torna a recarga atômica; o bloqueio de aplicação impede recargas simultâneas. Não há deduplicação por nome: a chave do cliente é seu código. O tratamento é propositalmente limitado ao contrato desta base, não é um saneador universal de CSV.

## De onde pegar outras bases

- Microsoft AdventureWorks: banco empresarial de exemplo pronto para SQL Server: https://learn.microsoft.com/sql/samples/adventureworks-install-configure
- Portal Brasileiro de Dados Abertos: https://dados.gov.br/
- Portal da Transparência, downloads CSV: https://portaldatransparencia.gov.br/download-de-dados
- Dados abertos do IBGE: https://www.ibge.gov.br/acesso-informacao/dados-abertos.html

Para uma base externa, registre URL, data de extração, licença/condições de uso e dicionário. Importe primeiro para outra tabela raw com colunas texto, preserve o arquivo original e escreva regras conforme o formato real. Não misture arquivos externos diretamente nas tabelas deste exercício sem mapear suas colunas e regras. Evite publicar dados pessoais ou de antigos empregadores.

## Como criar mais dados fictícios

O script usa sequências de números e fórmulas determinísticas para gerar códigos, datas, quantidades e preços. Altere o `TOP(600)` da CTE N **em uma cópia do laboratório** para aumentar o volume, mantendo 120 clientes e 30 produtos. Ao aumentar vendas, ajuste também o estoque inicial, as expectativas de contagem do validador e a capacidade do calendário. Para treinar saneamento, insira uma linha errada em raw, execute o reprocessamento e consulte audit.Rejeicao. O validador fornecido fixa as contagens da carga original e deve acusar alterações de volume.

## Modelo no Power BI

Conecte em **Obter dados > SQL Server**, servidor `localhost`, banco `DataNexoERP_Lab`, modo Importação. Comece com `bi.FatoVendas`, `erp.Cliente`, `erp.Produto` e `bi.Calendario`.

- Calendario[Data] 1 → N FatoVendas[DataVenda]. Marque Calendario como tabela de datas.
- Cliente[ClienteId] 1 → N FatoVendas[ClienteId].
- Produto[ProdutoId] 1 → N FatoVendas[ProdutoId].
- Acrescente `bi.ContasReceber`, `bi.Compras` e `bi.Estoque` conforme precisar; trate cada fato no próprio grão. Não una recebíveis aos itens e depois some o valor do título: isso duplica o financeiro.
- Em ContasReceber, DataVenda e Vencimento têm papéis diferentes; escolha uma relação ativa ou calendários distintos conforme a análise. O saldo fornecido é uma posição fixa, não um saldo histórico por mês.
- Estoque é um snapshot por produto; não possui data para relacionamento ao calendário. Para evolução temporal, use os movimentos, acumulando quantidades com abertura anterior ao período.

Medidas iniciais:

```dax
Faturamento = SUM(FatoVendas[ReceitaLiquida])
Margem = SUM(FatoVendas[MargemValor])
Margem % = DIVIDE([Margem], [Faturamento])
Vendas = DISTINCTCOUNT(FatoVendas[VendaId])
Ticket médio = DIVIDE([Faturamento], [Vendas])
```

## Roteiro para praticar

1. Conte bruto, aceito e rejeitado e explique cada rejeição.
2. Faça JOIN de vendas, clientes e produtos e valide o grão de uma linha.
3. Compare faturamento e títulos; depois compare recebido e saldo.
4. Calcule ticket médio, margem e ranking por cliente.
5. Crie visuais mensais e confira um mês no SQL.
6. Escolha um problema novo na raw e documente sua regra de qualidade.

## Limites do modelo

Laboratório de análise, não ERP de produção: sem impostos, fretes, devoluções, múltiplas parcelas, contas a pagar, orçamento ou DRE completa. Receita não é caixa; margem aqui é receita menos custo dos produtos, não lucro líquido. Compras não são pagamentos. O custo é fixo por produto; não implementa custo médio ou FIFO. Vendas e estoque assumem entrega imediata. As regras de saneamento abrangem a fonte de vendas; compras, cadastros e pagamentos são gerados já válidos. RLS, gateway e publicação no Service ainda serão exercícios posteriores.

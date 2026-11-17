# Sistema Gestor de Eventos Acadêmicos

Projeto de Banco de Dados referente à modelagem conceitual (TP1), projeto lógico relacional (TP2) e implementação física em PostgreSQL (TP3) do **Gestor de Eventos Acadêmicos**.

## Integrantes da Equipe (Equipe 1)
- João Lucas Simões Rocha da Silveira
- José Moisés da Silva Lima
- Ramon Venâncio da Silva
- Yan de Freitas Cândido

---

## Ambiente e Ferramenta Utilizados
- **SGBD / Ambiente PostgreSQL:** `PostgreSQL 16`
- **Ferramenta para execução dos scripts:** `pgAdmin 4` (via **Query Tool**)

---

## Ordem de Execução dos Scripts

Os scripts devem ser executados nesta sequência exata:

1. **`01_create.sql`** — Limpa e recria o esquema `public` (`DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;`) e cria as 13 tabelas do modelo físico com seus tipos de dados, chaves primárias (`PK`), chaves estrangeiras (`FK` com `ON DELETE RESTRICT`/`CASCADE`), restrições `UNIQUE`, `DEFAULT` e `CHECK`.
2. **`02_insert.sql`** — Insere dados de teste consistentes em todas as 13 tabelas, respeitando a ordem de dependência referencial (tabelas independentes → dependentes nível 1 → dependentes nível 2).
3. **`03_objects.sql`** — Cria as visões (`VIEW`), os índices (`INDEX`) e as funções/gatilhos (`FUNCTION` + `TRIGGER`) responsáveis por aplicar no banco as regras de negócio de integridade entre tabelas (`RO-04`, `RA-02`, `RA-03` e `RA-04`).
4. **`04_tests.sql`** *(script de validação/testes)* — Executa consultas nas `VIEW`s, consultas analíticas com `JOIN` e `GROUP BY`, e casos de teste negativos que provocam erros intencionais (`RAISE EXCEPTION`) para comprovar o bloqueio dos gatilhos.

---

## Justificativa das VIEWs Criadas (`03_objects.sql`)

Foram criadas duas visões para simplificar consultas recorrentes do sistema sem expor a complexidade de múltiplas junções no código das consultas:

1. **`vw_cronograma_atividades`**
   - **Estrutura:** Une `ATIVIDADE`, `EVENTO` e `SALA` (via `MINISTRA`), retornando `nome_evento`, `atividade` (`titulo`), `tipo`, `carga_horaria`, `nome_sala` e `bloco`.
   - **Justificativa:** A exibição da programação do evento é uma das consultas mais frequentes tanto para participantes quanto para organizadores. A `VIEW` encapsula os relacionamentos entre evento, atividade e alocação de sala, facilitando a geração de cronogramas e reduzindo duplicação de SQL nas consultas de relatório e na futura camada de aplicação.

2. **`vw_status_inscricoes`**
   - **Estrutura:** Une `INSCRICAO`, `PARTICIPANTE` e `ATIVIDADE`, retornando `nome_participante`, `cpf_participante`, `atividade` (`titulo`), `status` e `data_hora_checkin`.
   - **Justificativa:** Centraliza o acompanhamento de inscrições e presenças em uma visão pronta para leitura, permitindo consultar rapidamente quem está inscrito em cada atividade, a situação da inscrição (`Pendente`, `Confirmada`, `Cancelada`) e se o check-in já foi registrado (pré-requisito para avaliação e emissão de certificado).

---

## Justificativa dos Índices Criados (`03_objects.sql`)

Embora o PostgreSQL crie índices automaticamente para `PRIMARY KEY` e restrições `UNIQUE` (como `cpf_participante`, `cpf_palestrante`, `matricula` e `(cpf_participante, codigo_atividade)`), filtros por atributos não únicos exigiriam varredura sequencial (`Seq Scan`). Por isso, foram criados três índices adicionais:

1. **`idx_participante_nome` em `PARTICIPANTE(nome_participante)`**
   - **Justificativa:** Acelera buscas nominais e listagens filtradas/ordenadas por nome de participante em telas administrativas, listas de presença e buscas realizadas pelo back-end (previsto em Django).
2. **`idx_participante_email` em `PARTICIPANTE(email_participante)`**
   - **Justificativa:** Otimiza consultas diretas por e-mail — operação frequente em autenticação, verificação de cadastro e contato com participantes — evitando leitura completa da tabela `PARTICIPANTE`.
3. **`idx_evento_datas` em `EVENTO(data_inicio, data_fim)`**
   - **Justificativa:** Melhora o desempenho de consultas por faixa de datas, como filtragem de eventos em andamento, futuros ou encerrados, além de auxiliar verificações de período de eventos.

---

## Descrição dos Gatilhos (Triggers) Implementados (`03_objects.sql`)

Foram implementados dois gatilhos `BEFORE INSERT OR UPDATE` em PL/pgSQL para garantir regras de negócio que envolvem validação cruzada entre tabelas (e que não podem ser expressas apenas por `CHECK` na própria tabela):

1. **`trg_valida_inscricao` (função `fn_valida_inscricao()`)**
   - **Tabela e momento de disparo:** `BEFORE INSERT OR UPDATE ON INSCRICAO FOR EACH ROW`
   - **Regras implementadas:**
     - **RO-04 (Avaliação/comentário condicionados ao check-in):** Impede o registro ou alteração de `nota_avaliacao` ou `comentario` (`IS NOT NULL`) enquanto `data_hora_checkin` for `NULL`, lançando exceção com mensagem explicativa.
     - **RA-04 (Check-in dentro do período do evento):** Quando `data_hora_checkin` é informado, consulta `EVENTO.data_inicio` e `EVENTO.data_fim` por meio de `ATIVIDADE` (`codigo_atividade`) e bloqueia a operação caso `data_hora_checkin::DATE` seja anterior a `data_inicio` ou posterior a `data_fim`.

2. **`trg_valida_certificado` (função `fn_valida_certificado()`)**
   - **Tabela e momento de disparo:** `BEFORE INSERT OR UPDATE ON CERTIFICADO FOR EACH ROW`
   - **Regras implementadas:**
     - **RA-02 (Certificado exige check-in):** Busca `INSCRICAO.data_hora_checkin` correspondente a `NEW.id_inscricao` e impede a emissão/atualização do certificado caso o check-in não tenha sido registrado (`IS NULL`).
     - **RA-03 (Limite de carga horária certificada):** Consulta `ATIVIDADE.carga_horaria` vinculada à inscrição e bloqueia o certificado caso `NEW.carga_horaria_certificada` seja maior que a carga horária oficial da atividade.

---

## Instruções para Recriar o Banco do Zero (pgAdmin 4)

### 1. Criar um banco de dados limpo (caso ainda não exista)
1. Abra o **pgAdmin 4** e conecte-se ao servidor **PostgreSQL 16**.
2. No painel lateral esquerdo (**Browser**), escolha uma das opções abaixo:
   - **Via interface gráfica:** clique com o botão direito em **Databases** → **Create** → **Database...**, informe o nome `gestor_eventos_academicos` (com codificação `UTF8`) e clique em **Save**.
   - **Via SQL (Query Tool):** clique com o botão direito no banco padrão `postgres` → **Query Tool** e execute os comandos abaixo **um de cada vez** (selecionando cada linha e clicando em **Execute script**):

```sql
DROP DATABASE IF EXISTS gestor_eventos_academicos;
CREATE DATABASE gestor_eventos_academicos ENCODING 'UTF8';
```

### 2. Executar os scripts de criação, carga e objetos
No painel **Browser** do pgAdmin 4:

1. Expanda **Databases**, clique com o botão direito sobre **`gestor_eventos_academicos`** e selecione **Query Tool**.
   *(Caso o banco já tenha sido utilizado antes, não é necessário apagá-lo manualmente: o script `01_create.sql` já executa `DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;`.)*
2. Na barra de ferramentas do **Query Tool**, clique no ícone **Open File** (`Ctrl + O` no Windows/Linux ou `Cmd + O` no Mac), selecione **`01_create.sql`** e clique em **Execute script** (`F5` / botão de execução) para criar as 13 tabelas e restrições.
3. Repita o processo (**Open File** → **Execute script**) para o arquivo **`02_insert.sql`** (inserção da massa inicial de dados).
4. Repita o processo (**Open File** → **Execute script**) para o arquivo **`03_objects.sql`** (criação das `VIEW`s, `INDEX`es, `FUNCTION`s e `TRIGGER`s).

### 3. Executar as consultas e testes de validação (`04_tests.sql`)
1. Ainda conectado ao banco `gestor_eventos_academicos` no **Query Tool**, abra o arquivo **`04_tests.sql`** usando **Open File**.
2. Selecione e execute as seções **1 e 2** para conferir o retorno das `VIEW`s (`vw_cronograma_atividades` e `vw_status_inscricoes`) e das consultas com `JOIN` e `GROUP BY`.
3. Na seção **3**, **selecione e execute cada bloco SQL individualmente** (destacando o comando desejado antes de clicar em **Execute script**): os testes `RO-04`, `RA-04`, `RA-02` e `RA-03` **devem falhar propositalmente** (`RAISE EXCEPTION`) para comprovar os bloqueios dos gatilhos, e o comando intermediário de preparação (`INSERT INTO INSCRICAO ...`) precisa ser executado antes do teste `RA-02` para gerar a inscrição de teste (`id_inscricao = 2`).
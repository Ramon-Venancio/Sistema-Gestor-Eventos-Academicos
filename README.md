# Sistema Gestor de Eventos Acadêmicos

Projeto de Banco de Dados referente à modelagem conceitual (TP1), ao projeto lógico relacional (TP2) e à implementação física em PostgreSQL (TP3) do **Sistema Gestor de Eventos Acadêmicos**.

## Integrantes da equipe — Equipe 1

- João Lucas Simões Rocha da Silveira
- José Moisés da Silva Lima
- Ramon Venâncio da Silva
- Yan de Freitas Cândido

---

## 1. Ambiente e ferramentas

- **SGBD:** PostgreSQL 16.
- **Hospedagem prevista:** Neon (PostgreSQL gerenciado em servidor remoto).
- **Ferramenta de administração e execução:** pgAdmin 4, utilizando o Query Tool.
- **Codificação:** UTF-8.

O banco é hospedado remotamente. Cada integrante pode conectar seu pgAdmin 4 ao mesmo projeto/banco utilizando os dados de conexão fornecidos pelo painel do Neon.

### Configuração da conexão remota

No Neon, abra o projeto e utilize a opção **Connect** para obter os dados de conexão. No pgAdmin 4, registre um servidor com os seguintes campos:

| Campo no pgAdmin 4 | Informação fornecida pelo Neon |
|---|---|
| General → Name | Gestor de Eventos Acadêmicos (Remoto) — nome livre |
| Host name/address | Host da connection string |
| Port | Porta informada (normalmente 5432) |
| Maintenance database | Nome do banco selecionado no Neon |
| Username | Usuário informado pelo Neon |
| Password | Senha informada pelo Neon |
| SSL mode | `require` |

**Segurança:** não inclua senha, connection string completa, tokens ou outros segredos neste README, nos arquivos SQL ou no GitHub. Cada integrante deve obter/receber os dados de conexão por um canal privado. Se for necessário utilizar uma variável de ambiente na aplicação futura, mantenha o arquivo `.env` fora do controle de versão.

> O provedor e a região de hospedagem podem ser alterados sem modificar o modelo relacional. Se a equipe utilizar outro provedor PostgreSQL, atualize esta seção para refletir o ambiente realmente utilizado.

---

## 2. Estrutura dos artefatos

```text
Sistema-Gestor-Eventos-Academicos/
├── README.md
├── SQL-Scripts/
│   ├── 01_create.sql
│   ├── 02_insert.sql
│   ├── 03_objects.sql
│   └── 04_tests.sql
└── doc/
    └── 05_dicionario_fisico.md
```

---

## 3. Ordem de execução dos scripts

Execute os arquivos na ordem abaixo, conectando o pgAdmin 4 ao banco remoto destinado ao projeto:

1. **`SQL-Scripts/01_create.sql` — criação do esquema e das tabelas**
   - Remove e recria o schema `public` do banco conectado.
   - Cria as 13 tabelas do modelo físico.
   - Define tipos de dados PostgreSQL, chaves primárias, chaves estrangeiras, atributos obrigatórios, restrições `UNIQUE`, restrições `CHECK` e o valor padrão de `INSCRICAO.status` (`'Pendente'`).
2. **`SQL-Scripts/02_insert.sql` — população dos dados**
   - Insere dados coerentes com o domínio em todas as 13 tabelas.
   - Insere os registros respeitando as dependências entre as tabelas.
   - Inclui registros em quantidade suficiente para demonstrar relacionamentos, agregações, subconsulta e regras de negócio.
3. **`SQL-Scripts/03_objects.sql` — objetos físicos complementares**
   - Cria duas visões (`VIEW`).
   - Cria três índices auxiliares.
   - Cria duas funções em PL/pgSQL e dois gatilhos (`TRIGGER`).
4. **`SQL-Scripts/04_tests.sql` — testes e demonstração**
   - Executa consultas com `JOIN`, `GROUP BY`, função de agregação, `HAVING` e subconsulta.
   - Consulta as duas `VIEW`s.
   - Demonstra uma consulta compatível com índice.
   - Testa uma restrição `CHECK` e os gatilhos de inscrição e certificado.
   - Executa uma transação explícita com `BEGIN` e `ROLLBACK`.

### Como executar no pgAdmin 4

1. Conecte-se ao servidor remoto e selecione o banco destinado ao projeto.
2. Clique com o botão direito no banco e abra **Query Tool**.
3. Utilize **Open File** para abrir o primeiro script.
4. Execute com **F5** ou pelo botão **Execute script**.
5. Repita o procedimento na ordem indicada acima.

O `04_tests.sql` foi organizado para executar os testes negativos dentro de blocos `DO ... EXCEPTION`. As violações esperadas são capturadas e exibidas como mensagens `NOTICE`, permitindo que os demais testes continuem. Se aparecer uma mensagem `FALHA NO TESTE`, a regra correspondente não se comportou como esperado e deve ser investigada.

---

## 4. Atenção ao recriar o banco

O primeiro script contém:

```sql
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
```

Isso remove todos os objetos do schema `public` do banco atualmente selecionado e cria o schema novamente. Portanto:

- execute o script somente no banco destinado ao projeto;
- não o execute em um banco compartilhado com outros projetos ou dados importantes;
- combine com a equipe antes de recriar o schema remoto;
- faça backup dos dados que precisem ser preservados.

Em provedores gerenciados, como o Neon, utilize o banco disponibilizado/criado no painel do provedor. Não é necessário executar `DROP DATABASE` ou `CREATE DATABASE` pelo Query Tool para cada reconstrução: o `01_create.sql` recria as estruturas dentro do banco selecionado.

---

## 5. Justificativa das VIEWs

### `vw_cronograma_atividades`

Relaciona `ATIVIDADE`, `EVENTO`, `MINISTRA`, `PALESTRANTE` e `SALA`. Apresenta o evento, a atividade, seu tipo e carga horária, o palestrante responsável e a sala/bloco associados.

**Justificativa:** a programação é uma informação central do sistema. A visão reúne os relacionamentos necessários em uma consulta reutilizável, simplificando a apresentação do cronograma e evitando repetir os mesmos `JOIN`s em diferentes consultas da aplicação.

### `vw_status_inscricoes`

Relaciona `INSCRICAO`, `PARTICIPANTE` e `ATIVIDADE`. Apresenta identificação da inscrição, participante, atividade, status, data da inscrição, check-in, nota e comentário.

**Justificativa:** centraliza informações necessárias para acompanhar inscrições e presenças, facilitando consultas administrativas e futuras telas da aplicação.

---

## 6. Justificativa dos índices

As chaves primárias e restrições `UNIQUE` já possuem índices criados automaticamente pelo PostgreSQL. Foram adicionados três índices para consultas frequentes sobre colunas que não são, por si só, chaves únicas:

1. **`idx_participante_nome` — `PARTICIPANTE(nome_participante)`**
   - Auxilia buscas e listagens de participantes por nome.
2. **`idx_participante_email` — `PARTICIPANTE(email_participante)`**
   - Auxilia buscas por e-mail, como localização de cadastro e operações de autenticação que serão realizadas pelo backend.
3. **`idx_evento_datas` — `EVENTO(data_inicio, data_fim)`**
   - Auxilia consultas que filtram eventos por período ou datas de realização.

O teste do índice de e-mail utiliza uma condição de igualdade sobre `email_participante`. Como a massa de demonstração é pequena, o otimizador pode preferir uma varredura sequencial. Por isso, o teste desabilita temporariamente `enable_seqscan` apenas na sessão para tornar visível um plano que utiliza o índice e, em seguida, restaura a configuração com `RESET`.

---

## 7. Descrição dos gatilhos

### `trg_valida_inscricao` — função `fn_valida_inscricao()`

- **Tabela:** `INSCRICAO`.
- **Momento:** `BEFORE INSERT OR UPDATE`, para cada linha.
- **RO-04:** impede registrar nota de avaliação ou comentário quando `data_hora_checkin` estiver nulo.
- **RA-04:** quando há check-in, verifica se a data está entre `EVENTO.data_inicio` e `EVENTO.data_fim`, considerando o evento relacionado à atividade da inscrição.

### `trg_valida_certificado` — função `fn_valida_certificado()`

- **Tabela:** `CERTIFICADO`.
- **Momento:** `BEFORE INSERT OR UPDATE`, para cada linha.
- **RA-02:** impede emitir/atualizar certificado quando a inscrição relacionada não possui check-in.
- **RA-03:** impede que `carga_horaria_certificada` seja maior que a carga horária cadastrada para a atividade da inscrição.

As duas funções são implementadas em PL/pgSQL. Os testes negativos do `04_tests.sql` capturam as exceções esperadas para que o restante do roteiro seja executado.

---

## 8. Dicionário físico

O dicionário resumido das 13 tabelas, incluindo atributos, tipos PostgreSQL, obrigatoriedade, chaves e restrições relevantes, está em [`doc/05_dicionario_fisico.md`](doc/05_dicionario_fisico.md).

---

## 9. Instruções para reconstruir o banco do zero

1. Crie/selecione no Neon (ou no provedor PostgreSQL utilizado) um banco destinado exclusivamente ao projeto.
2. Conecte-se a esse banco pelo pgAdmin 4 com SSL habilitado (`SSL mode = require`, quando aplicável).
3. Execute `01_create.sql`.
4. Execute `02_insert.sql`.
5. Execute `03_objects.sql`.
6. Execute `04_tests.sql`.
7. Confira os resultados e mensagens no painel **Messages** e os resultados das consultas no painel **Data Output** do pgAdmin 4.

Para repetir a demonstração desde o início, execute novamente os scripts na ordem. O `01_create.sql` apagará e recriará o schema `public`, incluindo os dados e objetos nele existentes.

---

## 10. Observação sobre o escopo das regras

As restrições declaradas no modelo físico são aplicadas pelo PostgreSQL por meio de `NOT NULL`, `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK`, `DEFAULT` e gatilhos. A especialização de `PARTICIPANTE` em `ALUNO`, `PROFESSOR` e `EXTERNO` (RA-01), descrita no modelo como regra de aplicação, deve também ser validada pela camada de aplicação enquanto não houver uma implementação específica dessa regra no banco.

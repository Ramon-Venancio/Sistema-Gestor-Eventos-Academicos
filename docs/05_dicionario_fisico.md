# 05 - Dicionário Físico Resumido

- **Sistema:** Gestor de Eventos Acadêmicos (`Sistema-Gestor-Eventos-Academicos`)
- **Equipe 1:** João Lucas Simões Rocha da Silveira, José Moisés da Silva Lima, Ramon Venâncio da Silva e Yan de Freitas Cândido
- **SGBD:** PostgreSQL 16
- **Scripts de referência:** `01_create.sql` e `03_objects.sql`

> **Nota sobre o tipo `SERIAL`:** No PostgreSQL, colunas declaradas como `SERIAL` utilizam um inteiro de 4 bytes com sequência autoincremental (`NOT NULL` implícito e `DEFAULT nextval(...)`).

---

## 1. `EVENTO`
- **Chave Primária (PK):** `pk_evento` — `(codigo_evento)`
- **Chaves Estrangeiras (FK):** Nenhuma
- **Restrições Relevantes da Tabela:**
  - `chk_evento_datas`: `CHECK (data_fim >= data_inicio)` (RD-02)
  - `chk_evento_email`: `CHECK (email_contato LIKE '%@%')` (RD-10)
  - Índice auxiliar (`03_objects.sql`): `idx_evento_datas` em `(data_inicio, data_fim)`

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_evento` | `SERIAL` | `NOT NULL` | PK (`pk_evento`) | Autoincremento; identificador único do evento |
| `nome_evento` | `VARCHAR(255)` | `NOT NULL` | — | Nome pelo qual o evento é divulgado |
| `data_inicio` | `DATE` | `NOT NULL` | — | Data de início do evento |
| `data_fim` | `DATE` | `NOT NULL` | — | `chk_evento_datas`: deve ser `>= data_inicio` |
| `descricao_evento` | `TEXT` | `NULL` (Opcional) | — | Texto descritivo sobre o evento |
| `email_contato` | `VARCHAR(255)` | `NULL` (Opcional) | — | `chk_evento_email`: deve conter `@` |

---

## 2. `SALA`
- **Chave Primária (PK):** `pk_sala` — `(codigo_sala)`
- **Chaves Estrangeiras (FK):** Nenhuma
- **Restrições Relevantes da Tabela:**
  - `chk_sala_capacidade`: `CHECK (capacidade > 0)` (RD-04)
  - `chk_sala_andar`: `CHECK (andar >= 0)` (RD-05)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_sala` | `SERIAL` | `NOT NULL` | PK (`pk_sala`) | Autoincremento; identificador único da sala |
| `nome_sala` | `VARCHAR(100)` | `NOT NULL` | — | Nome ou número da sala |
| `capacidade` | `INT` | `NOT NULL` | — | `chk_sala_capacidade`: inteiro positivo (`> 0`) |
| `bloco` | `VARCHAR(50)` | `NULL` (Opcional) | — | Bloco onde a sala está localizada |
| `andar` | `INT` | `NULL` (Opcional) | — | `chk_sala_andar`: inteiro `>= 0` (`0 = térreo`) |

---

## 3. `PALESTRANTE`
- **Chave Primária (PK):** `pk_palestrante` — `(cpf_palestrante)`
- **Chaves Estrangeiras (FK):** Nenhuma
- **Restrições Relevantes da Tabela:**
  - `chk_palestrante_cpf`: `CHECK (length(cpf_palestrante) = 11 AND cpf_palestrante ~ '^[0-9]+$')` (RD-01)
  - `chk_palestrante_email`: `CHECK (email_palestrante LIKE '%@%')` (RD-10)
  - `chk_palestrante_lattes`: `CHECK (link_lattes LIKE 'http%')` (RD-11)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_palestrante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_palestrante`) | `chk_palestrante_cpf`: exatamente 11 dígitos numéricos sem pontuação |
| `nome_palestrante` | `VARCHAR(255)` | `NOT NULL` | — | Nome completo do palestrante |
| `email_palestrante` | `VARCHAR(255)` | `NOT NULL` | — | `chk_palestrante_email`: deve conter `@` |
| `minicurriculo` | `TEXT` | `NOT NULL` | — | Resumo da formação e atuação do palestrante |
| `instituicao` | `VARCHAR(255)` | `NULL` (Opcional) | — | Instituição à qual está vinculado |
| `link_lattes` | `VARCHAR(255)` | `NULL` (Opcional) | — | `chk_palestrante_lattes`: deve iniciar com `http` |

---

## 4. `PARTICIPANTE`
- **Chave Primária (PK):** `pk_participante` — `(cpf_participante)`
- **Chaves Estrangeiras (FK):** Nenhuma
- **Restrições Relevantes da Tabela:**
  - `chk_participante_cpf`: `CHECK (length(cpf_participante) = 11 AND cpf_participante ~ '^[0-9]+$')` (RD-01)
  - `chk_participante_email`: `CHECK (email_participante LIKE '%@%')` (RD-10)
  - `chk_participante_telefone`: `CHECK (telefone_participante ~ '^[0-9]+$')` (RD-12)
  - `chk_participante_nascimento`: `CHECK (data_nascimento < CURRENT_DATE)` (RD-07)
  - Índices auxiliares (`03_objects.sql`): `idx_participante_nome` em `(nome_participante)` e `idx_participante_email` em `(email_participante)`
  - Especialização total e exclusiva em `ALUNO`, `PROFESSOR` e `EXTERNO` (regra de aplicação RA-01)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_participante`) | `chk_participante_cpf`: exatamente 11 dígitos numéricos sem pontuação |
| `nome_participante` | `VARCHAR(255)` | `NOT NULL` | — | Nome completo; indexado por `idx_participante_nome` |
| `email_participante` | `VARCHAR(255)` | `NOT NULL` | — | `chk_participante_email`: deve conter `@`; indexado por `idx_participante_email` |
| `telefone_participante` | `VARCHAR(20)` | `NULL` (Opcional) | — | `chk_participante_telefone`: apenas dígitos numéricos (DDD + número) |
| `data_nascimento` | `DATE` | `NULL` (Opcional) | — | `chk_participante_nascimento`: anterior à data atual (`< CURRENT_DATE`) |

---

## 5. `ATIVIDADE`
- **Chave Primária (PK):** `pk_atividade` — `(codigo_atividade)`
- **Chaves Estrangeiras (FK):**
  - `fk_atividade_evento`: `codigo_evento` → `EVENTO(codigo_evento)` (`ON DELETE RESTRICT`, RR-01 e RO-02)
- **Restrições Relevantes da Tabela:**
  - `chk_atividade_ch`: `CHECK (carga_horaria > 0)` (RD-03)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_atividade` | `SERIAL` | `NOT NULL` | PK (`pk_atividade`) | Autoincremento; identificador único da atividade |
| `codigo_evento` | `INT` | `NOT NULL` | FK (`fk_atividade_evento`) | `ON DELETE RESTRICT`; nenhuma atividade existe sem evento (RO-02) |
| `titulo` | `VARCHAR(255)` | `NOT NULL` | — | Título da atividade |
| `tipo` | `VARCHAR(100)` | `NOT NULL` | — | Categoria da atividade (ex.: Minicurso, Palestra) |
| `carga_horaria` | `INT` | `NOT NULL` | — | `chk_atividade_ch`: inteiro positivo em horas (`> 0`) |
| `descricao_atividade` | `TEXT` | `NULL` (Opcional) | — | Texto descritivo sobre a atividade |

---

## 6. `ALUNO`
- **Chave Primária (PK):** `pk_aluno` — `(cpf_participante)`
- **Chaves Estrangeiras (FK):**
  - `fk_aluno_participante`: `cpf_participante` → `PARTICIPANTE(cpf_participante)` (`ON DELETE CASCADE`, RR-06)
- **Restrições Relevantes da Tabela:**
  - `uk_aluno_matricula`: `UNIQUE (matricula)` (RU-01)
  - `chk_aluno_semestre`: `CHECK (semestre > 0)` (RD-06)
  - Especialização total e exclusiva de `PARTICIPANTE` (regra de aplicação RA-01)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_aluno`), FK (`fk_aluno_participante`) | `ON DELETE CASCADE` a partir de `PARTICIPANTE` |
| `matricula` | `VARCHAR(50)` | `NOT NULL` | UK (`uk_aluno_matricula`) | Identificador alternativo único do aluno |
| `curso` | `VARCHAR(255)` | `NOT NULL` | — | Curso em que o aluno está matriculado |
| `semestre` | `INT` | `NULL` (Opcional) | — | `chk_aluno_semestre`: inteiro positivo (`> 0`) |
| `campus` | `VARCHAR(255)` | `NULL` (Opcional) | — | Campus ao qual o aluno pertence |

---

## 7. `PROFESSOR`
- **Chave Primária (PK):** `pk_professor` — `(cpf_participante)`
- **Chaves Estrangeiras (FK):**
  - `fk_professor_participante`: `cpf_participante` → `PARTICIPANTE(cpf_participante)` (`ON DELETE CASCADE`, RR-06)
- **Restrições Relevantes da Tabela:**
  - `chk_professor_lattes`: `CHECK (link_lattes LIKE 'http%')` (RD-11)
  - Especialização total e exclusiva de `PARTICIPANTE` (regra de aplicação RA-01)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_professor`), FK (`fk_professor_participante`) | `ON DELETE CASCADE` a partir de `PARTICIPANTE` |
| `titulacao` | `VARCHAR(100)` | `NOT NULL` | — | Maior titulação do professor |
| `departamento` | `VARCHAR(255)` | `NOT NULL` | — | Departamento ao qual o professor está vinculado |
| `link_lattes` | `VARCHAR(255)` | `NULL` (Opcional) | — | `chk_professor_lattes`: deve iniciar com `http` |

---

## 8. `EXTERNO`
- **Chave Primária (PK):** `pk_externo` — `(cpf_participante)`
- **Chaves Estrangeiras (FK):**
  - `fk_externo_participante`: `cpf_participante` → `PARTICIPANTE(cpf_participante)` (`ON DELETE CASCADE`, RR-06)
- **Restrições Relevantes da Tabela:**
  - Especialização total e exclusiva de `PARTICIPANTE` (regra de aplicação RA-01)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_externo`), FK (`fk_externo_participante`) | `ON DELETE CASCADE` a partir de `PARTICIPANTE` |
| `instituicao_origem` | `VARCHAR(255)` | `NOT NULL` | — | Instituição ou empresa de origem |
| `tipo_vinculo` | `VARCHAR(100)` | `NOT NULL` | — | Tipo de vínculo com a instituição de origem |
| `cargo` | `VARCHAR(255)` | `NULL` (Opcional) | — | Cargo ou função do participante externo |
| `cidade` | `VARCHAR(255)` | `NULL` (Opcional) | — | Cidade do participante externo |

---

## 9. `ATIVIDADE_PRE_REQUISITO`
- **Chave Primária (PK):** `pk_atividade_pre_requisito` — `(codigo_atividade, pre_requisito)` (RU-05)
- **Chaves Estrangeiras (FK):**
  - `fk_pre_requisito_atividade`: `codigo_atividade` → `ATIVIDADE(codigo_atividade)` (`ON DELETE CASCADE`, RR-03)
- **Restrições Relevantes da Tabela:**
  - PK composta impede a repetição do mesmo pré-requisito para a mesma atividade (RU-05)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_atividade` | `INT` | `NOT NULL` | PK (`pk_atividade_pre_requisito`), FK (`fk_pre_requisito_atividade`) | `ON DELETE CASCADE` a partir de `ATIVIDADE` |
| `pre_requisito` | `VARCHAR(255)` | `NOT NULL` | PK (`pk_atividade_pre_requisito`) | Descrição de um pré-requisito da atividade |

---

## 10. `PROFESSOR_AREA_PESQUISA`
- **Chave Primária (PK):** `pk_professor_area_pesquisa` — `(cpf_participante, area_pesquisa)` (RU-05)
- **Chaves Estrangeiras (FK):**
  - `fk_area_pesquisa_professor`: `cpf_participante` → `PROFESSOR(cpf_participante)` (`ON DELETE CASCADE`, RR-07)
- **Restrições Relevantes da Tabela:**
  - PK composta impede a repetição da mesma área de pesquisa para o mesmo professor (RU-05)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_professor_area_pesquisa`), FK (`fk_area_pesquisa_professor`) | `ON DELETE CASCADE` a partir de `PROFESSOR` |
| `area_pesquisa` | `VARCHAR(255)` | `NOT NULL` | PK (`pk_professor_area_pesquisa`) | Área de pesquisa do professor |

---

## 11. `MINISTRA`
- **Chave Primária (PK):** `pk_ministra` — `(cpf_palestrante, codigo_atividade)` (RU-04)
- **Chaves Estrangeiras (FK):**
  - `fk_ministra_palestrante`: `cpf_palestrante` → `PALESTRANTE(cpf_palestrante)` (`ON DELETE RESTRICT`, RR-05)
  - `fk_ministra_atividade`: `codigo_atividade` → `ATIVIDADE(codigo_atividade)` (`ON DELETE CASCADE`, RR-04)
  - `fk_ministra_sala`: `codigo_sala` → `SALA(codigo_sala)` (`ON DELETE RESTRICT`, RR-02 e RO-01)
- **Restrições Relevantes da Tabela:**
  - PK composta impede vincular o mesmo palestrante duas vezes à mesma atividade (RU-04)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `cpf_palestrante` | `VARCHAR(11)` | `NOT NULL` | PK (`pk_ministra`), FK (`fk_ministra_palestrante`) | `ON DELETE RESTRICT` |
| `codigo_atividade` | `INT` | `NOT NULL` | PK (`pk_ministra`), FK (`fk_ministra_atividade`) | `ON DELETE CASCADE` |
| `codigo_sala` | `INT` | `NOT NULL` | FK (`fk_ministra_sala`) | `ON DELETE RESTRICT`; RO-01 (toda atividade ministrada possui sala) |

---

## 12. `INSCRICAO`
- **Chave Primária (PK):** `pk_inscricao` — `(id_inscricao)`
- **Chaves Estrangeiras (FK):**
  - `fk_inscricao_participante`: `cpf_participante` → `PARTICIPANTE(cpf_participante)` (`ON DELETE RESTRICT`, RR-08)
  - `fk_inscricao_atividade`: `codigo_atividade` → `ATIVIDADE(codigo_atividade)` (`ON DELETE RESTRICT`, RR-09)
- **Restrições Relevantes da Tabela:**
  - `uk_inscricao`: `UNIQUE (cpf_participante, codigo_atividade)` (RU-02)
  - `chk_inscricao_status`: `CHECK (status IN ('Pendente', 'Confirmada', 'Cancelada'))` (RD-08)
  - `chk_inscricao_nota`: `CHECK (nota_avaliacao >= 0 AND nota_avaliacao <= 10)` (RD-09)
  - Gatilho `trg_valida_inscricao` (`03_objects.sql`): impõe **RO-04** (`nota_avaliacao` ou `comentario` exigem `data_hora_checkin` preenchido) e **RA-04** (`data_hora_checkin::DATE` dentro do intervalo `[data_inicio, data_fim]` do evento)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `id_inscricao` | `SERIAL` | `NOT NULL` | PK (`pk_inscricao`) | Autoincremento; identificador único da inscrição |
| `cpf_participante` | `VARCHAR(11)` | `NOT NULL` | FK (`fk_inscricao_participante`), UK (`uk_inscricao`) | `ON DELETE RESTRICT` |
| `codigo_atividade` | `INT` | `NOT NULL` | FK (`fk_inscricao_atividade`), UK (`uk_inscricao`) | `ON DELETE RESTRICT` |
| `data_inscricao` | `DATE` | `NOT NULL` | — | Data em que a inscrição foi realizada |
| `status` | `VARCHAR(50)` | `NOT NULL` | — | `DEFAULT 'Pendente'` (RO-03); `chk_inscricao_status`: `'Pendente'`, `'Confirmada'` ou `'Cancelada'` |
| `data_hora_checkin` | `TIMESTAMP` | `NULL` (Opcional) | — | Validado por `trg_valida_inscricao` (RA-04) |
| `nota_avaliacao` | `DECIMAL(4,2)` | `NULL` (Opcional) | — | `chk_inscricao_nota`: entre `0` e `10`; exige check-in via `trg_valida_inscricao` (RO-04) |
| `comentario` | `TEXT` | `NULL` (Opcional) | — | Exige check-in via `trg_valida_inscricao` (RO-04) |

---

## 13. `CERTIFICADO`
- **Chave Primária (PK):** `pk_certificado` — `(codigo_de_validacao)`
- **Chaves Estrangeiras (FK):**
  - `fk_certificado_inscricao`: `id_inscricao` → `INSCRICAO(id_inscricao)` (`ON DELETE RESTRICT`, RR-10 e RO-05)
- **Restrições Relevantes da Tabela:**
  - `uk_certificado_inscricao`: `UNIQUE (id_inscricao)` (RU-03 — garante cardinalidade 1:1 com `INSCRICAO`)
  - `chk_certificado_ch`: `CHECK (carga_horaria_certificada > 0)` (RD-03)
  - `chk_certificado_pdf`: `CHECK (link_pdf LIKE 'http%')` (RD-11)
  - Gatilho `trg_valida_certificado` (`03_objects.sql`): impõe **RA-02** (só emite certificado para inscrição com `data_hora_checkin` preenchido) e **RA-03** (`carga_horaria_certificada <= ATIVIDADE.carga_horaria`)

| Atributo | Tipo PostgreSQL | Obrigatoriedade | Chave | Restrições / Observações |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_de_validacao` | `VARCHAR(100)` | `NOT NULL` | PK (`pk_certificado`) | Código alfanumérico único de validação |
| `id_inscricao` | `INT` | `NOT NULL` | FK (`fk_certificado_inscricao`), UK (`uk_certificado_inscricao`) | `ON DELETE RESTRICT`; máximo 1 certificado por inscrição (RU-03) |
| `data_de_emissao` | `DATE` | `NOT NULL` | — | Data em que o certificado foi emitido |
| `carga_horaria_certificada` | `INT` | `NOT NULL` | — | `chk_certificado_ch` (`> 0`); `<= carga_horaria` da atividade via `trg_valida_certificado` (RA-03) |
| `link_pdf` | `VARCHAR(255)` | `NULL` (Opcional) | — | `chk_certificado_pdf`: deve iniciar com `http` |
| `observacao` | `TEXT` | `NULL` (Opcional) | — | Observação adicional sobre o certificado |
---

## Objetos físicos complementares

| Objeto | Tipo | Tabela(s) / referência | Finalidade |
| :--- | :--- | :--- | :--- |
| `vw_cronograma_atividades` | VIEW | `EVENTO`, `ATIVIDADE`, `MINISTRA`, `PALESTRANTE`, `SALA` | Consulta consolidada da programação, palestrantes e salas. |
| `vw_status_inscricoes` | VIEW | `INSCRICAO`, `PARTICIPANTE`, `ATIVIDADE` | Consulta consolidada de inscrições, status, check-in e avaliação. |
| `idx_participante_nome` | INDEX | `PARTICIPANTE(nome_participante)` | Apoia buscas e listagens por nome. |
| `idx_participante_email` | INDEX | `PARTICIPANTE(email_participante)` | Apoia buscas por e-mail. |
| `idx_evento_datas` | INDEX | `EVENTO(data_inicio, data_fim)` | Apoia consultas por período dos eventos. |
| `fn_valida_inscricao()` / `trg_valida_inscricao` | FUNCTION / TRIGGER | `INSCRICAO` | Aplica RO-04 e RA-04 antes de inserções e atualizações. |
| `fn_valida_certificado()` / `trg_valida_certificado` | FUNCTION / TRIGGER | `CERTIFICADO` | Aplica RA-02 e RA-03 antes de inserções e atualizações. |

## Observação sobre a especialização de PARTICIPANTE

A especialização de `PARTICIPANTE` em `ALUNO`, `PROFESSOR` e `EXTERNO` (RA-01) está indicada como regra de aplicação no modelo. O esquema físico apresentado não possui, neste momento, uma constraint ou trigger que imponha automaticamente a participação em exatamente uma dessas tabelas. Portanto, essa regra deve ser validada pela aplicação até que a equipe decida implementar uma regra adicional no banco.

## Ambiente de execução

O dicionário descreve o modelo físico PostgreSQL e não depende de hospedagem local ou remota. A mesma estrutura pode ser executada em uma instância PostgreSQL 16 local ou em um serviço PostgreSQL gerenciado, como o Neon, desde que o usuário tenha permissões para criar e remover os objetos do schema utilizado.
# 🎓 Sistema Gestor de Eventos Acadêmicos

![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-6.1-092E20?style=for-the-badge&logo=django&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white)
![Neon](https://img.shields.io/badge/Database-Neon-00E599?style=for-the-badge)
![Render](https://img.shields.io/badge/Deploy-Render-46E3B7?style=for-the-badge&logo=render&logoColor=black)

Aplicação web fullstack para gerenciamento de **eventos acadêmicos, atividades, participantes, inscrições, check-ins, avaliações e emissão de certificados**, desenvolvida como trabalho final da disciplina de **Banco de Dados** (integrando modelagem conceitual, projeto lógico relacional, implementação física em PostgreSQL e aplicação web em Django).

🌐 **Aplicação em Produção:** [sistema-gestor-eventos-academicos-1.onrender.com](https://sistema-gestor-eventos-academicos-1.onrender.com)  
> *Nota: por estar hospedada no plano gratuito do Render, a primeira requisição após um período de inatividade pode levar cerca de 45 a 60 segundos para reativar o servidor.*

---

## 📋 Sobre o Projeto

O sistema centraliza todo o ciclo de vida de eventos acadêmicos (como semanas de computação, palestras, minicursos e oficinas), garantindo a integridade dos dados diretamente no **PostgreSQL 16** por meio de restrições de domínio (`CHECK`), integridade referencial (`ON DELETE RESTRICT` / `CASCADE`), unicidade (`UNIQUE`), visões (`VIEW`), índices (`INDEX`) e gatilhos (`TRIGGER` em PL/pgSQL).

Os models do Django (`eventos/models.py`) utilizam `managed = False` para espelhar fielmente o esquema físico construído via scripts SQL na pasta `SQL-Scripts/`.

---

## ✨ Funcionalidades

- **Gestão de Eventos:** Cadastro, edição, listagem com busca por nome, visualização detalhada e exclusão protegida quando há atividades vinculadas.
- **Gestão de Atividades:** Criação, edição e remoção de atividades vinculadas a um evento (título, tipo, carga horária positiva e descrição).
- **Gestão de Participantes (Especialização Total e Exclusiva):**
  - Cadastro unificado com transação atômica (`transaction.atomic`) para **Aluno** (matrícula, curso, semestre, campus), **Professor** (titulação, departamento, Lattes) e **Externo** (instituição de origem, vínculo, cargo, cidade).
  - Filtro por nome, categoria e visualização geral ou filtrada por evento.
- **Inscrições, Check-in e Avaliação:**
  - Inscrição individual ou múltipla em atividades com controle de status (`Pendente`, `Confirmada`, `Cancelada`).
  - Check-in rápido ou completo com registro de data/hora, nota de avaliação (`0` a `10`) e comentário.
- **Emissão de Certificados:**
  - Geração automática de código de validação (`CERT-ANO-XXXXXX`), listagem e exclusão.
  - Disponibiliza apenas inscrições com check-in registrado e sem certificado prévio.
- **Relatórios SQL Analíticos:**
  - Consultas SQL diretas com `JOIN` (cronograma completo com evento, atividade, palestrante e sala), `GROUP BY` (atividades por evento) e `HAVING` (filtro dinâmico por quantidade mínima de inscritos).
- **Django Admin:** Interface administrativa configurada automaticamente para as tabelas compatíveis (ignorando models com `CompositePrimaryKey`).

---

## 🗄️ Arquitetura do Banco de Dados

O modelo físico é composto por **13 tabelas**, **2 views**, **3 índices** e **2 triggers**:

- **Tabelas principais:** `EVENTO`, `SALA`, `PALESTRANTE`, `PARTICIPANTE`, `ATIVIDADE`, `ALUNO`, `PROFESSOR`, `EXTERNO`, `ATIVIDADE_PRE_REQUISITO`, `PROFESSOR_AREA_PESQUISA`, `MINISTRA`, `INSCRICAO` e `CERTIFICADO`.
- **Views (`03_objects.sql`):**
  - `vw_cronograma_atividades`: consolida eventos, atividades, palestrantes e salas.
  - `vw_status_inscricoes`: consolida participantes, atividades, status, check-in e avaliações.
- **Índices (`03_objects.sql`):** `idx_participante_nome`, `idx_participante_email` e `idx_evento_datas`.
- **Gatilhos PL/pgSQL (`03_objects.sql`):**
  - `trg_valida_inscricao` (`fn_valida_inscricao`): impede nota/comentário sem check-in prévio e valida se a data do check-in está dentro do período `[data_inicio, data_fim]` do evento.
  - `trg_valida_certificado` (`fn_valida_certificado`): impede emitir certificado sem check-in e garante que `carga_horaria_certificada <= carga_horaria` da atividade.

📚 Documentação completa do banco:
- [Dicionário Físico de Dados](docs/05_dicionario_fisico.md)
- [Documentação de Implementação Física (TP3)](docs/README_tp3.md)

---

## 🛠️ Tecnologias Utilizadas

| Camada | Tecnologias |
|---|---|
| **Back-end** | Python 3.12, Django 6.1.3, Gunicorn |
| **Front-end** | Django Templates, HTML5, JavaScript, Bootstrap 5.3.3 |
| **Banco de Dados** | PostgreSQL 16 (hospedado no **Neon**) |
| **Driver & Conexão** | `psycopg[binary]` (v3), `dj-database-url`, `python-dotenv` |
| **Arquivos Estáticos** | WhiteNoise (`CompressedManifestStaticFilesStorage`) |
| **Deploy / Hospedagem** | Render (Web Service) + Neon (Serverless Postgres) |

---

## 📁 Estrutura do Repositório

```text
Sistema-Gestor-Eventos-Academicos/
├── docs/
│   ├── 05_dicionario_fisico.md     # Dicionário físico completo das 13 tabelas e objetos
│   └── README_tp3.md               # Roteiro e justificativas da implementação física
├── SQL-Scripts/
│   ├── 01_create.sql               # DDL: schema, tabelas, PKs, FKs, UNIQUE e CHECKs
│   ├── 02_insert.sql               # DML: massa de dados inicial para testes
│   ├── 03_objects.sql              # VIEWs, INDEXes, FUNCTIONs e TRIGGERs
│   └── 04_tests.sql                # Roteiro de testes das consultas e restrições
├── eventos/
│   ├── migrations/                 # Migrations do app (models com managed = False)
│   ├── templates/eventos/          # Templates HTML (Bootstrap 5)
│   ├── admin.py                    # Registro automático no Django Admin
│   ├── forms.py                    # Formulários Django
│   ├── models.py                   # Mapeamento ORM das tabelas do PostgreSQL
│   ├── urls.py                     # Rotas da aplicação
│   └── views.py                    # Regras de negócio, CRUDs e relatórios SQL
├── secomp/
│   ├── settings.py                 # Configurações de produção, Neon, WhiteNoise e logs
│   ├── urls.py                     # Roteamento raiz e /admin/
│   ├── wsgi.py                     # Ponto de entrada WSGI (Gunicorn)
│   └── asgi.py                     # Ponto de entrada ASGI
├── .env.example                    # Modelo das variáveis de ambiente locais
├── .gitignore
├── build.sh                        # Script de build do Render
├── manage.py
├── README.md
└── requirements.txt
```

---

## 🚀 Como Executar Localmente

### Pré-requisitos
- **Python 3.12+**
- **PostgreSQL 16** instalado localmente *ou* uma conta gratuita no **[Neon](https://neon.tech/)**
- **Git**

> **Importante:** Como o projeto utiliza recursos específicos do PostgreSQL (`SERIAL`, expressões regulares em `CHECK`, triggers em PL/pgSQL e `managed = False`), **é necessário utilizar um banco PostgreSQL** (não utilize SQLite).

### 1. Clonar o repositório
```bash
git clone https://github.com/Ramon-Venancio/Sistema-Gestor-Eventos-Academicos.git
cd Sistema-Gestor-Eventos-Academicos
git checkout feat/front
```

### 2. Criar e ativar o ambiente virtual
**Linux / macOS:**
```bash
python3 -m venv venv
source venv/bin/activate
```

**Windows (PowerShell):**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 3. Instalar as dependências
```bash
pip install -r requirements.txt
```

### 4. Configurar as variáveis de ambiente
Copie o arquivo de exemplo `.env.example` para `.env`:
```bash
cp .env.example .env
```

Edite o `.env` com os dados do seu ambiente local:
```env
DEBUG=True
SECRET_KEY=gere-uma-chave-secreta-aqui
ALLOWED_HOSTS=127.0.0.1,localhost
DATABASE_URL=postgresql://usuario:senha@localhost:5432/eventos_db
```
> Para gerar uma `SECRET_KEY` rapidamente pelo terminal:
> ```bash
> python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
> ```

### 5. Criar as tabelas e objetos no PostgreSQL / Neon
Execute os scripts da pasta `SQL-Scripts/` no seu banco PostgreSQL (via **pgAdmin 4**, **SQL Editor do Neon** ou **`psql`**) **exatamente nesta ordem**:

```bash
psql "SUA_DATABASE_URL" -f SQL-Scripts/01_create.sql
psql "SUA_DATABASE_URL" -f SQL-Scripts/02_insert.sql
psql "SUA_DATABASE_URL" -f SQL-Scripts/03_objects.sql
```
*(Opcional)* Execute `SQL-Scripts/04_tests.sql` para validar as consultas e regras de negócio.

### 6. Aplicar as migrations internas do Django
> ⚠️ **Execute este passo obrigatoriamente DEPOIS de rodar o `01_create.sql`**, pois o script SQL recria o schema `public` (`DROP SCHEMA IF EXISTS public CASCADE`).

```bash
python manage.py migrate
```

*(Opcional)* Para acessar o painel `/admin/`, crie um superusuário:
```bash
python manage.py createsuperuser
```

### 7. Iniciar o servidor de desenvolvimento
```bash
python manage.py runserver
```

Acesse no navegador: **`http://127.0.0.1:8000/`**

---

## ☁️ Deploy em Produção (Render + Neon)

1. Execute `01_create.sql`, `02_insert.sql` e `03_objects.sql` no banco de produção do **Neon**.
2. Crie um **Web Service** no **Render** conectado ao repositório com:
   - **Build Command:** `./build.sh`
   - **Start Command:** `gunicorn secomp.wsgi:application`
3. Configure as seguintes **Environment Variables** no Render:
   - `PYTHON_VERSION` = `3.12.7`
   - `DEBUG` = `False`
   - `SECRET_KEY` = *(chave aleatória forte de produção)*
   - `ALLOWED_HOSTS` = `seu-app.onrender.com`
   - `DATABASE_URL` = *(Connection String do Neon com `-pooler` e `?sslmode=require`)*

---

## 🧭 Principais Rotas da Aplicação

| Rota | Descrição |
|---|---|
| `/` | Listagem, busca e gerenciamento de eventos |
| `/eventos/<id>/` | Detalhes do evento, atividades e participantes vinculados |
| `/eventos/<id>/atividades/` | CRUD de atividades do evento |
| `/participantes/` | Listagem geral de participantes, categorias, check-in e inscrições |
| `/inscricoes/` | Painel geral de inscrições e check-ins |
| `/inscricoes/nova/` | Inscrição múltipla de participante em atividades |
| `/certificados/` | Listagem e emissão de certificados |
| `/relatorios/join/` | Relatório SQL: Cronograma (`JOIN`) |
| `/relatorios/group-by/` | Relatório SQL: Atividades por Evento (`GROUP BY`) |
| `/relatorios/having/` | Relatório SQL: Eventos por mínimo de inscritos (`HAVING`) |
| `/admin/` | Painel administrativo do Django |

---

## 👥 Equipe 1

- **João Lucas Simões Rocha da Silveira**
- **José Moisés da Silva Lima**
- **Ramon Venâncio da Silva**
- **Yan de Freitas Cândido**

---

<p align="center">
  Desenvolvido para a disciplina de Banco de Dados — Sistema Gestor de Eventos Acadêmicos.
</p>
-- ==============================================================================
-- Arquivo: 02_insert.sql
-- Equipe 1: João Lucas, Moisés, Ramon e Yan
-- Objetivo: Inserção de dados nas 13 tabelas do modelo físico (TP3)
-- ==============================================================================

-- ==============================================================================
-- 1. TABELAS INDEPENDENTES
-- ==============================================================================

-- EVENTO
-- (codigo_evento é SERIAL, então omitimos na listagem de colunas para gerar automático)
INSERT INTO EVENTO (nome_evento, data_inicio, data_fim, descricao_evento, email_contato) VALUES
('Tech Week 2026', '2026-12-01', '2026-12-05', 'Semana de Tecnologia da Informação', 'contato@techweek.com'),
('Simpósio de IA', '2026-11-20', '2026-11-21', 'Encontro sobre Inteligência Artificial', 'ia@simposio.br');

-- SALA
INSERT INTO SALA (nome_sala, capacidade, bloco, andar) VALUES
('Laboratório 1', 30, 'Bloco C', 1),
('Auditório Principal', 200, 'Bloco Central', 0);

-- PALESTRANTE
INSERT INTO PALESTRANTE (cpf_palestrante, nome_palestrante, email_palestrante, minicurriculo, instituicao, link_lattes) VALUES
('11111111111', 'Dr. Alan Souza', 'alan@universidade.br', 'Especialista em Banco de Dados', 'Universidade Federal', 'http://lattes.cnpq.br/111'),
('22222222222', 'Profa. Ada Costa', 'ada@tech.com', 'Engenheira de Machine Learning', 'Tech Institute', 'http://lattes.cnpq.br/222');

-- PARTICIPANTE (Vamos cadastrar 3 para cobrir Aluno, Professor e Externo)
INSERT INTO PARTICIPANTE (cpf_participante, nome_participante, email_participante, telefone_participante, data_nascimento) VALUES
('33333333333', 'João Lucas', 'joao@email.com', '85999999999', '2001-05-15'),
('44444444444', 'Maria Oliveira', 'maria@email.com', '85988888888', '1985-08-20'),
('55555555555', 'Carlos Mendes', 'carlos@empresa.com', '85977777777', '1992-11-30');


-- ==============================================================================
-- 2. TABELAS DEPENDENTES NÍVEL 1
-- ==============================================================================

-- ATIVIDADE (Usa codigo_evento = 1, gerado automaticamente no primeiro insert)
INSERT INTO ATIVIDADE (codigo_evento, titulo, tipo, carga_horaria, descricao_atividade) VALUES
(1, 'Oficina de PostgreSQL', 'Minicurso', 4, 'Modelagem e queries avançadas'),
(1, 'O Futuro da IA', 'Palestra', 2, 'Impactos da inteligência artificial no mercado');

-- ALUNO (Especialização do Participante 33333333333)
INSERT INTO ALUNO (cpf_participante, matricula, curso, semestre, campus) VALUES
('33333333333', '20260101', 'Ciência da Computação', 5, 'Itaperi');

-- PROFESSOR (Especialização do Participante 44444444444)
INSERT INTO PROFESSOR (cpf_participante, titulacao, departamento, link_lattes) VALUES
('44444444444', 'Doutora', 'Departamento de Computação', 'http://lattes.cnpq.br/444');

-- EXTERNO (Especialização do Participante 55555555555)
INSERT INTO EXTERNO (cpf_participante, instituicao_origem, tipo_vinculo, cargo, cidade) VALUES
('55555555555', 'Empresa TechData', 'Convidado', 'Desenvolvedor Senior', 'Fortaleza');


-- ==============================================================================
-- 3. TABELAS DEPENDENTES NÍVEL 2 (Associativas e Multivalorados)
-- ==============================================================================

-- ATIVIDADE_PRE_REQUISITO (Referencia a atividade 1)
INSERT INTO ATIVIDADE_PRE_REQUISITO (codigo_atividade, pre_requisito) VALUES
(1, 'Lógica de Programação'),
(1, 'Modelagem de Dados Básica');

-- PROFESSOR_AREA_PESQUISA (Referencia a professora Maria)
INSERT INTO PROFESSOR_AREA_PESQUISA (cpf_participante, area_pesquisa) VALUES
('44444444444', 'Engenharia de Software'),
('44444444444', 'Sistemas de Informação');

-- MINISTRA (Associa Palestrante, Atividade e Sala)
INSERT INTO MINISTRA (cpf_palestrante, codigo_atividade, codigo_sala) VALUES
('11111111111', 1, 1), -- Alan ministra Oficina de PostgreSQL no Lab 1
('22222222222', 2, 2); -- Ada ministra Palestra de IA no Auditório

-- INSCRICAO (Participante João na Oficina de PostgreSQL)
INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao, status, data_hora_checkin, nota_avaliacao, comentario) VALUES
('33333333333', 1, '2026-11-15', 'Confirmada', '2026-12-01 08:00:00', 9.5, 'Excelente didática!');

-- CERTIFICADO (Gerado para a Inscrição 1 do João)
INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada, link_pdf, observacao) VALUES
('CERT-2026-001', 1, '2026-12-06', 4, 'http://certificados.evento.br/001', 'Certificado validado eletronicamente');
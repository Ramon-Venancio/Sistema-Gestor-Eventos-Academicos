INSERT INTO EVENTO (nome_evento, data_inicio, data_fim, descricao_evento, email_contato) VALUES
('Tech Week 2026', '2026-12-01', '2026-12-05', 'Semana de Tecnologia da Informação', 'contato@techweek.com'),
('Simpósio de IA', '2026-11-20', '2026-11-21', 'Encontro sobre Inteligência Artificial', 'ia@simposio.br');

INSERT INTO SALA (nome_sala, capacidade, bloco, andar) VALUES
('Laboratório 1', 30, 'Bloco C', 1),
('Auditório Principal', 200, 'Bloco Central', 0);

INSERT INTO PALESTRANTE (cpf_palestrante, nome_palestrante, email_palestrante, minicurriculo, instituicao, link_lattes) VALUES
('11111111111', 'Dr. Alan Souza', 'alan@universidade.br', 'Especialista em Banco de Dados', 'Universidade Federal', 'http://lattes.cnpq.br/111'),
('22222222222', 'Profa. Ada Costa', 'ada@tech.com', 'Engenheira de Machine Learning', 'Tech Institute', 'http://lattes.cnpq.br/222');

INSERT INTO PARTICIPANTE (cpf_participante, nome_participante, email_participante, telefone_participante, data_nascimento) VALUES
('33333333333', 'João Lucas', 'joao@email.com', '85999999999', '2001-05-15'),
('44444444444', 'Maria Oliveira', 'maria@email.com', '85988888888', '1985-08-20'),
('55555555555', 'Carlos Mendes', 'carlos@empresa.com', '85977777777', '1992-11-30');


INSERT INTO ATIVIDADE (codigo_evento, titulo, tipo, carga_horaria, descricao_atividade) VALUES
(1, 'Oficina de PostgreSQL', 'Minicurso', 4, 'Modelagem e queries avançadas'),
(1, 'O Futuro da IA', 'Palestra', 2, 'Impactos da inteligência artificial no mercado');

INSERT INTO ALUNO (cpf_participante, matricula, curso, semestre, campus) VALUES
('33333333333', '20260101', 'Ciência da Computação', 5, 'Itaperi');

INSERT INTO PROFESSOR (cpf_participante, titulacao, departamento, link_lattes) VALUES
('44444444444', 'Doutora', 'Departamento de Computação', 'http://lattes.cnpq.br/444');

INSERT INTO EXTERNO (cpf_participante, instituicao_origem, tipo_vinculo, cargo, cidade) VALUES
('55555555555', 'Empresa TechData', 'Convidado', 'Desenvolvedor Senior', 'Fortaleza');


INSERT INTO ATIVIDADE_PRE_REQUISITO (codigo_atividade, pre_requisito) VALUES
(1, 'Lógica de Programação'),
(1, 'Modelagem de Dados Básica');

INSERT INTO PROFESSOR_AREA_PESQUISA (cpf_participante, area_pesquisa) VALUES
('44444444444', 'Engenharia de Software'),
('44444444444', 'Sistemas de Informação');

INSERT INTO MINISTRA (cpf_palestrante, codigo_atividade, codigo_sala) VALUES
('11111111111', 1, 1), 
('22222222222', 2, 2); 

INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao, status, data_hora_checkin, nota_avaliacao, comentario) VALUES
('33333333333', 1, '2026-11-15', 'Confirmada', '2026-12-01 08:00:00', 9.5, 'Excelente didática!');

INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada, link_pdf, observacao) VALUES
('CERT-2026-001', 1, '2026-12-06', 4, 'http://certificados.evento.br/001', 'Certificado validado eletronicamente');
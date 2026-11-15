-- ==============================================================================
-- Arquivo: 04_tests.sql
-- Equipe 1: João Lucas, Moisés, Ramon e Yan
-- Objetivo: Testes de Consultas, Visões e Validação de Gatilhos (Regras de Negócio)
-- ==============================================================================

-- ==============================================================================
-- 1. TESTE DAS VISÕES (VIEWS)
-- ==============================================================================

-- Lista o cronograma completo agrupando atividades, eventos e salas
SELECT * FROM vw_cronograma_atividades;

-- Lista o status de todos os participantes e suas respectivas atividades
SELECT * FROM vw_status_inscricoes;

-- ==============================================================================
-- 2. CONSULTAS COM JUNÇÕES (JOINs) E AGREGAÇÕES (GROUP BY)
-- ==============================================================================

-- Quantidade de atividades por evento
SELECT 
    e.nome_evento, 
    COUNT(a.codigo_atividade) AS total_atividades
FROM EVENTO e
LEFT JOIN ATIVIDADE a ON e.codigo_evento = a.codigo_evento
GROUP BY e.nome_evento;

-- Lista de palestrantes, as atividades que ministram e onde
SELECT 
    p.nome_palestrante,
    a.titulo AS atividade_ministrada,
    s.nome_sala
FROM MINISTRA m
JOIN PALESTRANTE p ON m.cpf_palestrante = p.cpf_palestrante
JOIN ATIVIDADE a ON m.codigo_atividade = a.codigo_atividade
JOIN SALA s ON m.codigo_sala = s.codigo_sala;


-- ==============================================================================
-- 3. TESTE DOS GATILHOS (BLOQUEIOS DE REGRAS DE NEGÓCIO)
-- ATENÇÃO: As queries abaixo DEVEM falhar para provar que a segurança funciona.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- TESTE RO-04: Tentar inserir avaliação sem ter feito check-in
-- RESULTADO ESPERADO: Erro "RO-04: Avaliação ou comentário exigem o registro..."
-- ------------------------------------------------------------------------------
INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao, nota_avaliacao) 
VALUES ('44444444444', 1, CURRENT_DATE, 10.0);

-- ------------------------------------------------------------------------------
-- TESTE RA-04: Tentar fazer check-in numa data fora do período do evento
-- O Evento 1 (Tech Week) ocorre entre '2026-12-01' e '2026-12-05'.
-- RESULTADO ESPERADO: Erro "RA-04: Data de check-in fora do período do evento."
-- ------------------------------------------------------------------------------
UPDATE INSCRICAO 
SET data_hora_checkin = '2026-11-10 08:00:00' 
WHERE id_inscricao = 1;

-- ------------------------------------------------------------------------------
-- PREPARAÇÃO PARA OS PRÓXIMOS TESTES: Inserir uma inscrição limpa (sem check-in)
-- ------------------------------------------------------------------------------
INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao) 
VALUES ('55555555555', 2, CURRENT_DATE);
-- (Esta inscrição recebe automaticamente o id_inscricao = 2)

-- ------------------------------------------------------------------------------
-- TESTE RA-02: Tentar emitir certificado para inscrição sem check-in
-- RESULTADO ESPERADO: Erro "RA-02: Certificado não pode ser emitido sem check-in..."
-- ------------------------------------------------------------------------------
INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada) 
VALUES ('CERT-TESTE-01', 2, CURRENT_DATE, 2);

-- ------------------------------------------------------------------------------
-- TESTE RA-03: Tentar emitir certificado com carga horária maior que a atividade
-- A inscrição 1 é da Atividade 1, que tem apenas 4 horas.
-- RESULTADO ESPERADO: Erro "RA-03: Carga horária do certificado excede o limite..."
-- ------------------------------------------------------------------------------
INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada) 
VALUES ('CERT-TESTE-02', 1, CURRENT_DATE, 10);
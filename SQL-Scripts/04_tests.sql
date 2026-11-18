SELECT
    e.nome_evento,
    a.titulo AS atividade,
    p.nome_palestrante,
    s.nome_sala,
    s.bloco
FROM ATIVIDADE a
JOIN EVENTO e ON e.codigo_evento = a.codigo_evento
JOIN MINISTRA m ON m.codigo_atividade = a.codigo_atividade
JOIN PALESTRANTE p ON p.cpf_palestrante = m.cpf_palestrante
JOIN SALA s ON s.codigo_sala = m.codigo_sala
ORDER BY e.nome_evento, a.titulo;


SELECT
    e.codigo_evento,
    e.nome_evento,
    COUNT(a.codigo_atividade) AS total_atividades
FROM EVENTO e
LEFT JOIN ATIVIDADE a ON a.codigo_evento = e.codigo_evento
GROUP BY e.codigo_evento, e.nome_evento
ORDER BY e.codigo_evento;


SELECT
    e.nome_evento,
    COUNT(a.codigo_atividade) AS total_atividades
FROM EVENTO e
JOIN ATIVIDADE a ON a.codigo_evento = e.codigo_evento
GROUP BY e.codigo_evento, e.nome_evento
HAVING COUNT(a.codigo_atividade) >= 2
ORDER BY e.nome_evento;


SELECT
    a.titulo,
    a.carga_horaria
FROM ATIVIDADE a
WHERE a.carga_horaria > (
    SELECT AVG(a2.carga_horaria)
    FROM ATIVIDADE a2
)
ORDER BY a.carga_horaria DESC;


SELECT *
FROM vw_cronograma_atividades
ORDER BY nome_evento, atividade;

SELECT *
FROM vw_status_inscricoes
ORDER BY id_inscricao;


SET enable_seqscan = OFF;

EXPLAIN
SELECT cpf_participante, nome_participante, email_participante
FROM PARTICIPANTE
WHERE email_participante = 'joao@email.com';

RESET enable_seqscan;

SELECT cpf_participante, nome_participante, email_participante
FROM PARTICIPANTE
WHERE email_participante = 'joao@email.com';


DO $$
DECLARE
    v_bloqueou BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO SALA (nome_sala, capacidade)
        VALUES ('Sala inválida - teste CHECK', 0);
    EXCEPTION
        WHEN check_violation THEN
            v_bloqueou := TRUE;
            RAISE NOTICE 'OK: chk_sala_capacidade impediu capacidade igual a zero.';
    END;

    IF NOT v_bloqueou THEN
        RAISE EXCEPTION
            'FALHA NO TESTE: a restrição chk_sala_capacidade não bloqueou o valor inválido.';
    END IF;
END;
$$;


DO $$
DECLARE
    v_bloqueou BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO INSCRICAO
            (cpf_participante, codigo_atividade, data_inscricao, nota_avaliacao)
        VALUES
            ('44444444444', 1, CURRENT_DATE, 9.00);
    EXCEPTION
        WHEN raise_exception THEN
            v_bloqueou := TRUE;
            RAISE NOTICE 'OK: trg_valida_inscricao aplicou RO-04 (avaliação exige check-in).';
    END;

    IF NOT v_bloqueou THEN
        RAISE EXCEPTION
            'FALHA NO TESTE: RO-04 não impediu avaliação sem check-in.';
    END IF;
END;
$$;


DO $$
DECLARE
    v_bloqueou BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE INSCRICAO
            SET data_hora_checkin = TIMESTAMP '2026-11-10 08:00:00'
            WHERE cpf_participante = '33333333333'
            AND codigo_atividade = 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'FALHA NO TESTE: inscrição de referência não foi encontrada.';
        END IF;
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'RA-04:%' THEN
                v_bloqueou := TRUE;
                RAISE NOTICE 'OK: trg_valida_inscricao aplicou RA-04 (check-in fora do período).';
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT v_bloqueou THEN
        RAISE EXCEPTION
            'FALHA NO TESTE: RA-04 não impediu check-in fora do período.';
    END IF;
END;
$$;


DO $$
DECLARE
    v_id_inscricao INT;
BEGIN
    INSERT INTO INSCRICAO
        (cpf_participante, codigo_atividade, data_inscricao, status,
        data_hora_checkin, nota_avaliacao, comentario)
    VALUES
        ('44444444444', 3, CURRENT_DATE, 'Confirmada',
        TIMESTAMP '2026-11-20 09:00:00', 8.50, 'Teste de caminho válido do gatilho.')
    RETURNING id_inscricao INTO v_id_inscricao;

    RAISE NOTICE 'OK: inscrição válida aceita pelo gatilho (id_inscricao=%).', v_id_inscricao;

    DELETE FROM INSCRICAO
    WHERE id_inscricao = v_id_inscricao;
END;
$$;


INSERT INTO INSCRICAO
    (cpf_participante, codigo_atividade, data_inscricao, status)
VALUES
    ('55555555555', 2, CURRENT_DATE, 'Pendente')
ON CONFLICT (cpf_participante, codigo_atividade) DO NOTHING;

UPDATE INSCRICAO
    SET data_hora_checkin = NULL,
        nota_avaliacao = NULL,
        comentario = NULL,
        status = 'Pendente'
    WHERE cpf_participante = '55555555555'
    AND codigo_atividade = 2;


DO $$
DECLARE
    v_id_inscricao INT;
    v_bloqueou BOOLEAN := FALSE;
BEGIN
    SELECT id_inscricao
        INTO v_id_inscricao
        FROM INSCRICAO
        WHERE cpf_participante = '55555555555'
        AND codigo_atividade = 2;

    BEGIN
        INSERT INTO CERTIFICADO
            (codigo_de_validacao, id_inscricao, data_de_emissao,
            carga_horaria_certificada, link_pdf)
        VALUES
            ('CERT-TESTE-RA02', v_id_inscricao, CURRENT_DATE,
            2, 'http://certificados.evento.br/teste-ra02');
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'RA-02:%' THEN
                v_bloqueou := TRUE;
                RAISE NOTICE 'OK: trg_valida_certificado aplicou RA-02 (certificado exige check-in).';
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT v_bloqueou THEN
        RAISE EXCEPTION
            'FALHA NO TESTE: RA-02 não impediu certificado sem check-in.';
    END IF;
END;
$$;


DO $$
DECLARE
    v_id_inscricao INT;
    v_bloqueou BOOLEAN := FALSE;
BEGIN
    SELECT id_inscricao
        INTO v_id_inscricao
        FROM INSCRICAO
        WHERE cpf_participante = '33333333333'
        AND codigo_atividade = 1;

    BEGIN
        INSERT INTO CERTIFICADO
            (codigo_de_validacao, id_inscricao, data_de_emissao,
            carga_horaria_certificada, link_pdf)
        VALUES
            ('CERT-TESTE-RA03', v_id_inscricao, CURRENT_DATE,
            10, 'http://certificados.evento.br/teste-ra03');
    EXCEPTION
        WHEN raise_exception THEN
            IF SQLERRM LIKE 'RA-03:%' THEN
                v_bloqueou := TRUE;
                RAISE NOTICE 'OK: trg_valida_certificado aplicou RA-03 (carga horária excedente).';
            ELSE
                RAISE;
            END IF;
    END;

    IF NOT v_bloqueou THEN
        RAISE EXCEPTION
            'FALHA NO TESTE: RA-03 não impediu carga horária certificada excedente.';
    END IF;
END;
$$;


BEGIN;

INSERT INTO EVENTO
    (nome_evento, data_inicio, data_fim, descricao_evento, email_contato)
VALUES
    ('Evento temporário - teste de transação', DATE '2027-01-10', DATE '2027-01-10',
    'Registro criado apenas para demonstrar ROLLBACK.', 'teste@transacao.br');

SELECT codigo_evento, nome_evento
FROM EVENTO
WHERE nome_evento = 'Evento temporário - teste de transação';

ROLLBACK;

SELECT codigo_evento, nome_evento
FROM EVENTO
WHERE nome_evento = 'Evento temporário - teste de transação';
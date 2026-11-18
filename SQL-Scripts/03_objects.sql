DROP VIEW IF EXISTS vw_cronograma_atividades;
CREATE VIEW vw_cronograma_atividades AS
SELECT
    e.codigo_evento,
    e.nome_evento,
    a.codigo_atividade,
    a.titulo AS atividade,
    a.tipo,
    a.carga_horaria,
    p.nome_palestrante,
    s.codigo_sala,
    s.nome_sala,
    s.bloco
FROM ATIVIDADE a
JOIN EVENTO e
    ON e.codigo_evento = a.codigo_evento
JOIN MINISTRA m
    ON m.codigo_atividade = a.codigo_atividade
JOIN PALESTRANTE p
    ON p.cpf_palestrante = m.cpf_palestrante
JOIN SALA s
    ON s.codigo_sala = m.codigo_sala;

DROP VIEW IF EXISTS vw_status_inscricoes;
CREATE VIEW vw_status_inscricoes AS
SELECT
    i.id_inscricao,
    p.nome_participante,
    p.cpf_participante,
    a.titulo AS atividade,
    i.status,
    i.data_inscricao,
    i.data_hora_checkin,
    i.nota_avaliacao,
    i.comentario
FROM INSCRICAO i
JOIN PARTICIPANTE p
    ON p.cpf_participante = i.cpf_participante
JOIN ATIVIDADE a
    ON a.codigo_atividade = i.codigo_atividade;

CREATE INDEX IF NOT EXISTS idx_participante_nome
    ON PARTICIPANTE (nome_participante);

CREATE INDEX IF NOT EXISTS idx_participante_email
    ON PARTICIPANTE (email_participante);

CREATE INDEX IF NOT EXISTS idx_evento_datas
    ON EVENTO (data_inicio, data_fim);


CREATE OR REPLACE FUNCTION fn_valida_inscricao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_data_inicio DATE;
    v_data_fim DATE;
BEGIN
    IF (NEW.nota_avaliacao IS NOT NULL OR NEW.comentario IS NOT NULL)
        AND NEW.data_hora_checkin IS NULL THEN
        RAISE EXCEPTION
            'RO-04: Avaliação ou comentário exigem o registro de check-in do participante.';
    END IF;

    IF NEW.data_hora_checkin IS NOT NULL THEN
        SELECT e.data_inicio, e.data_fim
            INTO v_data_inicio, v_data_fim
            FROM ATIVIDADE a
            JOIN EVENTO e ON e.codigo_evento = a.codigo_evento
            WHERE a.codigo_atividade = NEW.codigo_atividade;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'RA-04: Não foi possível localizar o evento da atividade informada.';
        END IF;

        IF NEW.data_hora_checkin::DATE < v_data_inicio
            OR NEW.data_hora_checkin::DATE > v_data_fim THEN
            RAISE EXCEPTION
                'RA-04: Data de check-in (%) fora do período do evento (% a %).',
                NEW.data_hora_checkin::DATE, v_data_inicio, v_data_fim;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_valida_inscricao ON INSCRICAO;
CREATE TRIGGER trg_valida_inscricao
BEFORE INSERT OR UPDATE ON INSCRICAO
FOR EACH ROW
EXECUTE FUNCTION fn_valida_inscricao();


CREATE OR REPLACE FUNCTION fn_valida_certificado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_checkin TIMESTAMP;
    v_carga_atividade INT;
BEGIN
    SELECT i.data_hora_checkin, a.carga_horaria
        INTO v_checkin, v_carga_atividade
        FROM INSCRICAO i
        JOIN ATIVIDADE a ON a.codigo_atividade = i.codigo_atividade
        WHERE i.id_inscricao = NEW.id_inscricao;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'RA-02: A inscrição informada não foi encontrada.';
    END IF;

    IF v_checkin IS NULL THEN
        RAISE EXCEPTION
            'RA-02: Certificado não pode ser emitido sem check-in registrado na inscrição correspondente.';
    END IF;

    IF NEW.carga_horaria_certificada > v_carga_atividade THEN
        RAISE EXCEPTION
            'RA-03: Carga horária do certificado (%) excede o limite da atividade (%).',
            NEW.carga_horaria_certificada, v_carga_atividade;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_valida_certificado ON CERTIFICADO;
CREATE TRIGGER trg_valida_certificado
BEFORE INSERT OR UPDATE ON CERTIFICADO
FOR EACH ROW
EXECUTE FUNCTION fn_valida_certificado();

SELECT table_name AS view_criada
FROM information_schema.views
WHERE table_schema = 'public'
    AND table_name IN ('vw_cronograma_atividades', 'vw_status_inscricoes')
ORDER BY table_name;

SELECT indexname AS indice_criado, tablename AS tabela
FROM pg_indexes
WHERE schemaname = 'public'
    AND indexname IN ('idx_participante_nome', 'idx_participante_email', 'idx_evento_datas')
ORDER BY indexname;

SELECT trigger_name AS gatilho_criado, event_object_table AS tabela
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name IN ('trg_valida_inscricao', 'trg_valida_certificado')
ORDER BY trigger_name;
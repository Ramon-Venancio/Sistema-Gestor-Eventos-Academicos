CREATE OR REPLACE VIEW vw_cronograma_atividades AS
SELECT 
    e.nome_evento,
    a.titulo AS atividade,
    a.tipo,
    a.carga_horaria,
    s.nome_sala,
    s.bloco
FROM ATIVIDADE a
JOIN EVENTO e ON a.codigo_evento = e.codigo_evento
JOIN SALA s ON a.codigo_atividade IN (SELECT codigo_atividade FROM MINISTRA m WHERE m.codigo_sala = s.codigo_sala LIMIT 1);

CREATE OR REPLACE VIEW vw_status_inscricoes AS
SELECT 
    p.nome_participante,
    p.cpf_participante,
    a.titulo AS atividade,
    i.status,
    i.data_hora_checkin
FROM INSCRICAO i
JOIN PARTICIPANTE p ON i.cpf_participante = p.cpf_participante
JOIN ATIVIDADE a ON i.codigo_atividade = a.codigo_atividade;


CREATE INDEX idx_participante_nome ON PARTICIPANTE(nome_participante);
CREATE INDEX idx_participante_email ON PARTICIPANTE(email_participante);
CREATE INDEX idx_evento_datas ON EVENTO(data_inicio, data_fim);


CREATE OR REPLACE FUNCTION fn_valida_inscricao() RETURNS TRIGGER AS $$
DECLARE
    v_data_inicio DATE;
    v_data_fim DATE;
BEGIN
    IF (NEW.nota_avaliacao IS NOT NULL OR NEW.comentario IS NOT NULL) AND NEW.data_hora_checkin IS NULL THEN
        RAISE EXCEPTION 'RO-04: Avaliação ou comentário exigem o registro de check-in do participante.';
    END IF;

    IF NEW.data_hora_checkin IS NOT NULL THEN
        SELECT e.data_inicio, e.data_fim
        INTO v_data_inicio, v_data_fim
        FROM ATIVIDADE a
        JOIN EVENTO e ON a.codigo_evento = e.codigo_evento
        WHERE a.codigo_atividade = NEW.codigo_atividade;

        IF NEW.data_hora_checkin::DATE < v_data_inicio OR NEW.data_hora_checkin::DATE > v_data_fim THEN
            RAISE EXCEPTION 'RA-04: Data de check-in (%) fora do período do evento (% a %).', NEW.data_hora_checkin::DATE, v_data_inicio, v_data_fim;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_inscricao
BEFORE INSERT OR UPDATE ON INSCRICAO
FOR EACH ROW EXECUTE FUNCTION fn_valida_inscricao();


CREATE OR REPLACE FUNCTION fn_valida_certificado() RETURNS TRIGGER AS $$
DECLARE
    v_checkin TIMESTAMP;
    v_carga_atividade INT;
BEGIN
    SELECT i.data_hora_checkin, a.carga_horaria
    INTO v_checkin, v_carga_atividade
    FROM INSCRICAO i
    JOIN ATIVIDADE a ON i.codigo_atividade = a.codigo_atividade
    WHERE i.id_inscricao = NEW.id_inscricao;

    IF v_checkin IS NULL THEN
        RAISE EXCEPTION 'RA-02: Certificado não pode ser emitido sem check-in registrado na inscrição correspondente.';
    END IF;

    IF NEW.carga_horaria_certificada > v_carga_atividade THEN
        RAISE EXCEPTION 'RA-03: Carga horária do certificado (%) excede o limite da atividade (%).', NEW.carga_horaria_certificada, v_carga_atividade;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_certificado
BEFORE INSERT OR UPDATE ON CERTIFICADO
FOR EACH ROW EXECUTE FUNCTION fn_valida_certificado();
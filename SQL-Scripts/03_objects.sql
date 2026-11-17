-- ==============================================================================
-- Arquivo: 03_objects.sql
-- Equipe 1: João Lucas, Moisés, Ramon e Yan
-- Objetivo: Criação de Views, Índices e Triggers (Regras de Negócio do TP2)
-- ==============================================================================

-- ==============================================================================
-- 1. VISÕES (VIEWS) - Consultas pré-programadas para facilitar relatórios
-- ==============================================================================

-- View para listar as Atividades com os dados do Evento e da Sala
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

-- View para ver a situação das inscrições dos participantes
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


-- ==============================================================================
-- 2. ÍNDICES (INDEXES) - Otimização de performance para o banco
-- ==============================================================================

-- Acelera buscas por nome e e-mail (muito usado no back-end Django depois)
CREATE INDEX idx_participante_nome ON PARTICIPANTE(nome_participante);
CREATE INDEX idx_participante_email ON PARTICIPANTE(email_participante);
CREATE INDEX idx_evento_datas ON EVENTO(data_inicio, data_fim);


-- ==============================================================================
-- 3. FUNÇÕES E GATILHOS (TRIGGERS) - Implementação das Regras de Negócio (RA/RO)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Regra RO-04: Nota/Comentário exige check-in
-- Regra RA-04: Check-in deve estar dentro do período do evento
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_valida_inscricao() RETURNS TRIGGER AS $$
DECLARE
    v_data_inicio DATE;
    v_data_fim DATE;
BEGIN
    -- Validação RO-04
    IF (NEW.nota_avaliacao IS NOT NULL OR NEW.comentario IS NOT NULL) AND NEW.data_hora_checkin IS NULL THEN
        RAISE EXCEPTION 'RO-04: Avaliação ou comentário exigem o registro de check-in do participante.';
    END IF;

    -- Validação RA-04
    IF NEW.data_hora_checkin IS NOT NULL THEN
        -- Busca as datas do evento relacionado a esta atividade
        SELECT e.data_inicio, e.data_fim
        INTO v_data_inicio, v_data_fim
        FROM ATIVIDADE a
        JOIN EVENTO e ON a.codigo_evento = e.codigo_evento
        WHERE a.codigo_atividade = NEW.codigo_atividade;

        -- Verifica se o check-in vazou das datas do evento
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


-- ------------------------------------------------------------------------------
-- Regra RA-02: Certificado exige check-in na inscrição
-- Regra RA-03: Carga horária certificada não pode superar a da atividade
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_valida_certificado() RETURNS TRIGGER AS $$
DECLARE
    v_checkin TIMESTAMP;
    v_carga_atividade INT;
BEGIN
    -- Busca os dados cruzados de Inscrição e Atividade
    SELECT i.data_hora_checkin, a.carga_horaria
    INTO v_checkin, v_carga_atividade
    FROM INSCRICAO i
    JOIN ATIVIDADE a ON i.codigo_atividade = a.codigo_atividade
    WHERE i.id_inscricao = NEW.id_inscricao;

    -- Validação RA-02
    IF v_checkin IS NULL THEN
        RAISE EXCEPTION 'RA-02: Certificado não pode ser emitido sem check-in registrado na inscrição correspondente.';
    END IF;

    -- Validação RA-03
    IF NEW.carga_horaria_certificada > v_carga_atividade THEN
        RAISE EXCEPTION 'RA-03: Carga horária do certificado (%) excede o limite da atividade (%).', NEW.carga_horaria_certificada, v_carga_atividade;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_certificado
BEFORE INSERT OR UPDATE ON CERTIFICADO
FOR EACH ROW EXECUTE FUNCTION fn_valida_certificado();
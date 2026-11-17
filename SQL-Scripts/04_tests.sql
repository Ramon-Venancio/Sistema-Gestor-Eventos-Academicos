SELECT * FROM vw_cronograma_atividades;

SELECT * FROM vw_status_inscricoes;

SELECT 
    e.nome_evento, 
    COUNT(a.codigo_atividade) AS total_atividades
FROM EVENTO e
LEFT JOIN ATIVIDADE a ON e.codigo_evento = a.codigo_evento
GROUP BY e.nome_evento;

SELECT 
    p.nome_palestrante,
    a.titulo AS atividade_ministrada,
    s.nome_sala
FROM MINISTRA m
JOIN PALESTRANTE p ON m.cpf_palestrante = p.cpf_palestrante
JOIN ATIVIDADE a ON m.codigo_atividade = a.codigo_atividade
JOIN SALA s ON m.codigo_sala = s.codigo_sala;


INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao, nota_avaliacao) 
VALUES ('44444444444', 1, CURRENT_DATE, 10.0);

UPDATE INSCRICAO 
SET data_hora_checkin = '2026-11-10 08:00:00' 
WHERE id_inscricao = 1;

INSERT INTO INSCRICAO (cpf_participante, codigo_atividade, data_inscricao) 
VALUES ('55555555555', 2, CURRENT_DATE);

INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada) 
VALUES ('CERT-TESTE-01', 2, CURRENT_DATE, 2);

INSERT INTO CERTIFICADO (codigo_de_validacao, id_inscricao, data_de_emissao, carga_horaria_certificada) 
VALUES ('CERT-TESTE-02', 1, CURRENT_DATE, 10);
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;


CREATE TABLE EVENTO (
    codigo_evento SERIAL,
    nome_evento VARCHAR(255) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    descricao_evento TEXT,
    email_contato VARCHAR(255),

    CONSTRAINT pk_evento PRIMARY KEY (codigo_evento),
    CONSTRAINT chk_evento_datas CHECK (data_fim >= data_inicio),
    CONSTRAINT chk_evento_email CHECK (email_contato LIKE '%@%')
);

CREATE TABLE SALA (
    codigo_sala SERIAL,
    nome_sala VARCHAR(100) NOT NULL,
    capacidade INT NOT NULL,
    bloco VARCHAR(50),
    andar INT,

    CONSTRAINT pk_sala PRIMARY KEY (codigo_sala),
    CONSTRAINT chk_sala_capacidade CHECK (capacidade > 0),
    CONSTRAINT chk_sala_andar CHECK (andar >= 0)
);

CREATE TABLE PALESTRANTE (
    cpf_palestrante VARCHAR(11) NOT NULL,
    nome_palestrante VARCHAR(255) NOT NULL,
    email_palestrante VARCHAR(255) NOT NULL,
    minicurriculo TEXT NOT NULL,
    instituicao VARCHAR(255),
    link_lattes VARCHAR(255),

    CONSTRAINT pk_palestrante PRIMARY KEY (cpf_palestrante),
    CONSTRAINT chk_palestrante_cpf
        CHECK (length(cpf_palestrante) = 11 AND cpf_palestrante ~ '^[0-9]+$'),
    CONSTRAINT chk_palestrante_email CHECK (email_palestrante LIKE '%@%'),
    CONSTRAINT chk_palestrante_lattes CHECK (link_lattes LIKE 'http%')
);

CREATE TABLE PARTICIPANTE (
    cpf_participante VARCHAR(11) NOT NULL,
    nome_participante VARCHAR(255) NOT NULL,
    email_participante VARCHAR(255) NOT NULL,
    telefone_participante VARCHAR(20),
    data_nascimento DATE,

    CONSTRAINT pk_participante PRIMARY KEY (cpf_participante),
    CONSTRAINT chk_participante_cpf
        CHECK (length(cpf_participante) = 11 AND cpf_participante ~ '^[0-9]+$'),
    CONSTRAINT chk_participante_email CHECK (email_participante LIKE '%@%'),
    CONSTRAINT chk_participante_telefone CHECK (telefone_participante ~ '^[0-9]+$'),
    CONSTRAINT chk_participante_nascimento CHECK (data_nascimento < CURRENT_DATE)
);


CREATE TABLE ATIVIDADE (
    codigo_atividade SERIAL,
    codigo_evento INT NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    tipo VARCHAR(100) NOT NULL,
    carga_horaria INT NOT NULL,
    descricao_atividade TEXT,

    CONSTRAINT pk_atividade PRIMARY KEY (codigo_atividade),
    CONSTRAINT fk_atividade_evento
        FOREIGN KEY (codigo_evento) REFERENCES EVENTO(codigo_evento) ON DELETE RESTRICT,
    CONSTRAINT chk_atividade_ch CHECK (carga_horaria > 0)
);

CREATE TABLE ALUNO (
    cpf_participante VARCHAR(11) NOT NULL,
    matricula VARCHAR(50) NOT NULL,
    curso VARCHAR(255) NOT NULL,
    semestre INT,
    campus VARCHAR(255),

    CONSTRAINT pk_aluno PRIMARY KEY (cpf_participante),
    CONSTRAINT uk_aluno_matricula UNIQUE (matricula),
    CONSTRAINT fk_aluno_participante
        FOREIGN KEY (cpf_participante) REFERENCES PARTICIPANTE(cpf_participante) ON DELETE CASCADE,
    CONSTRAINT chk_aluno_semestre CHECK (semestre > 0)
);

CREATE TABLE PROFESSOR (
    cpf_participante VARCHAR(11) NOT NULL,
    titulacao VARCHAR(100) NOT NULL,
    departamento VARCHAR(255) NOT NULL,
    link_lattes VARCHAR(255),

    CONSTRAINT pk_professor PRIMARY KEY (cpf_participante),
    CONSTRAINT fk_professor_participante
        FOREIGN KEY (cpf_participante) REFERENCES PARTICIPANTE(cpf_participante) ON DELETE CASCADE,
    CONSTRAINT chk_professor_lattes CHECK (link_lattes LIKE 'http%')
);

CREATE TABLE EXTERNO (
    cpf_participante VARCHAR(11) NOT NULL,
    instituicao_origem VARCHAR(255) NOT NULL,
    tipo_vinculo VARCHAR(100) NOT NULL,
    cargo VARCHAR(255),
    cidade VARCHAR(255),

    CONSTRAINT pk_externo PRIMARY KEY (cpf_participante),
    CONSTRAINT fk_externo_participante
        FOREIGN KEY (cpf_participante) REFERENCES PARTICIPANTE(cpf_participante) ON DELETE CASCADE
);


CREATE TABLE ATIVIDADE_PRE_REQUISITO (
    codigo_atividade INT NOT NULL,
    pre_requisito VARCHAR(255) NOT NULL,

    CONSTRAINT pk_atividade_pre_requisito PRIMARY KEY (codigo_atividade, pre_requisito),
    CONSTRAINT fk_pre_requisito_atividade
        FOREIGN KEY (codigo_atividade) REFERENCES ATIVIDADE(codigo_atividade) ON DELETE CASCADE
);

CREATE TABLE PROFESSOR_AREA_PESQUISA (
    cpf_participante VARCHAR(11) NOT NULL,
    area_pesquisa VARCHAR(255) NOT NULL,

    CONSTRAINT pk_professor_area_pesquisa PRIMARY KEY (cpf_participante, area_pesquisa),
    CONSTRAINT fk_area_pesquisa_professor
        FOREIGN KEY (cpf_participante) REFERENCES PROFESSOR(cpf_participante) ON DELETE CASCADE
);

CREATE TABLE MINISTRA (
    cpf_palestrante VARCHAR(11) NOT NULL,
    codigo_atividade INT NOT NULL,
    codigo_sala INT NOT NULL,

    CONSTRAINT pk_ministra PRIMARY KEY (cpf_palestrante, codigo_atividade),
    CONSTRAINT fk_ministra_palestrante
        FOREIGN KEY (cpf_palestrante) REFERENCES PALESTRANTE(cpf_palestrante) ON DELETE RESTRICT,
    CONSTRAINT fk_ministra_atividade
        FOREIGN KEY (codigo_atividade) REFERENCES ATIVIDADE(codigo_atividade) ON DELETE CASCADE,
    CONSTRAINT fk_ministra_sala
        FOREIGN KEY (codigo_sala) REFERENCES SALA(codigo_sala) ON DELETE RESTRICT
);

CREATE TABLE INSCRICAO (
    id_inscricao SERIAL,
    cpf_participante VARCHAR(11) NOT NULL,
    codigo_atividade INT NOT NULL,
    data_inscricao DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Pendente' NOT NULL,
    data_hora_checkin TIMESTAMP,
    nota_avaliacao DECIMAL(4,2),
    comentario TEXT,

    CONSTRAINT pk_inscricao PRIMARY KEY (id_inscricao),
    CONSTRAINT uk_inscricao UNIQUE (cpf_participante, codigo_atividade),
    CONSTRAINT fk_inscricao_participante
        FOREIGN KEY (cpf_participante) REFERENCES PARTICIPANTE(cpf_participante) ON DELETE RESTRICT,
    CONSTRAINT fk_inscricao_atividade
        FOREIGN KEY (codigo_atividade) REFERENCES ATIVIDADE(codigo_atividade) ON DELETE RESTRICT,
    CONSTRAINT chk_inscricao_status CHECK (status IN ('Pendente', 'Confirmada', 'Cancelada')),
    CONSTRAINT chk_inscricao_nota CHECK (nota_avaliacao >= 0 AND nota_avaliacao <= 10)
);

CREATE TABLE CERTIFICADO (
    codigo_de_validacao VARCHAR(100) NOT NULL,
    id_inscricao INT NOT NULL,
    data_de_emissao DATE NOT NULL,
    carga_horaria_certificada INT NOT NULL,
    link_pdf VARCHAR(255),
    observacao TEXT,

    CONSTRAINT pk_certificado PRIMARY KEY (codigo_de_validacao),
    CONSTRAINT uk_certificado_inscricao UNIQUE (id_inscricao),
    CONSTRAINT fk_certificado_inscricao
        FOREIGN KEY (id_inscricao) REFERENCES INSCRICAO(id_inscricao) ON DELETE RESTRICT,
    CONSTRAINT chk_certificado_ch CHECK (carga_horaria_certificada > 0),
    CONSTRAINT chk_certificado_pdf CHECK (link_pdf LIKE 'http%')
);
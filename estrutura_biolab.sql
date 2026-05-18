DROP DATABASE IF EXISTS Biolab;
CREATE DATABASE Biolab
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE Biolab;

CREATE TABLE paciente (
    id_paciente INT AUTO_INCREMENT PRIMARY KEY,
    data_nasc DATE NOT NULL,
    genero CHAR(1) CHECK (genero IN ('M','F')),
    nome VARCHAR(100) NOT NULL
) ENGINE=InnoDB;


CREATE TABLE hosp_parceiro (
    id_hospital INT AUTO_INCREMENT PRIMARY KEY,
    razao_social VARCHAR(150) NOT NULL,
    cnpj VARCHAR(14) NOT NULL UNIQUE
) ENGINE=InnoDB;


CREATE TABLE solicitacao (
    id_solicitacao INT AUTO_INCREMENT PRIMARY KEY,
    timestamp_coleta DATETIME,
    timestamp_liberacao DATETIME,
    timestamp_solicitacao DATETIME NOT NULL,
    canal VARCHAR(20),
	CONSTRAINT chk_canal
	CHECK (canal IN ('unidade','domicilio','hospital')),
    timestamp_processamento DATETIME,
    timestamp_validacao DATETIME,

    id_paciente INT NOT NULL,
    id_hospital INT,

    CONSTRAINT fk_solicitacao_paciente
        FOREIGN KEY (id_paciente)
        REFERENCES paciente(id_paciente),

    CONSTRAINT fk_solicitacao_hospital
        FOREIGN KEY (id_hospital)
        REFERENCES hosp_parceiro(id_hospital)
) ENGINE=InnoDB;


CREATE TABLE inconsistencia (
    id_inconsistencia INT AUTO_INCREMENT PRIMARY KEY,
    data_ocorrencia DATETIME NOT NULL,
    custo_interno DECIMAL(10,2),
    descricao_inconsistencia VARCHAR(255),
    tipo_inconsistencia VARCHAR(50),

    id_solicitacao INT NOT NULL,

    CONSTRAINT fk_inconsistencia_solicitacao
        FOREIGN KEY (id_solicitacao)
        REFERENCES solicitacao(id_solicitacao)
) ENGINE=InnoDB;


CREATE TABLE contrato (
    id_contrato INT AUTO_INCREMENT PRIMARY KEY,
    data_inicio_vigencia DATE NOT NULL,
    data_fim_vigencia DATE,
    valor_acordado DECIMAL(10,2) NOT NULL,

    id_hospital INT NOT NULL,

    CONSTRAINT fk_contrato_hospital
        FOREIGN KEY (id_hospital)
        REFERENCES hosp_parceiro(id_hospital)
) ENGINE=InnoDB;

CREATE TABLE exame (
    id_exame INT AUTO_INCREMENT PRIMARY KEY,
    descricao_exame VARCHAR(150) NOT NULL,
    pontos_complexidade INT,
    preparo VARCHAR(255)
) ENGINE=InnoDB;


CREATE TABLE contrato_exame (
    id_contrato INT NOT NULL,
    id_exame INT NOT NULL,
    valor_exame DECIMAL(10,2),

    PRIMARY KEY (id_contrato, id_exame),

    CONSTRAINT fk_contrato_exame_contrato
        FOREIGN KEY (id_contrato)
        REFERENCES contrato(id_contrato),

    CONSTRAINT fk_contrato_exame_exame
        FOREIGN KEY (id_exame)
        REFERENCES exame(id_exame)
) ENGINE=InnoDB;


CREATE TABLE solicitacao_exame (
    id_exame INT NOT NULL,
    id_solicitacao INT NOT NULL,

    PRIMARY KEY (id_exame, id_solicitacao),

    CONSTRAINT fk_solicitacao_exame_exame
        FOREIGN KEY (id_exame)
        REFERENCES exame(id_exame),

    CONSTRAINT fk_solicitacao_exame_solicitacao
        FOREIGN KEY (id_solicitacao)
        REFERENCES solicitacao(id_solicitacao)
) ENGINE=InnoDB;


CREATE TABLE biomedico (
    id_biomedico INT AUTO_INCREMENT PRIMARY KEY,
    registro_profissional VARCHAR(20) NOT NULL,
    assinatura_digital VARCHAR(255),
    nome VARCHAR(100) NOT NULL,

    CONSTRAINT uq_registro_profissional
        UNIQUE (registro_profissional)
) ENGINE=InnoDB;


CREATE TABLE resultado (
    id_resultado INT AUTO_INCREMENT PRIMARY KEY,
    situacao_resultado VARCHAR(20),
    valor_obtido DECIMAL(10,4),
    flag_referencia VARCHAR(10),

    id_exame INT NOT NULL,
    id_biomedico INT,
    id_solicitacao INT NOT NULL,

    CONSTRAINT fk_resultado_exame
        FOREIGN KEY (id_exame)
        REFERENCES exame(id_exame),

    CONSTRAINT fk_resultado_biomedico
        FOREIGN KEY (id_biomedico)
        REFERENCES biomedico(id_biomedico),
        
	CONSTRAINT fk_resultado_solicitacao
		FOREIGN KEY (id_solicitacao)
        REFERENCES solicitacao(id_solicitacao)
) ENGINE=InnoDB;

CREATE TABLE tabela_referencia (
    id_referencia INT AUTO_INCREMENT PRIMARY KEY,
    idade_min INT,
    idade_max INT,
    sexo CHAR(1) CHECK (sexo IN ('M','F')),
    valor_referencia_min DECIMAL(10,4),
    valor_referencia_max DECIMAL(10,4),

    id_exame INT NOT NULL,

    CONSTRAINT fk_tabela_referencia_exame
        FOREIGN KEY (id_exame)
        REFERENCES exame(id_exame)
) ENGINE=InnoDB;

CREATE TABLE painel (
    id_painel INT AUTO_INCREMENT PRIMARY KEY,
    nome_agrupamento VARCHAR(100) NOT NULL
) ENGINE=InnoDB;


CREATE TABLE item_painel (
    id_exame INT NOT NULL,
    id_painel INT NOT NULL,

    PRIMARY KEY (id_exame, id_painel),

    CONSTRAINT fk_item_painel_exame
        FOREIGN KEY (id_exame)
        REFERENCES exame(id_exame),

    CONSTRAINT fk_item_painel_painel
        FOREIGN KEY (id_painel)
        REFERENCES painel(id_painel)
) ENGINE=InnoDB;

CREATE INDEX idx_paciente_nome
ON paciente(nome);

CREATE INDEX idx_solicitacao_data
ON solicitacao(timestamp_solicitacao);

CREATE INDEX idx_inconsistencia_tipo
ON inconsistencia(tipo_inconsistencia);

CREATE INDEX idx_resultado_status
ON resultado(situacao_resultado);
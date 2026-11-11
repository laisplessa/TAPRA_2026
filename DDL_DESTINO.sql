-- =====================================================================
-- DDL do banco de DESTINO (db-tapra-144-6an-lais)
-- Mesmas tabelas da origem (schema itsm), agora com chaves primarias e
-- estrangeiras para garantir a integridade referencial.
--
-- Como rodar no Query editor do portal:
--   1) Rode SOMENTE a linha "CREATE SCHEMA itsm;" (ela precisa ser executada sozinha).
--   2) Depois selecione e rode todo o restante do arquivo.
-- =====================================================================

CREATE SCHEMA itsm;

-- ---------------------------------------------------------------------
-- Tabelas de cadastro (pais)
-- ---------------------------------------------------------------------

CREATE TABLE itsm.categoria (
	id_categoria int IDENTITY(1,1) NOT NULL,
	cd_categoria nvarchar(50) NOT NULL,
	nm_categoria nvarchar(150) NOT NULL,
	ds_descricao nvarchar(300) NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_categoria PRIMARY KEY (id_categoria)
);

CREATE TABLE itsm.cliente_organizacao (
	id_cliente_organizacao int IDENTITY(1,1) NOT NULL,
	cd_cliente_organizacao nvarchar(50) NOT NULL,
	nm_cliente_organizacao nvarchar(200) NOT NULL,
	nr_cnpj nvarchar(20) NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_cliente_organizacao PRIMARY KEY (id_cliente_organizacao)
);

CREATE TABLE itsm.fila (
	id_fila int IDENTITY(1,1) NOT NULL,
	cd_fila nvarchar(50) NOT NULL,
	nm_fila nvarchar(150) NOT NULL,
	ds_descricao nvarchar(300) NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_fila PRIMARY KEY (id_fila)
);

CREATE TABLE itsm.sla (
	id_sla int IDENTITY(1,1) NOT NULL,
	cd_sla nvarchar(50) NOT NULL,
	nm_sla nvarchar(150) NOT NULL,
	qt_meta_minutos int NOT NULL,
	ds_descricao nvarchar(300) NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_sla PRIMARY KEY (id_sla)
);

CREATE TABLE itsm.analista (
	id_analista int IDENTITY(1,1) NOT NULL,
	cd_analista nvarchar(50) NOT NULL,
	nm_analista nvarchar(200) NOT NULL,
	ds_email nvarchar(200) NULL,
	ds_nivel nvarchar(10) NOT NULL,
	id_fila_atual int NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_analista PRIMARY KEY (id_analista),
	CONSTRAINT FK_analista_fila FOREIGN KEY (id_fila_atual)
		REFERENCES itsm.fila (id_fila),
	CONSTRAINT CK_analista_nivel CHECK (ds_nivel IN ('N1', 'N2', 'N3'))
);

CREATE TABLE itsm.solicitante (
	id_solicitante int IDENTITY(1,1) NOT NULL,
	cd_solicitante nvarchar(50) NOT NULL,
	id_cliente_organizacao int NOT NULL,
	nm_solicitante nvarchar(200) NOT NULL,
	ds_email nvarchar(200) NULL,
	ds_telefone nvarchar(50) NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_solicitante PRIMARY KEY (id_solicitante),
	CONSTRAINT FK_solicitante_cliente FOREIGN KEY (id_cliente_organizacao)
		REFERENCES itsm.cliente_organizacao (id_cliente_organizacao)
);

-- ---------------------------------------------------------------------
-- Chamado (depende dos cadastros)
-- ---------------------------------------------------------------------

CREATE TABLE itsm.chamado (
	id_chamado bigint IDENTITY(1,1) NOT NULL,
	nr_chamado nvarchar(50) NOT NULL,
	ds_tipo_chamado nvarchar(50) NOT NULL,
	ds_status_chamado nvarchar(30) NOT NULL,
	ds_prioridade nvarchar(20) NOT NULL,
	dt_criacao datetime2(0) NOT NULL,
	dt_resolucao datetime2(0) NULL,
	dt_ultima_atualizacao datetime2(0) NOT NULL,
	id_analista_atual int NULL,
	id_reporter int NOT NULL,
	id_categoria int NULL,
	id_cliente_organizacao int NOT NULL,
	id_fila_atual int NULL,
	ds_titulo nvarchar(250) NULL,
	ds_descricao nvarchar(MAX) NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_chamado PRIMARY KEY (id_chamado),
	CONSTRAINT FK_chamado_analista FOREIGN KEY (id_analista_atual)
		REFERENCES itsm.analista (id_analista),
	CONSTRAINT FK_chamado_solicitante FOREIGN KEY (id_reporter)
		REFERENCES itsm.solicitante (id_solicitante),
	CONSTRAINT FK_chamado_categoria FOREIGN KEY (id_categoria)
		REFERENCES itsm.categoria (id_categoria),
	CONSTRAINT FK_chamado_cliente FOREIGN KEY (id_cliente_organizacao)
		REFERENCES itsm.cliente_organizacao (id_cliente_organizacao),
	CONSTRAINT FK_chamado_fila FOREIGN KEY (id_fila_atual)
		REFERENCES itsm.fila (id_fila),
	CONSTRAINT CK_chamado_tipo CHECK (ds_tipo_chamado IN
		('INCIDENT', 'REQUEST', 'PROBLEM', 'CHANGE', 'TASK')),
	CONSTRAINT CK_chamado_status CHECK (ds_status_chamado IN
		('OPEN', 'IN_PROGRESS', 'PENDING', 'RESOLVED', 'CLOSED', 'CANCELLED')),
	CONSTRAINT CK_chamado_prioridade CHECK (ds_prioridade IN
		('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- ---------------------------------------------------------------------
-- Tabelas que dependem do chamado (filhas)
-- ---------------------------------------------------------------------

CREATE TABLE itsm.chamado_sla (
	id_chamado_sla bigint IDENTITY(1,1) NOT NULL,
	id_chamado bigint NOT NULL,
	id_sla int NOT NULL,
	fl_breach bit NOT NULL,
	qt_tempo_restante_minutos int NULL,
	qt_tempo_decorrido_minutos int NULL,
	qt_meta_minutos int NOT NULL,
	dt_referencia datetime2(0) NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_chamado_sla PRIMARY KEY (id_chamado_sla),
	CONSTRAINT FK_chamado_sla_chamado FOREIGN KEY (id_chamado)
		REFERENCES itsm.chamado (id_chamado),
	CONSTRAINT FK_chamado_sla_sla FOREIGN KEY (id_sla)
		REFERENCES itsm.sla (id_sla)
);

CREATE TABLE itsm.chamado_status_historico (
	id_chamado_status_historico bigint IDENTITY(1,1) NOT NULL,
	id_chamado bigint NOT NULL,
	ds_status_chamado nvarchar(30) NOT NULL,
	dt_inicio_status datetime2(0) NOT NULL,
	dt_fim_status datetime2(0) NULL,
	qt_tempo_status_minutos int NULL,
	id_analista_responsavel int NULL,
	id_fila int NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_chamado_status_historico PRIMARY KEY (id_chamado_status_historico),
	CONSTRAINT FK_historico_chamado FOREIGN KEY (id_chamado)
		REFERENCES itsm.chamado (id_chamado),
	CONSTRAINT FK_historico_analista FOREIGN KEY (id_analista_responsavel)
		REFERENCES itsm.analista (id_analista),
	CONSTRAINT FK_historico_fila FOREIGN KEY (id_fila)
		REFERENCES itsm.fila (id_fila),
	CONSTRAINT CK_historico_status CHECK (ds_status_chamado IN
		('OPEN', 'IN_PROGRESS', 'PENDING', 'RESOLVED', 'CLOSED', 'CANCELLED'))
);

CREATE TABLE itsm.csat_avaliacao (
	id_csat_avaliacao bigint IDENTITY(1,1) NOT NULL,
	id_chamado bigint NOT NULL,
	id_analista int NULL,
	nr_score int NOT NULL,
	ds_comentario nvarchar(1000) NULL,
	dt_avaliacao datetime2(0) NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) NULL,
	cd_registro_origem nvarchar(100) NULL,
	CONSTRAINT PK_csat_avaliacao PRIMARY KEY (id_csat_avaliacao),
	CONSTRAINT FK_csat_chamado FOREIGN KEY (id_chamado)
		REFERENCES itsm.chamado (id_chamado),
	CONSTRAINT FK_csat_analista FOREIGN KEY (id_analista)
		REFERENCES itsm.analista (id_analista)
);

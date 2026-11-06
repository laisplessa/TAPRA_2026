-- DROP SCHEMA itsm;

CREATE SCHEMA itsm;

CREATE TABLE itsm.categoria (
	id_categoria int IDENTITY(1,1) NOT NULL,
	cd_categoria nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nm_categoria nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
);


CREATE TABLE itsm.cliente_organizacao (
	id_cliente_organizacao int IDENTITY(1,1) NOT NULL,
	cd_cliente_organizacao nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nm_cliente_organizacao nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nr_cnpj nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);



CREATE TABLE itsm.csat (
	Id int NOT NULL,
	Column1 nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Column2 int NULL,
	
);



CREATE TABLE itsm.fila (
	id_fila int IDENTITY(1,1) NOT NULL,
	cd_fila nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nm_fila nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);


CREATE TABLE itsm.sla (
	id_sla int IDENTITY(1,1) NOT NULL,
	cd_sla nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nm_sla nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	qt_meta_minutos int NOT NULL,
	ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	
);



CREATE TABLE itsm.analista (
	id_analista int IDENTITY(1,1) NOT NULL,
	cd_analista nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	nm_analista nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_email nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ds_nivel nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	id_fila_atual int NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);
 
ALTER TABLE itsm.analista WITH NOCHECK ADD CONSTRAINT CK_itsm_analista_nivel CHECK (([ds_nivel]='N3' OR [ds_nivel]='N2' OR [ds_nivel]='N1'));


CREATE TABLE itsm.solicitante (
	id_solicitante int IDENTITY(1,1) NOT NULL,
	cd_solicitante nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	id_cliente_organizacao int NOT NULL,
	nm_solicitante nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_email nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ds_telefone nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	fl_ativo bit DEFAULT 1 NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	
);
 



CREATE TABLE itsm.chamado (
	id_chamado bigint IDENTITY(1,1) NOT NULL,
	nr_chamado nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_tipo_chamado nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_status_chamado nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ds_prioridade nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	dt_criacao datetime2(0) NOT NULL,
	dt_resolucao datetime2(0) NULL,
	dt_ultima_atualizacao datetime2(0) NOT NULL,
	id_analista_atual int NULL,
	id_reporter int NOT NULL,
	id_categoria int NULL,
	id_cliente_organizacao int NOT NULL,
	id_fila_atual int NULL,
	ds_titulo nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ds_descricao nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	
);
  
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_tipo CHECK (([ds_tipo_chamado]='TASK' OR [ds_tipo_chamado]='CHANGE' OR [ds_tipo_chamado]='PROBLEM' OR [ds_tipo_chamado]='REQUEST' OR [ds_tipo_chamado]='INCIDENT'));
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_status CHECK (([ds_status_chamado]='CANCELLED' OR [ds_status_chamado]='CLOSED' OR [ds_status_chamado]='RESOLVED' OR [ds_status_chamado]='PENDING' OR [ds_status_chamado]='IN_PROGRESS' OR [ds_status_chamado]='OPEN'));
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_prioridade CHECK (([ds_prioridade]='CRITICAL' OR [ds_prioridade]='HIGH' OR [ds_prioridade]='MEDIUM' OR [ds_prioridade]='LOW'));



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
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);
 



CREATE TABLE itsm.chamado_status_historico (
	id_chamado_status_historico bigint IDENTITY(1,1) NOT NULL,
	id_chamado bigint NOT NULL,
	ds_status_chamado nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	dt_inicio_status datetime2(0) NOT NULL,
	dt_fim_status datetime2(0) NULL,
	qt_tempo_status_minutos int NULL,
	id_analista_responsavel int NULL,
	id_fila int NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);
  
ALTER TABLE itsm.chamado_status_historico WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_status_hist_status CHECK (([ds_status_chamado]='CANCELLED' OR [ds_status_chamado]='CLOSED' OR [ds_status_chamado]='RESOLVED' OR [ds_status_chamado]='PENDING' OR [ds_status_chamado]='IN_PROGRESS' OR [ds_status_chamado]='OPEN'));



CREATE TABLE itsm.csat_avaliacao (
	id_csat_avaliacao bigint IDENTITY(1,1) NOT NULL,
	id_chamado bigint NOT NULL,
	id_analista int NULL,
	nr_score int NOT NULL,
	ds_comentario nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	dt_avaliacao datetime2(0) NOT NULL,
	dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
	dt_atualizacao datetime2(0) NULL,
	nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,

);
 
ALTER TABLE itsm.csat_avaliacao WITH NOCHECK ADD CONSTRAINT CK_itsm_csat_score CHECK (([nr_score]>=(1) AND [nr_score]<=(5)));
-- ============================================================================
-- 03_modelo_estrela.sql
-- Passo 3: Criação das Tabelas do Modelo Estrela (DDL)
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/03_modelo_estrela.sql

-- ══════════════════════════════════════════════════════════════════════════════
-- 7.1 — DIM_TEMPO (role-playing dimension)
-- Dimensão conformada referenciada 6 vezes na fato.
-- SK no formato YYYYMMDD (smart key - Kimball).
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_tempo CASCADE;
CREATE TABLE dw.dim_tempo (
    sk_tempo                INT         PRIMARY KEY,
    data                    DATE,
    dia                     SMALLINT,
    mes                     SMALLINT,
    ano                     SMALLINT,
    trimestre               SMALLINT,
    nome_mes                VARCHAR(15),
    dia_semana              VARCHAR(15),
    ano_mes                 CHAR(7),        -- '2026-03'
    eh_fim_de_semana        BOOLEAN,
    semana_epidemiologica   SMALLINT
);

-- Membro "Desconhecido" para datas ausentes (SK = -1)
INSERT INTO dw.dim_tempo VALUES
    (-1, NULL, NULL, NULL, NULL, NULL, 'Desconhecido', 'Desconhecido', 'N/D', FALSE, NULL);


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.2 — DIM_LOCALIDADE
-- Hierarquia drill-down: UF → Região → Município → Bairro
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_localidade CASCADE;
CREATE TABLE dw.dim_localidade (
    sk_local        SERIAL      PRIMARY KEY,
    municipio       VARCHAR(100),
    bairro          VARCHAR(150),
    uf              CHAR(2)     DEFAULT 'ES',
    regiao_es       VARCHAR(30),
    macrorregiao    VARCHAR(30),
    UNIQUE (municipio, bairro)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_localidade (sk_local, municipio, bairro, uf, regiao_es, macrorregiao)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', 'Desconhecido', 'ES', 'Desconhecida', 'Desconhecida');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.3 — DIM_PERFIL_PACIENTE
-- Combinações únicas de perfil demográfico.
-- Não há ID de paciente — guarda perfis, não indivíduos.
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_perfil_paciente CASCADE;
CREATE TABLE dw.dim_perfil_paciente (
    sk_perfil           SERIAL      PRIMARY KEY,
    sexo                VARCHAR(20),
    faixa_etaria        VARCHAR(30),
    raca_cor            VARCHAR(30),
    escolaridade        VARCHAR(100),
    gestante            VARCHAR(40),
    profissional_saude  VARCHAR(20),
    morador_rua         VARCHAR(20),
    possui_deficiencia  VARCHAR(20),
    UNIQUE (sexo, faixa_etaria, raca_cor, escolaridade,
            gestante, profissional_saude, morador_rua, possui_deficiencia)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_perfil_paciente (sk_perfil, sexo, faixa_etaria, raca_cor, escolaridade,
    gestante, profissional_saude, morador_rua, possui_deficiencia)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido', 'Desconhecida', 'Desconhecida', 'Desconhecida',
        'Desconhecido', 'Desconhecido', 'Desconhecido', 'Desconhecido');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.4 — DIM_CLASSIFICACAO
-- Status do caso: ~160 combinações possíveis.
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_classificacao CASCADE;
CREATE TABLE dw.dim_classificacao (
    sk_class                SERIAL      PRIMARY KEY,
    classificacao           VARCHAR(50),
    evolucao                VARCHAR(50),
    criterio_confirmacao    VARCHAR(50),
    status_notificacao      VARCHAR(30),
    UNIQUE (classificacao, evolucao, criterio_confirmacao, status_notificacao)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_classificacao (sk_class, classificacao, evolucao,
    criterio_confirmacao, status_notificacao)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecida', 'Desconhecida', 'Desconhecido', 'Desconhecido');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.5 — DIM_SINTOMAS (junk dimension)
-- Consolida 7 flags de sintomas.
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_sintomas CASCADE;
CREATE TABLE dw.dim_sintomas (
    sk_sint             SERIAL      PRIMARY KEY,
    febre               VARCHAR(20),
    dif_respiratoria    VARCHAR(20),
    tosse               VARCHAR(20),
    coriza              VARCHAR(20),
    dor_garganta        VARCHAR(20),
    diarreia            VARCHAR(20),
    cefaleia            VARCHAR(20),
    UNIQUE (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_sintomas (sk_sint, febre, dif_respiratoria, tosse, coriza,
    dor_garganta, diarreia, cefaleia)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido','Desconhecido');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.5 — DIM_COMORBIDADE (junk dimension)
-- Consolida 6 flags de comorbidades. Separada de sintomas por domínio semântico.
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_comorbidade CASCADE;
CREATE TABLE dw.dim_comorbidade (
    sk_como         SERIAL      PRIMARY KEY,
    com_pulmao      VARCHAR(20),
    com_cardio      VARCHAR(20),
    com_renal       VARCHAR(20),
    com_diabetes    VARCHAR(20),
    com_tabagismo   VARCHAR(20),
    com_obesidade   VARCHAR(20),
    UNIQUE (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_comorbidade (sk_como, com_pulmao, com_cardio, com_renal,
    com_diabetes, com_tabagismo, com_obesidade)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido','Desconhecido');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.6 — DIM_TESTE
-- Descreve "como foi testado" — todas as variações de exame em uma só dimensão.
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.dim_teste CASCADE;
CREATE TABLE dw.dim_teste (
    sk_teste            SERIAL      PRIMARY KEY,
    tipo_teste_rapido   VARCHAR(60),
    resultado_rt_pcr    VARCHAR(30),
    resultado_teste_rap VARCHAR(30),
    resultado_sorologia VARCHAR(30),
    resultado_sorol_igg VARCHAR(30),
    UNIQUE (tipo_teste_rapido, resultado_rt_pcr,
            resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
);

-- Membro "Desconhecido"
INSERT INTO dw.dim_teste (sk_teste, tipo_teste_rapido, resultado_rt_pcr,
    resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
OVERRIDING SYSTEM VALUE
VALUES (-1, 'Desconhecido','Desconhecido','Desconhecido',
        'Desconhecido','Desconhecido');


-- ══════════════════════════════════════════════════════════════════════════════
-- 7.7 — FATO_NOTIFICACAO_COVID
-- Grão: uma notificação de COVID-19 (1 linha do CSV = 1 linha da fato).
-- ══════════════════════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dw.fato_notificacao_covid CASCADE;
CREATE TABLE dw.fato_notificacao_covid (
    sk_fato                 BIGSERIAL   PRIMARY KEY,

    -- Dimensões de tempo (role-playing: 6 papéis)
    sk_data_notificacao     INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_cadastro        INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_diagnostico     INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_coleta          INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_encerramento    INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),
    sk_data_obito           INT NOT NULL REFERENCES dw.dim_tempo(sk_tempo),

    -- Dimensões descritivas
    sk_local                INT NOT NULL REFERENCES dw.dim_localidade(sk_local),
    sk_perfil               INT NOT NULL REFERENCES dw.dim_perfil_paciente(sk_perfil),
    sk_class                INT NOT NULL REFERENCES dw.dim_classificacao(sk_class),
    sk_sint                 INT NOT NULL REFERENCES dw.dim_sintomas(sk_sint),
    sk_como                 INT NOT NULL REFERENCES dw.dim_comorbidade(sk_como),
    sk_teste                INT NOT NULL REFERENCES dw.dim_teste(sk_teste),

    -- Medidas
    qtd_notificacao         SMALLINT    NOT NULL DEFAULT 1,
    flag_confirmado         SMALLINT    NOT NULL DEFAULT 0,
    flag_obito_covid        SMALLINT    NOT NULL DEFAULT 0,
    flag_internado          SMALLINT    NOT NULL DEFAULT 0,
    flag_cura               SMALLINT    NOT NULL DEFAULT 0,
    idade_anos              SMALLINT,
    dias_notif_encerramento INT,
    dias_notif_obito        INT
);

-- Índices recomendados para consultas OLAP
CREATE INDEX idx_fato_data_notif ON dw.fato_notificacao_covid(sk_data_notificacao);
CREATE INDEX idx_fato_local      ON dw.fato_notificacao_covid(sk_local);
CREATE INDEX idx_fato_class      ON dw.fato_notificacao_covid(sk_class);
CREATE INDEX idx_fato_perfil     ON dw.fato_notificacao_covid(sk_perfil);

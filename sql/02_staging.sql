-- ============================================================================
-- 02_staging.sql
-- Passo 2: Staging (Extract) — DDL da tabela raw + carga com COPY
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/02_staging.sql

-- ──────────────────────────────────────────────────────────────────────────────
-- DDL da tabela de staging
-- Todas as colunas como TEXT porque a staging NÃO valida nem converte.
-- Preserva o dado bruto (1:1 com o CSV) para rastreabilidade e reprocessamento.
-- ──────────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS stg.notificacao_raw;
CREATE TABLE stg.notificacao_raw (
    data_notificacao        TEXT,
    data_cadastro           TEXT,
    data_diagnostico        TEXT,
    data_coleta_rt_pcr      TEXT,
    data_coleta_teste_rap   TEXT,
    data_coleta_sorologia   TEXT,
    data_coleta_sorolog_igg TEXT,
    data_encerramento       TEXT,
    data_obito              TEXT,
    classificacao           TEXT,
    evolucao                TEXT,
    criterio_confirmacao    TEXT,
    status_notificacao      TEXT,
    municipio               TEXT,
    bairro                  TEXT,
    faixa_etaria            TEXT,
    idade_na_notificacao    TEXT,
    sexo                    TEXT,
    raca_cor                TEXT,
    escolaridade            TEXT,
    gestante                TEXT,
    febre                   TEXT,
    dif_respiratoria        TEXT,
    tosse                   TEXT,
    coriza                  TEXT,
    dor_garganta            TEXT,
    diarreia                TEXT,
    cefaleia                TEXT,
    com_pulmao              TEXT,
    com_cardio              TEXT,
    com_renal               TEXT,
    com_diabetes            TEXT,
    com_tabagismo           TEXT,
    com_obesidade           TEXT,
    ficou_internado         TEXT,
    viagem_brasil           TEXT,
    viagem_internacional    TEXT,
    profissional_saude      TEXT,
    possui_deficiencia      TEXT,
    morador_rua             TEXT,
    resultado_rt_pcr        TEXT,
    resultado_teste_rap     TEXT,
    resultado_sorologia     TEXT,
    resultado_sorol_igg     TEXT,
    tipo_teste_rapido       TEXT
);

-- ──────────────────────────────────────────────────────────────────────────────
-- Carga com COPY (alta performance)
-- COPY carrega 5M linhas em poucos minutos; INSERT linha a linha levaria horas.
-- ──────────────────────────────────────────────────────────────────────────────

-- IMPORTANTE: Ajuste o caminho absoluto abaixo para o local do seu CSV
\encoding LATIN1

COPY stg.notificacao_raw
FROM '/caminho/absoluto/MICRODADOS.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    ENCODING 'LATIN1',
    NULL ''
);

-- Verificação rápida
SELECT COUNT(*) AS total_linhas FROM stg.notificacao_raw;

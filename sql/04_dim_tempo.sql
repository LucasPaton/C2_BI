-- ============================================================================
-- 04_dim_tempo.sql
-- Passo 4: Povoamento da DIM_TEMPO
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/04_dim_tempo.sql

-- A dimensão tempo é populada ANTES da fato, cobrindo todo o intervalo do dataset.
-- Usamos SQL puro (sem ETL Python) porque é determinístico.
--
-- Didática: a sk_tempo é um inteiro no formato YYYYMMDD (ex.: 20260315).
-- Esse padrão, chamado "smart key", é defendido por Kimball:
--   - Permite ordenar datas apenas pela SK, sem join
--   - É humanamente legível

INSERT INTO dw.dim_tempo (
    sk_tempo, data, dia, mes, ano, trimestre,
    nome_mes, dia_semana, ano_mes, eh_fim_de_semana, semana_epidemiologica
)
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INT)     AS sk_tempo,
    d,
    EXTRACT(DAY     FROM d)::SMALLINT,
    EXTRACT(MONTH   FROM d)::SMALLINT,
    EXTRACT(YEAR    FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    TO_CHAR(d, 'TMDay'),
    TO_CHAR(d, 'YYYY-MM'),
    EXTRACT(ISODOW FROM d) >= 6,
    EXTRACT(WEEK FROM d)::SMALLINT
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) d;

-- Verificação
SELECT
    COUNT(*)        AS total_dias,
    MIN(data)       AS data_inicio,
    MAX(data)       AS data_fim
FROM dw.dim_tempo
WHERE sk_tempo > 0;

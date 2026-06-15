-- ============================================================================
-- 07_validacao.sql
-- Passo 7: Validação do DW + Consultas Analíticas OLAP
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/07_validacao.sql


-- ══════════════════════════════════════════════════════════════════════════════
-- 11.1 — TESTES DE INTEGRIDADE
-- ══════════════════════════════════════════════════════════════════════════════

-- 1) Nenhuma FK deve estar nula (as constraints NOT NULL já garantem isso)
SELECT 'fato_sem_tempo_notif' AS teste, COUNT(*)
FROM dw.fato_notificacao_covid
WHERE sk_data_notificacao IS NULL
UNION ALL
SELECT 'fato_sem_local', COUNT(*)
FROM dw.fato_notificacao_covid
WHERE sk_local IS NULL;

-- 2) Contagem da fato = contagem da staging
SELECT
    (SELECT COUNT(*) FROM stg.notificacao_raw)       AS origem,
    (SELECT COUNT(*) FROM dw.fato_notificacao_covid)  AS carregado;

-- 3) Cardinalidades das dimensões
SELECT 'dim_tempo'          AS dim, COUNT(*) FROM dw.dim_tempo
UNION ALL SELECT 'dim_localidade',    COUNT(*) FROM dw.dim_localidade
UNION ALL SELECT 'dim_perfil',        COUNT(*) FROM dw.dim_perfil_paciente
UNION ALL SELECT 'dim_classificacao', COUNT(*) FROM dw.dim_classificacao
UNION ALL SELECT 'dim_sintomas',      COUNT(*) FROM dw.dim_sintomas
UNION ALL SELECT 'dim_comorbidade',   COUNT(*) FROM dw.dim_comorbidade
UNION ALL SELECT 'dim_teste',         COUNT(*) FROM dw.dim_teste;


-- ══════════════════════════════════════════════════════════════════════════════
-- 11.2 — CONSULTAS ANALÍTICAS DE EXEMPLO
-- ══════════════════════════════════════════════════════════════════════════════

-- ──────────────────────────────────────────────────────────────────────────────
-- Q1 — Casos confirmados por município e mês
-- ──────────────────────────────────────────────────────────────────────────────
SELECT
    l.municipio,
    t.ano_mes,
    SUM(f.flag_confirmado)  AS confirmados,
    SUM(f.qtd_notificacao)  AS notificacoes_total
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON l.sk_local = f.sk_local
JOIN dw.dim_tempo      t ON t.sk_tempo = f.sk_data_notificacao
WHERE t.ano IN (2021, 2022)
GROUP BY l.municipio, t.ano_mes
ORDER BY confirmados DESC
LIMIT 20;


-- ──────────────────────────────────────────────────────────────────────────────
-- Q2 — Letalidade por faixa etária
-- ──────────────────────────────────────────────────────────────────────────────
SELECT
    p.faixa_etaria,
    SUM(f.flag_confirmado)    AS confirmados,
    SUM(f.flag_obito_covid)   AS obitos,
    ROUND(100.0 * SUM(f.flag_obito_covid)
        / NULLIF(SUM(f.flag_confirmado), 0), 2) AS letalidade_pct
FROM dw.fato_notificacao_covid f
JOIN dw.dim_perfil_paciente p ON p.sk_perfil = f.sk_perfil
GROUP BY p.faixa_etaria
ORDER BY letalidade_pct DESC;


-- ──────────────────────────────────────────────────────────────────────────────
-- Q3 — Sintomas mais associados à internação
-- ──────────────────────────────────────────────────────────────────────────────
SELECT
    s.febre, s.tosse, s.dif_respiratoria,
    SUM(f.flag_internado)   AS internacoes,
    SUM(f.qtd_notificacao)  AS casos
FROM dw.fato_notificacao_covid f
JOIN dw.dim_sintomas s ON s.sk_sint = f.sk_sint
GROUP BY s.febre, s.tosse, s.dif_respiratoria
HAVING SUM(f.qtd_notificacao) > 1000
ORDER BY internacoes DESC
LIMIT 10;


-- ──────────────────────────────────────────────────────────────────────────────
-- Q4 — Tempo médio entre notificação e encerramento por município
-- ──────────────────────────────────────────────────────────────────────────────
SELECT
    l.municipio,
    ROUND(AVG(f.dias_notif_encerramento)::numeric, 1) AS dias_medio,
    COUNT(*) AS casos
FROM dw.fato_notificacao_covid f
JOIN dw.dim_localidade l ON l.sk_local = f.sk_local
WHERE f.dias_notif_encerramento IS NOT NULL
    AND f.dias_notif_encerramento BETWEEN 0 AND 180
GROUP BY l.municipio
HAVING COUNT(*) > 500
ORDER BY dias_medio DESC;


-- ──────────────────────────────────────────────────────────────────────────────
-- Q5 — Impacto de comorbidades na letalidade
-- ──────────────────────────────────────────────────────────────────────────────
SELECT
    c.com_cardio, c.com_diabetes, c.com_obesidade,
    SUM(f.flag_confirmado)    AS confirmados,
    SUM(f.flag_obito_covid)   AS obitos,
    ROUND(100.0 * SUM(f.flag_obito_covid)
        / NULLIF(SUM(f.flag_confirmado), 0), 2) AS letalidade_pct
FROM dw.fato_notificacao_covid f
JOIN dw.dim_comorbidade c ON c.sk_como = f.sk_como
GROUP BY c.com_cardio, c.com_diabetes, c.com_obesidade
ORDER BY letalidade_pct DESC
LIMIT 15;

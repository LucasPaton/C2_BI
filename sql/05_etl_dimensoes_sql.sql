-- ============================================================================
-- 05_etl_dimensoes_sql.sql
-- Passo 5: ETL das Dimensões — Alternativa em SQL puro
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/05_etl_dimensoes_sql.sql

-- Didática: o padrão COALESCE(NULLIF(TRIM(·),''), 'Desconhecido') padroniza
-- valores vazios e nulos em um único rótulo consistente — pré-requisito para
-- que "Não Informado" vire um membro real da dimensão e as FKs da fato nunca
-- fiquem nulas.

-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_LOCALIDADE
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_localidade (municipio, bairro)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(municipio),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(bairro),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (municipio, bairro) DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_CLASSIFICACAO
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_classificacao
    (classificacao, evolucao, criterio_confirmacao, status_notificacao)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(classificacao),''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(evolucao),''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(criterio_confirmacao),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(status_notificacao),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (classificacao, evolucao, criterio_confirmacao, status_notificacao)
DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_PERFIL_PACIENTE
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_perfil_paciente
    (sexo, faixa_etaria, raca_cor, escolaridade,
     gestante, profissional_saude, morador_rua, possui_deficiencia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(sexo),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(faixa_etaria),''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(raca_cor),''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(escolaridade),''), 'Desconhecida'),
    COALESCE(NULLIF(TRIM(gestante),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(profissional_saude),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(morador_rua),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(possui_deficiencia),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (sexo, faixa_etaria, raca_cor, escolaridade,
             gestante, profissional_saude, morador_rua, possui_deficiencia)
DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_SINTOMAS (junk dimension)
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_sintomas
    (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(febre),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(dif_respiratoria),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(tosse),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(coriza),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(dor_garganta),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(diarreia),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(cefaleia),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (febre, dif_respiratoria, tosse, coriza, dor_garganta, diarreia, cefaleia)
DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_COMORBIDADE (junk dimension)
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_comorbidade
    (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(com_pulmao),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_cardio),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_renal),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_diabetes),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_tabagismo),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(com_obesidade),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (com_pulmao, com_cardio, com_renal, com_diabetes, com_tabagismo, com_obesidade)
DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- DIM_TESTE
-- ══════════════════════════════════════════════════════════════════════════════
INSERT INTO dw.dim_teste
    (tipo_teste_rapido, resultado_rt_pcr, resultado_teste_rap,
     resultado_sorologia, resultado_sorol_igg)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(tipo_teste_rapido),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_rt_pcr),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_teste_rap),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_sorologia),''), 'Desconhecido'),
    COALESCE(NULLIF(TRIM(resultado_sorol_igg),''), 'Desconhecido')
FROM stg.notificacao_raw
ON CONFLICT (tipo_teste_rapido, resultado_rt_pcr,
             resultado_teste_rap, resultado_sorologia, resultado_sorol_igg)
DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════════════
-- Verificação de cardinalidades
-- ══════════════════════════════════════════════════════════════════════════════
SELECT 'dim_localidade'      AS dimensao, COUNT(*) AS registros FROM dw.dim_localidade
UNION ALL SELECT 'dim_classificacao',  COUNT(*) FROM dw.dim_classificacao
UNION ALL SELECT 'dim_perfil',         COUNT(*) FROM dw.dim_perfil_paciente
UNION ALL SELECT 'dim_sintomas',       COUNT(*) FROM dw.dim_sintomas
UNION ALL SELECT 'dim_comorbidade',    COUNT(*) FROM dw.dim_comorbidade
UNION ALL SELECT 'dim_teste',          COUNT(*) FROM dw.dim_teste
ORDER BY dimensao;

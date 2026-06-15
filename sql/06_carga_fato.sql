-- ============================================================================
-- 06_carga_fato.sql
-- Passo 6: Carga da Tabela Fato
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao dw_covid:
--   psql -U postgres -d dw_covid -f sql/06_carga_fato.sql

-- A carga da fato é um INSERT ... SELECT com LEFT JOINs nas dimensões
-- para substituir os valores de texto pelas surrogate keys.

-- Pontos didáticos:
--   • LEFT JOIN + COALESCE(-1): garante que toda linha da staging vira uma
--     linha da fato, mesmo que alguma dimensão não tenha a combinação exata.
--     Evita perda silenciosa de dados.
--   • Flags 0/1 em vez de texto: permitem somar diretamente
--     (ex.: SUM(flag_confirmado) = total de casos confirmados).
--   • Smart key de tempo: YYYYMMDD facilita filtros de período.
--   • Data de coleta consolidada: preferimos a primeira não-nula entre as
--     4 datas de coleta para simplificar o grão.

INSERT INTO dw.fato_notificacao_covid (
    sk_data_notificacao, sk_data_cadastro, sk_data_diagnostico,
    sk_data_coleta, sk_data_encerramento, sk_data_obito,
    sk_local, sk_perfil, sk_class, sk_sint, sk_como, sk_teste,
    qtd_notificacao, flag_confirmado, flag_obito_covid,
    flag_internado, flag_cura, idade_anos,
    dias_notif_encerramento, dias_notif_obito
)
SELECT
    -- ── TEMPO: transforma texto em SK no formato YYYYMMDD; -1 quando ausente ──
    COALESCE(CAST(TO_CHAR(s.data_notificacao::DATE, 'YYYYMMDD') AS INT), -1),
    COALESCE(CAST(TO_CHAR(s.data_cadastro::DATE, 'YYYYMMDD') AS INT), -1),
    COALESCE(CAST(TO_CHAR(
        NULLIF(TRIM(s.data_diagnostico),'')::DATE, 'YYYYMMDD') AS INT), -1),
    COALESCE(CAST(TO_CHAR(
        COALESCE(
            NULLIF(TRIM(s.data_coleta_rt_pcr),'')::DATE,
            NULLIF(TRIM(s.data_coleta_teste_rap),'')::DATE,
            NULLIF(TRIM(s.data_coleta_sorologia),'')::DATE,
            NULLIF(TRIM(s.data_coleta_sorolog_igg),'')::DATE
        ), 'YYYYMMDD') AS INT), -1),
    COALESCE(CAST(TO_CHAR(
        NULLIF(TRIM(s.data_encerramento),'')::DATE, 'YYYYMMDD') AS INT), -1),
    COALESCE(CAST(TO_CHAR(
        NULLIF(TRIM(s.data_obito),'')::DATE, 'YYYYMMDD') AS INT), -1),

    -- ── DIMENSÕES DESCRITIVAS ──
    COALESCE(dl.sk_local,   -1),
    COALESCE(dp.sk_perfil,  -1),
    COALESCE(dc.sk_class,   -1),
    COALESCE(ds.sk_sint,    -1),
    COALESCE(dm.sk_como,    -1),
    COALESCE(dt.sk_teste,   -1),

    -- ── MEDIDAS ──
    1                                               AS qtd_notificacao,
    (s.classificacao = 'Confirmados')::INT          AS flag_confirmado,
    (s.evolucao = 'Óbito pelo COVID-19')::INT       AS flag_obito_covid,
    (s.ficou_internado = 'Sim')::INT                AS flag_internado,
    (s.evolucao = 'Cura')::INT                      AS flag_cura,
    NULLIF(SPLIT_PART(s.idade_na_notificacao, ' anos', 1),'')::INT
                                                    AS idade_anos,
    NULLIF(TRIM(s.data_encerramento),'')::DATE
        - NULLIF(TRIM(s.data_notificacao),'')::DATE AS dias_notif_encerramento,
    NULLIF(TRIM(s.data_obito),'')::DATE
        - NULLIF(TRIM(s.data_notificacao),'')::DATE AS dias_notif_obito

FROM stg.notificacao_raw s

LEFT JOIN dw.dim_localidade dl
    ON  dl.municipio = s.municipio
    AND dl.bairro    = COALESCE(NULLIF(TRIM(s.bairro),''), 'Desconhecido')

LEFT JOIN dw.dim_perfil_paciente dp
    ON  dp.sexo                = s.sexo
    AND dp.faixa_etaria        = s.faixa_etaria
    AND dp.raca_cor            = s.raca_cor
    AND dp.escolaridade        = s.escolaridade
    AND dp.gestante            = s.gestante
    AND dp.profissional_saude  = s.profissional_saude
    AND dp.morador_rua         = s.morador_rua
    AND dp.possui_deficiencia  = s.possui_deficiencia

LEFT JOIN dw.dim_classificacao dc
    ON  dc.classificacao         = s.classificacao
    AND dc.evolucao              = s.evolucao
    AND dc.criterio_confirmacao  = s.criterio_confirmacao
    AND dc.status_notificacao    = s.status_notificacao

LEFT JOIN dw.dim_sintomas ds
    ON  ds.febre            = s.febre
    AND ds.dif_respiratoria = s.dif_respiratoria
    AND ds.tosse            = s.tosse
    AND ds.coriza           = s.coriza
    AND ds.dor_garganta     = s.dor_garganta
    AND ds.diarreia         = s.diarreia
    AND ds.cefaleia         = s.cefaleia

LEFT JOIN dw.dim_comorbidade dm
    ON  dm.com_pulmao     = s.com_pulmao
    AND dm.com_cardio     = s.com_cardio
    AND dm.com_renal      = s.com_renal
    AND dm.com_diabetes   = s.com_diabetes
    AND dm.com_tabagismo  = s.com_tabagismo
    AND dm.com_obesidade  = s.com_obesidade

LEFT JOIN dw.dim_teste dt
    ON  dt.tipo_teste_rapido   = s.tipo_teste_rapido
    AND dt.resultado_rt_pcr    = s.resultado_rt_pcr
    AND dt.resultado_teste_rap = s.resultado_teste_rap
    AND dt.resultado_sorologia = s.resultado_sorologia
    AND dt.resultado_sorol_igg = s.resultado_sorol_igg;

-- ── Verificação rápida ──
SELECT COUNT(*) AS linhas_fato FROM dw.fato_notificacao_covid;

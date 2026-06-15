"""
ETL: Popula as dimensões a partir de stg.notificacao_raw.

Passo 5 do tutorial — opção Python com SQLAlchemy.
Extrai combinações DISTINCT da staging e insere nas dimensões
usando ON CONFLICT DO NOTHING para idempotência.

FAESA — Ciência da Computação — Business Intelligence 2026/1
Projeto: Data Warehouse COVID-19 — Espírito Santo
"""

from sqlalchemy import create_engine, text

# ── Configuração ──────────────────────────────────────────────────────────────
# Ajuste a connection string conforme seu ambiente
ENGINE = create_engine(
    "postgresql+psycopg2://postgres:postgres@localhost:5432/dw_covid"
)


def carregar_dimensao(nome_tabela: str, colunas_origem: list, colunas_destino: list):
    """
    Extrai combinações distintas da staging e insere na dimensão.
    Usa ON CONFLICT DO NOTHING para idempotência.
    """
    col_src = ", ".join(colunas_origem)
    col_dst = ", ".join(colunas_destino)
    sql = f"""
        INSERT INTO dw.{nome_tabela} ({col_dst})
        SELECT DISTINCT {col_src}
        FROM stg.notificacao_raw
        ON CONFLICT ({col_dst}) DO NOTHING;
    """
    with ENGINE.begin() as conn:
        conn.execute(text(sql))
    print(f"[OK] Dimensão {nome_tabela} carregada.")


# ── DIM_LOCALIDADE ────────────────────────────────────────────────────────────
carregar_dimensao(
    "dim_localidade",
    colunas_origem=["municipio", "bairro"],
    colunas_destino=["municipio", "bairro"]
)

# ── DIM_CLASSIFICACAO ─────────────────────────────────────────────────────────
carregar_dimensao(
    "dim_classificacao",
    colunas_origem=["classificacao", "evolucao",
                    "criterio_confirmacao", "status_notificacao"],
    colunas_destino=["classificacao", "evolucao",
                     "criterio_confirmacao", "status_notificacao"]
)

# ── DIM_PERFIL_PACIENTE ───────────────────────────────────────────────────────
carregar_dimensao(
    "dim_perfil_paciente",
    colunas_origem=["sexo", "faixa_etaria", "raca_cor", "escolaridade",
                    "gestante", "profissional_saude", "morador_rua",
                    "possui_deficiencia"],
    colunas_destino=["sexo", "faixa_etaria", "raca_cor", "escolaridade",
                     "gestante", "profissional_saude", "morador_rua",
                     "possui_deficiencia"]
)

# ── DIM_SINTOMAS (junk dimension) ────────────────────────────────────────────
carregar_dimensao(
    "dim_sintomas",
    colunas_origem=["febre", "dif_respiratoria", "tosse", "coriza",
                    "dor_garganta", "diarreia", "cefaleia"],
    colunas_destino=["febre", "dif_respiratoria", "tosse", "coriza",
                     "dor_garganta", "diarreia", "cefaleia"]
)

# ── DIM_COMORBIDADE (junk dimension) ─────────────────────────────────────────
carregar_dimensao(
    "dim_comorbidade",
    colunas_origem=["com_pulmao", "com_cardio", "com_renal",
                    "com_diabetes", "com_tabagismo", "com_obesidade"],
    colunas_destino=["com_pulmao", "com_cardio", "com_renal",
                     "com_diabetes", "com_tabagismo", "com_obesidade"]
)

# ── DIM_TESTE ─────────────────────────────────────────────────────────────────
carregar_dimensao(
    "dim_teste",
    colunas_origem=["tipo_teste_rapido", "resultado_rt_pcr",
                    "resultado_teste_rap", "resultado_sorologia",
                    "resultado_sorol_igg"],
    colunas_destino=["tipo_teste_rapido", "resultado_rt_pcr",
                     "resultado_teste_rap", "resultado_sorologia",
                     "resultado_sorol_igg"]
)

print("\n✅ Todas as dimensões foram carregadas com sucesso!")

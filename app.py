import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np
import os

# ── Configuração da página ────────────────────────────────────────────────────
st.set_page_config(
    page_title="COVID-19 ES · Dashboard BI",
    page_icon="🦠",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── CSS customizado ───────────────────────────────────────────────────────────
st.markdown("""
<style>
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@300;400;600;700&display=swap');

html, body, [class*="css"] {
    font-family: 'IBM Plex Sans', sans-serif;
}

/* Fundo geral */
.stApp { background-color: #0d1117; }

/* Sidebar */
section[data-testid="stSidebar"] {
    background-color: #161b22;
    border-right: 1px solid #30363d;
}

/* Títulos */
h1, h2, h3 { font-family: 'IBM Plex Mono', monospace; color: #e6edf3; }

/* Métricas */
[data-testid="metric-container"] {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 16px;
}
[data-testid="metric-container"] label { color: #8b949e !important; font-size: 12px !important; }
[data-testid="metric-container"] [data-testid="stMetricValue"] {
    color: #58a6ff !important;
    font-family: 'IBM Plex Mono', monospace;
    font-size: 28px !important;
}
[data-testid="metric-container"] [data-testid="stMetricDelta"] { font-size: 12px !important; }

/* Divisor */
hr { border-color: #30363d; }

/* Selectbox / slider labels */
label { color: #8b949e !important; }

/* Scrollbar */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: #0d1117; }
::-webkit-scrollbar-thumb { background: #30363d; border-radius: 3px; }
</style>
""", unsafe_allow_html=True)

# ── Tema matplotlib ───────────────────────────────────────────────────────────
plt.rcParams.update({
    "figure.facecolor": "#161b22",
    "axes.facecolor":   "#161b22",
    "axes.edgecolor":   "#30363d",
    "axes.labelcolor":  "#8b949e",
    "xtick.color":      "#8b949e",
    "ytick.color":      "#8b949e",
    "text.color":       "#e6edf3",
    "grid.color":       "#21262d",
    "grid.linestyle":   "--",
    "grid.alpha":       0.6,
    "font.family":      "monospace",
    "axes.titlesize":   12,
    "axes.labelsize":   10,
})

ACCENT    = "#58a6ff"
ACCENT2   = "#3fb950"
DANGER    = "#f85149"
WARNING   = "#d29922"
PURPLE    = "#a371f7"
GRAY      = "#8b949e"

# ── Carregamento de dados ─────────────────────────────────────────────────────
@st.cache_data(show_spinner=False)
def carregar_dados(caminho: str, taxa: float, seed: int) -> pd.DataFrame:
    np.random.seed(seed)
    with open(caminho, "r", encoding="latin-1") as f:
        total_linhas = sum(1 for _ in f) - 1
    n_amostrar  = int(total_linhas * taxa)
    todas       = np.arange(1, total_linhas + 1)
    linhas_pular = np.sort(
        np.random.choice(todas, size=total_linhas - n_amostrar, replace=False)
    )
    df = pd.read_csv(caminho, sep=";", encoding="latin-1",
                     low_memory=False, skiprows=linhas_pular)
    df["DataNotificacao"] = pd.to_datetime(df["DataNotificacao"], errors="coerce")
    df["AnoMes"] = df["DataNotificacao"].dt.to_period("M")
    return df

# ── Sidebar ───────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("## 🦠 COVID-19 ES")
    st.markdown("**Dashboard de Business Intelligence**")
    st.markdown("---")

    st.markdown("### 📂 Fonte de Dados")
    caminho_csv = st.text_input("Caminho do arquivo CSV", value="MICRODADOS.csv")
    taxa_amostra = st.slider("Taxa de amostragem (%)", 1, 100, 10, step=1)
    seed_val = st.number_input("Seed aleatória", value=42, step=1)

    carregar = st.button("🔄 Carregar / Atualizar dados", use_container_width=True)
    st.markdown("---")
    st.markdown("### 🔍 Filtros Globais")

# ── Estado de sessão ──────────────────────────────────────────────────────────
if "df" not in st.session_state:
    st.session_state.df = None
if "erro" not in st.session_state:
    st.session_state.erro = None

if carregar:
    if not os.path.exists(caminho_csv):
        st.session_state.erro = f"Arquivo não encontrado: `{caminho_csv}`"
        st.session_state.df   = None
    else:
        with st.spinner("Carregando amostra do CSV..."):
            try:
                st.session_state.df   = carregar_dados(caminho_csv, taxa_amostra / 100, seed_val)
                st.session_state.erro = None
            except Exception as e:
                st.session_state.erro = str(e)
                st.session_state.df   = None

# ── Filtros globais (só aparecem se dados carregados) ─────────────────────────
df_raw = st.session_state.df

if df_raw is not None:
    with st.sidebar:
        classificacoes_disp = ["Todas"] + sorted(df_raw["Classificacao"].dropna().unique().tolist())
        filtro_class = st.selectbox("Classificação", classificacoes_disp)

        if "Municipio" in df_raw.columns:
            municipios_disp = ["Todos"] + sorted(df_raw["Municipio"].dropna().unique().tolist())
            filtro_mun = st.selectbox("Município", municipios_disp)
        else:
            filtro_mun = "Todos"

        datas_validas = df_raw["DataNotificacao"].dropna()
        if not datas_validas.empty:
            d_min = datas_validas.min().date()
            d_max = datas_validas.max().date()
            intervalo = st.date_input("Período", value=(d_min, d_max),
                                       min_value=d_min, max_value=d_max)
        else:
            intervalo = None

    # Aplica filtros
    df = df_raw.copy()
    if filtro_class != "Todas":
        df = df[df["Classificacao"] == filtro_class]
    if filtro_mun != "Todos":
        df = df[df["Municipio"] == filtro_mun]
    if intervalo and len(intervalo) == 2:
        df = df[
            (df["DataNotificacao"].dt.date >= intervalo[0]) &
            (df["DataNotificacao"].dt.date <= intervalo[1])
        ]
else:
    df = None

# ── Header ────────────────────────────────────────────────────────────────────
st.markdown("""
<h1 style='font-size:2rem; margin-bottom:0;'>
  <span style='color:#58a6ff;'>COVID-19</span>
  <span style='color:#e6edf3;'> · Espírito Santo</span>
</h1>
<p style='color:#8b949e; font-family:IBM Plex Mono,monospace; font-size:0.85rem; margin-top:4px;'>
  Análise Exploratória de Dados · Microdados Oficiais
</p>
""", unsafe_allow_html=True)
st.markdown("---")

# ── Tela inicial (sem dados) ──────────────────────────────────────────────────
if df is None or st.session_state.df is None:
    if st.session_state.erro:
        st.error(f"❌ {st.session_state.erro}")

    st.markdown("""
    <div style='text-align:center; padding: 60px 20px;'>
      <div style='font-size:4rem;'>📊</div>
      <h2 style='color:#8b949e;'>Nenhum dado carregado</h2>
      <p style='color:#484f58;'>
        Informe o caminho do arquivo <code>MICRODADOS.csv</code> na barra lateral
        e clique em <strong>Carregar / Atualizar dados</strong>.
      </p>
      <hr style='border-color:#21262d; margin: 30px auto; width:40%;'>
      <p style='color:#484f58; font-size:0.8rem;'>
        Baixe os microdados em:
        <a href='https://coronavirus.es.gov.br/painel-covid-19-es' target='_blank'
           style='color:#58a6ff;'>coronavirus.es.gov.br/painel-covid-19-es</a>
      </p>
    </div>
    """, unsafe_allow_html=True)
    st.stop()

# ── Abas ──────────────────────────────────────────────────────────────────────
tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "📋 Visão Geral",
    "🏥 Casos & Classificação",
    "👥 Perfil Epidemiológico",
    "🔬 Clínico",
    "📈 Temporal",
])

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 1 · VISÃO GERAL
# ═══════════════════════════════════════════════════════════════════════════════
with tab1:
    st.markdown("### Métricas Gerais")
    c1, c2, c3, c4, c5 = st.columns(5)

    total = len(df)
    confirmados_n = (df["Classificacao"] == "Confirmados").sum() if "Classificacao" in df.columns else 0
    obitos_n = (df.get("Evolucao", pd.Series(dtype=str)) == "Óbito pelo COVID-19").sum()
    curas_n  = (df.get("Evolucao", pd.Series(dtype=str)) == "Cura").sum()
    taxa_let = (obitos_n / confirmados_n * 100) if confirmados_n > 0 else 0

    c1.metric("Total de Registros",    f"{total:,}")
    c2.metric("Confirmados",           f"{confirmados_n:,}")
    c3.metric("Óbitos COVID",          f"{obitos_n:,}")
    c4.metric("Curas",                 f"{curas_n:,}")
    c5.metric("Taxa de Letalidade",    f"{taxa_let:.2f}%")

    st.markdown("---")

    col_a, col_b = st.columns(2)

    with col_a:
        st.markdown("#### Tipos de Dados das Colunas")
        dtypes_df = df.dtypes.reset_index()
        dtypes_df.columns = ["Coluna", "Tipo"]
        dtypes_df["Tipo"] = dtypes_df["Tipo"].astype(str)
        st.dataframe(dtypes_df, use_container_width=True, height=350)

    with col_b:
        st.markdown("#### Valores Nulos por Coluna")
        nulos = df.isnull().sum()
        nulos = nulos[nulos > 0].sort_values(ascending=False)
        if nulos.empty:
            st.success("✅ Nenhum valor nulo encontrado no filtro atual.")
        else:
            nulos_df = pd.DataFrame({
                "Coluna": nulos.index,
                "Qtd Nulos": nulos.values,
                "Percentual (%)": (nulos.values / total * 100).round(2),
            })
            st.dataframe(nulos_df, use_container_width=True, height=350)

    st.markdown("---")
    st.markdown("#### Primeiros Registros")
    st.dataframe(df.head(20), use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 2 · CASOS & CLASSIFICAÇÃO
# ═══════════════════════════════════════════════════════════════════════════════
with tab2:
    col1, col2 = st.columns(2)

    # Exercício 2 – Distribuição por Classificação
    with col1:
        st.markdown("#### Ex. 2 · Distribuição por Classificação")
        if "Classificacao" in df.columns:
            freq = df["Classificacao"].value_counts()
            fig, ax = plt.subplots(figsize=(6, 3.5))
            colors = [ACCENT, DANGER, WARNING, ACCENT2, PURPLE][:len(freq)]
            bars = ax.barh(freq.index, freq.values, color=colors)
            for bar, val in zip(bars, freq.values):
                ax.text(bar.get_width() + max(freq.values) * 0.01,
                        bar.get_y() + bar.get_height() / 2,
                        f"{val:,}", va="center", fontsize=9, color=GRAY)
            ax.set_xlabel("Notificações")
            ax.set_title("Notificações por Classificação")
            ax.grid(axis="x")
            fig.tight_layout()
            st.pyplot(fig)
            plt.close(fig)

            freq_df = pd.DataFrame({"Categoria": freq.index,
                                     "Absoluto": freq.values,
                                     "% ": (freq.values / total * 100).round(2)})
            st.dataframe(freq_df, use_container_width=True, hide_index=True)

    # Exercício 3 – Top 10 Municípios
    with col2:
        st.markdown("#### Ex. 3 · Top 10 Municípios")
        if "Municipio" in df.columns:
            top10 = df["Municipio"].value_counts().head(10)
            fig, ax = plt.subplots(figsize=(6, 3.5))
            palette = plt.cm.Blues_r(np.linspace(0.25, 0.85, 10))
            bars = ax.barh(top10.index[::-1], top10.values[::-1], color=palette)
            for bar, val in zip(bars, top10.values[::-1]):
                ax.text(bar.get_width() + max(top10.values) * 0.01,
                        bar.get_y() + bar.get_height() / 2,
                        f"{val:,}", va="center", fontsize=8, color=GRAY)
            ax.set_xlabel("Notificações")
            ax.set_title("Top 10 Municípios por Notificações")
            ax.grid(axis="x")
            fig.tight_layout()
            st.pyplot(fig)
            plt.close(fig)

            lider = top10.index[0]
            st.info(f"🥇 **{lider}** lidera com **{top10.iloc[0]:,}** notificações.")

    st.markdown("---")

    # Exercício 6 – Taxa de Letalidade
    st.markdown("#### Ex. 6 · Taxa de Letalidade (Casos Confirmados)")
    if "Classificacao" in df.columns and "Evolucao" in df.columns:
        conf_df   = df[df["Classificacao"] == "Confirmados"]
        tot_conf  = len(conf_df)
        ev_counts = conf_df["Evolucao"].value_counts()

        c1, c2, c3, c4 = st.columns(4)
        ob_cov  = ev_counts.get("Óbito pelo COVID-19", 0)
        ob_out  = ev_counts.get("Óbito por outras causas", 0)
        cura    = ev_counts.get("Cura", 0)
        ign     = ev_counts.get("Ignorado", 0)
        tx      = (ob_cov / tot_conf * 100) if tot_conf > 0 else 0

        c1.metric("Óbitos COVID",        f"{ob_cov:,}",  delta=f"{ob_cov/tot_conf*100:.2f}%" if tot_conf else "—")
        c2.metric("Óbitos outras causas",f"{ob_out:,}")
        c3.metric("Curas",               f"{cura:,}")
        c4.metric("Taxa de Letalidade",  f"{tx:.2f}%")

    # Exercício 10 – Pivot Table
    st.markdown("---")
    st.markdown("#### Ex. 10 · Tabela Cruzada – Top 5 Municípios × Evolução")
    if all(c in df.columns for c in ["Classificacao", "Municipio", "Evolucao"]):
        conf_df = df[df["Classificacao"] == "Confirmados"]
        top5_mun = conf_df["Municipio"].value_counts().head(5).index.tolist()
        conf5    = conf_df[conf_df["Municipio"].isin(top5_mun)]
        cross    = pd.crosstab(conf5["Municipio"], conf5["Evolucao"])
        st.dataframe(cross, use_container_width=True)

        letal_data = []
        for m in top5_mun:
            tot = (conf_df["Municipio"] == m).sum()
            ob  = ((conf_df["Municipio"] == m) & (conf_df["Evolucao"] == "Óbito pelo COVID-19")).sum()
            tx  = (ob / tot * 100) if tot > 0 else 0
            letal_data.append({"Município": m, "Confirmados": tot, "Óbitos COVID": ob, "Letalidade (%)": round(tx, 2)})
        letal_df = pd.DataFrame(letal_data).sort_values("Letalidade (%)", ascending=False)
        st.dataframe(letal_df, use_container_width=True, hide_index=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 3 · PERFIL EPIDEMIOLÓGICO
# ═══════════════════════════════════════════════════════════════════════════════
with tab3:
    col1, col2 = st.columns(2)

    # Exercício 4 – Sexo
    with col1:
        st.markdown("#### Ex. 4 · Distribuição por Sexo")
        if "Sexo" in df.columns:
            sexo_counts = df["Sexo"].value_counts(dropna=True)
            labels_map  = {"F": "Feminino", "M": "Masculino", "I": "Ignorado"}
            labels      = [labels_map.get(x, x) for x in sexo_counts.index]
            fig, ax = plt.subplots(figsize=(5, 4))
            wedge_kw = {"edgecolor": "#0d1117", "linewidth": 2}
            ax.pie(sexo_counts.values, labels=labels, autopct="%1.1f%%",
                   colors=[PURPLE, ACCENT, GRAY], startangle=90,
                   wedgeprops=wedge_kw, textprops={"fontsize": 11})
            ax.set_title("Notificações por Sexo")
            fig.tight_layout()
            st.pyplot(fig)
            plt.close(fig)

    # Exercício 5 – Faixa Etária
    with col2:
        st.markdown("#### Ex. 5 · Casos por Faixa Etária")
        if "FaixaEtaria" in df.columns:
            ordem = ["0-4","5-9","10-19","20-29","30-39","40-49","50-59","60-69","70-79","80+"]
            fe = df["FaixaEtaria"].value_counts().reindex(ordem, fill_value=0)
            fig, ax = plt.subplots(figsize=(6, 3.8))
            cores = [DANGER if v == fe.max() else ACCENT for v in fe.values]
            bars = ax.bar(fe.index, fe.values, color=cores)
            for bar, val in zip(bars, fe.values):
                ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(fe.values) * 0.01,
                        f"{val:,}", ha="center", fontsize=8, color=GRAY)
            ax.set_xlabel("Faixa Etária")
            ax.set_ylabel("Notificações")
            ax.set_title("Notificações por Faixa Etária")
            ax.grid(axis="y")
            plt.xticks(rotation=30)
            fig.tight_layout()
            st.pyplot(fig)
            plt.close(fig)

            pico_faixa = fe.idxmax()
            st.info(f"📌 Maior volume: faixa **{pico_faixa}** com **{fe.max():,}** notificações.")


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 4 · CLÍNICO
# ═══════════════════════════════════════════════════════════════════════════════
with tab4:
    col1, col2 = st.columns(2)

    # Exercício 7 – Sintomas
    with col1:
        st.markdown("#### Ex. 7 · Sintomas mais Frequentes")
        cols_sint = {
            "Febre": "Febre",
            "DificuldadeRespiratoria": "Dif. Respiratória",
            "Tosse": "Tosse",
            "Coriza": "Coriza",
            "DorGarganta": "Dor de Garganta",
            "Diarreia": "Diarreia",
            "Cefaleia": "Cefaleia",
        }
        sint_data = {nome: (df[col] == "Sim").sum()
                     for col, nome in cols_sint.items() if col in df.columns}
        if sint_data:
            sint_s = pd.Series(sint_data).sort_values(ascending=True)
            fig, ax = plt.subplots(figsize=(6, 4))
            n = len(sint_s)
            cores = plt.cm.YlOrRd(np.linspace(0.3, 0.9, n))
            bars = ax.barh(sint_s.index, sint_s.values, color=cores)
            for bar, val in zip(bars, sint_s.values):
                ax.text(bar.get_width() + max(sint_s.values) * 0.01,
                        bar.get_y() + bar.get_height() / 2,
                        f"{val:,}", va="center", fontsize=9, color=GRAY)
            ax.set_xlabel("Registros com 'Sim'")
            ax.set_title("Sintomas por Frequência")
            ax.grid(axis="x")
            fig.tight_layout()
            st.pyplot(fig)
            plt.close(fig)

    # Exercício 8 – Comorbidades nos óbitos
    with col2:
        st.markdown("#### Ex. 8 · Comorbidades nos Óbitos COVID")
        cols_comor = {
            "ComorbidadePulmao":    "Doença Pulmonar",
            "ComorbidadeCardio":    "Cardiovascular",
            "ComorbidadeRenal":     "Doença Renal",
            "ComorbidadeDiabetes":  "Diabetes",
            "ComorbidadeTabagismo": "Tabagismo",
            "ComorbidadeObesidade": "Obesidade",
        }
        if "Evolucao" in df.columns:
            obitos_df = df[df["Evolucao"] == "Óbito pelo COVID-19"]
            comor_data = {nome: (obitos_df[col] == "Sim").sum()
                          for col, nome in cols_comor.items() if col in obitos_df.columns}
            if comor_data:
                comor_s = pd.Series(comor_data).sort_values(ascending=True)
                fig, ax = plt.subplots(figsize=(6, 4))
                cores = plt.cm.Reds(np.linspace(0.4, 0.9, len(comor_s)))
                bars  = ax.barh(comor_s.index, comor_s.values, color=cores)
                for bar, val in zip(bars, comor_s.values):
                    ax.text(bar.get_width() + max(comor_s.values, default=1) * 0.01,
                            bar.get_y() + bar.get_height() / 2,
                            f"{val:,}", va="center", fontsize=9, color=GRAY)
                ax.set_xlabel("Óbitos com a comorbidade")
                ax.set_title("Comorbidades nos Óbitos por COVID-19")
                ax.grid(axis="x")
                fig.tight_layout()
                st.pyplot(fig)
                plt.close(fig)

                top_comor = comor_s.idxmax()
                st.warning(f"⚠️ **{top_comor}** é a comorbidade mais presente nos óbitos.")
            else:
                st.info("Colunas de comorbidade não encontradas nos dados filtrados.")
        else:
            st.info("Coluna 'Evolucao' não encontrada.")


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 5 · TEMPORAL
# ═══════════════════════════════════════════════════════════════════════════════
with tab5:
    st.markdown("#### Ex. 9 · Evolução Temporal das Notificações")
    if "DataNotificacao" in df.columns:
        df_temp = df.dropna(subset=["DataNotificacao"]).copy()
        df_temp["AnoMes"] = df_temp["DataNotificacao"].dt.to_period("M")
        serie = df_temp.groupby("AnoMes").size().reset_index(name="Notificacoes")
        serie["AnoMes_str"] = serie["AnoMes"].astype(str)

        # Seletor de granularidade
        granular = st.radio("Granularidade", ["Mensal", "Trimestral", "Anual"], horizontal=True)
        if granular == "Trimestral":
            df_temp["AnoTri"] = df_temp["DataNotificacao"].dt.to_period("Q")
            serie = df_temp.groupby("AnoTri").size().reset_index(name="Notificacoes")
            serie["AnoMes_str"] = serie["AnoTri"].astype(str)
        elif granular == "Anual":
            df_temp["Ano"] = df_temp["DataNotificacao"].dt.year
            serie = df_temp.groupby("Ano").size().reset_index(name="Notificacoes")
            serie["AnoMes_str"] = serie["Ano"].astype(str)

        fig, ax = plt.subplots(figsize=(14, 5))
        x = np.arange(len(serie))
        ax.fill_between(x, serie["Notificacoes"], alpha=0.15, color=ACCENT)
        ax.plot(x, serie["Notificacoes"], color=ACCENT, linewidth=2, marker="o", markersize=4)

        # Marca pico
        idx_pico = serie["Notificacoes"].idxmax()
        ax.scatter(idx_pico, serie["Notificacoes"].iloc[idx_pico],
                   color=DANGER, s=120, zorder=5)
        ax.annotate(
            f"Pico\n{serie['AnoMes_str'].iloc[idx_pico]}\n{serie['Notificacoes'].iloc[idx_pico]:,}",
            xy=(idx_pico, serie["Notificacoes"].iloc[idx_pico]),
            xytext=(idx_pico, serie["Notificacoes"].iloc[idx_pico] * 1.12),
            ha="center", fontsize=8, color=DANGER,
            arrowprops=dict(arrowstyle="->", color=DANGER),
        )

        tick_step = max(1, len(serie) // 12)
        ax.set_xticks(x[::tick_step])
        ax.set_xticklabels(serie["AnoMes_str"].iloc[::tick_step], rotation=45, ha="right")
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f"{int(v):,}"))
        ax.set_title("Evolução Temporal das Notificações – COVID-19 ES")
        ax.set_ylabel("Notificações")
        ax.grid(axis="y")
        fig.tight_layout()
        st.pyplot(fig)
        plt.close(fig)

        # Top meses
        st.markdown("##### Top 10 Períodos com Mais Notificações")
        top_periodos = serie.nlargest(10, "Notificacoes")[["AnoMes_str", "Notificacoes"]].rename(
            columns={"AnoMes_str": "Período", "Notificacoes": "Notificações"}
        )
        st.dataframe(top_periodos, use_container_width=True, hide_index=True)
    else:
        st.info("Coluna 'DataNotificacao' não encontrada.")

# ── Footer ────────────────────────────────────────────────────────────────────
st.markdown("---")
st.markdown(
    "<p style='text-align:center; color:#484f58; font-size:0.75rem; font-family:IBM Plex Mono,monospace;'>"
    "Dashboard BI · COVID-19 Espírito Santo · Dados: coronavirus.es.gov.br"
    "</p>",
    unsafe_allow_html=True
)

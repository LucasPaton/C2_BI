# C2_BI — Data Warehouse COVID-19 · Espírito Santo

> Disciplina: **Business Intelligence** — FAESA · Ciência da Computação · 2026/1  
> Prof. Otávio Lube

---

## 📋 Descrição

Projeto completo de construção de um **Data Warehouse** em esquema estrela para análise das notificações de COVID-19 do estado do Espírito Santo, seguindo a metodologia **Kimball**.

O projeto cobre:
- **Análise Exploratória de Dados (AED)** — notebook Jupyter e dashboard Streamlit interativo
- **Modelagem multidimensional** — esquema estrela com 7 dimensões
- **ETL (Extract, Transform, Load)** — scripts SQL e Python
- **Consultas analíticas OLAP** — validação do modelo

---

## 🚀 Instalação

### Pré-requisitos

Antes de começar, certifique-se de ter instalado:

| Ferramenta | Versão Mínima | Download |
|------------|---------------|----------|
| **Python** | 3.10+ | [python.org](https://www.python.org/downloads/) |
| **PostgreSQL** | 14+ | [postgresql.org](https://www.postgresql.org/download/) |
| **Git** | 2.0+ | [git-scm.com](https://git-scm.com/downloads) |

### Passo 1 — Clonar o repositório

```bash
git clone https://github.com/LucasPaton/C2_BI.git
cd C2_BI
```

### Passo 2 — Criar e ativar o ambiente virtual

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**Windows (CMD):**
```cmd
python -m venv .venv
.venv\Scripts\activate.bat
```

**Linux / macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### Passo 3 — Instalar as dependências

```bash
pip install -r requirements.txt
```

Isso vai instalar automaticamente:
- `streamlit` — framework do dashboard interativo
- `pandas` — manipulação de dados
- `matplotlib` — gráficos e visualizações
- `numpy` — operações numéricas
- `sqlalchemy` — ORM para conexão com PostgreSQL
- `psycopg2-binary` — driver PostgreSQL para Python
- `tqdm` — barras de progresso
- `python-dateutil` — utilitários de data

### Passo 4 — Obter o arquivo de dados

Baixe o arquivo `MICRODADOS.csv` do portal oficial:

🔗 **[coronavirus.es.gov.br/painel-covid-19-es](https://coronavirus.es.gov.br/painel-covid-19-es)**

Coloque o arquivo na raiz do projeto (mesma pasta do `app.py`).

> ⚠️ **Atenção:** O arquivo tem ~1.95 GB e **não está incluído no repositório** por questões de tamanho.

---

## ▶️ Como Executar

### Dashboard Streamlit

O dashboard interativo roda localmente com um único comando:

```bash
streamlit run app.py
```

O Streamlit vai abrir automaticamente no navegador em `http://localhost:8501`.

**No dashboard você pode:**
1. Informar o caminho do `MICRODADOS.csv` na barra lateral
2. Ajustar a taxa de amostragem (para testes rápidos, use 5-10%)
3. Clicar em **Carregar / Atualizar dados**
4. Explorar as 5 abas: Visão Geral, Casos, Perfil Epidemiológico, Clínico e Temporal

### Notebook Jupyter

```bash
pip install jupyter
jupyter notebook atividade_bi_covid19_es.ipynb
```

---

## 🗄️ Data Warehouse (PostgreSQL)

Se quiser construir o DW completo, execute os scripts SQL na ordem:

```bash
# 1. Criar banco e schemas
psql -U postgres -f sql/01_criar_banco.sql

# 2. Criar e popular staging (ajuste o caminho do CSV no script!)
psql -U postgres -d dw_covid -f sql/02_staging.sql

# 3. Criar modelo estrela (dimensões + fato)
psql -U postgres -d dw_covid -f sql/03_modelo_estrela.sql

# 4. Popular DIM_TEMPO
psql -U postgres -d dw_covid -f sql/04_dim_tempo.sql

# 5. ETL das dimensões (escolha UMA opção)
python etl_dimensoes.py                                       # Opção A: Python
psql -U postgres -d dw_covid -f sql/05_etl_dimensoes_sql.sql  # Opção B: SQL puro

# 6. Carga da tabela fato
psql -U postgres -d dw_covid -f sql/06_carga_fato.sql

# 7. Validação e consultas OLAP
psql -U postgres -d dw_covid -f sql/07_validacao.sql
```

> 💡 **Dica:** No script `02_staging.sql`, altere `/caminho/absoluto/MICRODADOS.csv` para o caminho real do seu arquivo.

---

## 🏗️ Arquitetura do DW

```
MICRODADOS.csv ──→ stg.notificacao_raw ──→ dw.dim_* / dw.fato_* ──→ Dashboard BI
   (5.19M linhas)       EXTRACT              TRANSFORM + LOAD          CONSUME
```

### Modelo Estrela

| Tabela | Tipo | Descrição |
|--------|------|-----------|
| `dw.fato_notificacao_covid` | Fato | 1 linha = 1 notificação COVID-19 |
| `dw.dim_tempo` | Dimensão | Role-playing (6 FKs de data) |
| `dw.dim_localidade` | Dimensão | Município + Bairro |
| `dw.dim_perfil_paciente` | Dimensão | Sexo, faixa etária, raça, escolaridade... |
| `dw.dim_classificacao` | Dimensão | Classificação, evolução, status |
| `dw.dim_sintomas` | Junk Dim | 7 flags de sintomas |
| `dw.dim_comorbidade` | Junk Dim | 6 flags de comorbidades |
| `dw.dim_teste` | Dimensão | Tipos e resultados de exames |

---

## 📁 Estrutura do Projeto

```
C2_BI/
├── .gitignore                       # Arquivos ignorados pelo Git
├── README.md                        # Este arquivo
├── requirements.txt                 # Dependências Python
├── app.py                           # Dashboard Streamlit
├── atividade_bi_covid19_es.ipynb    # Notebook com exercícios AED
├── etl_dimensoes.py                 # ETL Python para dimensões
└── sql/
    ├── 01_criar_banco.sql           # CREATE DATABASE + schemas
    ├── 02_staging.sql               # DDL staging + COPY
    ├── 03_modelo_estrela.sql        # DDL dimensões + fato
    ├── 04_dim_tempo.sql             # Povoar DIM_TEMPO
    ├── 05_etl_dimensoes_sql.sql     # ETL dimensões (SQL puro)
    ├── 06_carga_fato.sql            # Carga da fato com JOINs
    └── 07_validacao.sql             # Testes + consultas OLAP
```

---

## 🛠️ Troubleshooting

| Problema | Solução |
|----------|---------|
| `streamlit: command not found` | Ative o ambiente virtual: `.venv\Scripts\activate` |
| Erro de encoding no CSV | O CSV usa Latin-1. O `app.py` já trata isso automaticamente |
| Dashboard lento | Reduza a taxa de amostragem na barra lateral (ex: 5%) |
| Erro no PostgreSQL com COPY | Verifique o caminho absoluto do CSV no script `02_staging.sql` |
| `ModuleNotFoundError` | Execute `pip install -r requirements.txt` novamente |

---

*Projeto acadêmico — FAESA 2026/1*

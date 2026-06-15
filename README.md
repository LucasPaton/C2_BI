# C2_BI — Data Warehouse COVID-19 · Espírito Santo

> Disciplina: **Business Intelligence** — FAESA · Ciência da Computação · 2026/1  
> Prof. Otávio Lube

## 📋 Descrição

Projeto completo de construção de um **Data Warehouse** em esquema estrela para análise das notificações de COVID-19 do estado do Espírito Santo, seguindo a metodologia **Kimball**.

O projeto cobre:
- **Análise Exploratória de Dados (AED)** — notebook e dashboard Streamlit
- **Modelagem multidimensional** — esquema estrela com 7 dimensões
- **ETL (Extract, Transform, Load)** — scripts SQL e Python
- **Consultas analíticas OLAP** — validação do modelo

## 🏗️ Arquitetura

```
MICRODADOS.csv ──→ stg.notificacao_raw ──→ dw.dim_* / dw.fato_* ──→ Dashboard BI
   (5.19M linhas)       EXTRACT              TRANSFORM + LOAD          CONSUME
```

### Modelo Estrela

| Tabela                    | Tipo      | Descrição                                   |
|---------------------------|-----------|---------------------------------------------|
| `dw.fato_notificacao_covid` | Fato      | 1 linha = 1 notificação COVID-19           |
| `dw.dim_tempo`            | Dimensão  | Role-playing (6 FKs de data)                |
| `dw.dim_localidade`       | Dimensão  | Município + Bairro                          |
| `dw.dim_perfil_paciente`  | Dimensão  | Sexo, faixa etária, raça, escolaridade...   |
| `dw.dim_classificacao`    | Dimensão  | Classificação, evolução, status             |
| `dw.dim_sintomas`         | Junk Dim  | 7 flags de sintomas                         |
| `dw.dim_comorbidade`      | Junk Dim  | 6 flags de comorbidades                     |
| `dw.dim_teste`            | Dimensão  | Tipos e resultados de exames                |

## 🚀 Pré-requisitos

- **PostgreSQL 14+**
- **Python 3.10+**
- Arquivo `MICRODADOS.csv` (não incluído no repositório — ~1.95 GB)

## ⚙️ Instalação

```bash
# 1. Clone o repositório
git clone <url-do-repo>
cd C2_BI

# 2. Crie o ambiente virtual
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# .venv\Scripts\activate   # Windows

# 3. Instale as dependências
pip install -r requirements.txt
```

## 📦 Execução dos Scripts SQL

Execute os scripts na ordem no PostgreSQL:

```bash
# 1. Criar banco e schemas
psql -U postgres -f sql/01_criar_banco.sql

# 2. Criar e popular staging
psql -U postgres -d dw_covid -f sql/02_staging.sql

# 3. Criar modelo estrela (dimensões + fato)
psql -U postgres -d dw_covid -f sql/03_modelo_estrela.sql

# 4. Popular DIM_TEMPO
psql -U postgres -d dw_covid -f sql/04_dim_tempo.sql

# 5. ETL das dimensões (escolha uma opção)
python etl_dimensoes.py                           # Opção A: Python
psql -U postgres -d dw_covid -f sql/05_etl_dimensoes_sql.sql  # Opção B: SQL puro

# 6. Carga da tabela fato
psql -U postgres -d dw_covid -f sql/06_carga_fato.sql

# 7. Validação e consultas OLAP
psql -U postgres -d dw_covid -f sql/07_validacao.sql
```

## 📊 Dashboard Streamlit

```bash
streamlit run app.py
```

## 📁 Estrutura do Projeto

```
C2_BI/
├── .gitignore
├── README.md
├── requirements.txt
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

## 📝 Dados

O arquivo `MICRODADOS.csv` pode ser obtido em:  
🔗 [coronavirus.es.gov.br/painel-covid-19-es](https://coronavirus.es.gov.br/painel-covid-19-es)

---

*Projeto acadêmico — FAESA 2026/1*

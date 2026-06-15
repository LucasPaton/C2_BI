-- ============================================================================
-- 01_criar_banco.sql
-- Passo 1: Preparação do Ambiente — Criação do banco e schemas
-- ============================================================================
-- FAESA — Ciência da Computação — Business Intelligence 2026/1
-- Projeto: Data Warehouse COVID-19 — Espírito Santo
-- ============================================================================

-- Executar conectado ao postgres (usuário administrador):
--   psql -U postgres -f sql/01_criar_banco.sql

-- 1) Criar o banco de dados
CREATE DATABASE dw_covid
    ENCODING 'UTF8'
    LC_COLLATE 'pt_BR.UTF-8'
    LC_CTYPE   'pt_BR.UTF-8'
    TEMPLATE   template0;

-- 2) Conectar ao banco recém-criado
\c dw_covid

-- 3) Criar os schemas do DW
CREATE SCHEMA stg;    -- staging: dados brutos do CSV
CREATE SCHEMA dw;     -- data warehouse: modelo estrela (dimensões + fato)
CREATE SCHEMA mart;   -- data marts: views e agregações para BI

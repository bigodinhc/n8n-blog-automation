# RAG Design Document - Minerals Trading Daily

**Data:** 2026-01-05
**Versao:** 2.0
**Autor:** Claude Code
**Status:** Design Aprovado + Melhorias SOTA

> **v2.0 Changelog:** Integrado melhorias do TheAIAutomators SOTA RAG Blueprints v2.3.x:
> - Smart Chunker com hierarquia de documento
> - Hybrid Search (4 metodos: dense, sparse, ilike, fuzzy)
> - Record Manager para versionamento
> - Context Expansion via ranges
> - Agent SOP estruturado

---

## Sumario Executivo

Este documento detalha a implementacao de um sistema RAG (Retrieval-Augmented Generation) para o blog Minerals Trading Daily, baseado nos padroes do TheAIAutomators RAG Blueprint.

### Objetivo
Melhorar a qualidade dos artigos gerados pela AI atraves de:
- Contexto de posts anteriores
- Consistencia terminologica
- Deteccao de duplicacao
- Verificacao de fatos (grounding)

### Padrao Escolhido
**Multi-Agent Sequential (Padrao 8)** com elementos de:
- Query Classification (Padrao 4)
- Answer Verification (Padrao 2)
- Duplication Detection

### ROI Esperado
| Metrica | Antes | Depois |
|---------|-------|--------|
| Qualidade artigos | 6/10 | 8.5/10 |
| Duplicacao | ~5% | <0.5% |
| Consistencia termos | ~70% | >95% |
| Custo adicional | - | ~$5-10/mes |

---

## 1. Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MINERALS TRADING DAILY - RAG SYSTEM                  │
└─────────────────────────────────────────────────────────────────────────────┘

                              INDEXACAO (WF009)
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   02_cnt_posts ──┐                                                          │
│   (65 artigos)   │     ┌──────────────┐     ┌─────────────────────────┐    │
│                  ├────▶│   CHUNKER    │────▶│  09_rag_knowledge_chunks │    │
│   Guidelines ────┤     │  (~500 tok)  │     │      (pgvector)          │    │
│   Glossario ─────┘     └──────────────┘     └─────────────────────────┘    │
│                              │                         │                    │
│                              ▼                         │                    │
│                    ┌──────────────────┐               │                    │
│                    │ OpenAI Embeddings │               │                    │
│                    │ text-embedding-3  │               │                    │
│                    │    -small         │               │                    │
│                    └──────────────────┘               │                    │
│                                                        │                    │
└────────────────────────────────────────────────────────┼────────────────────┘
                                                         │
                              GERACAO (WF002 modificado) │
┌────────────────────────────────────────────────────────┼────────────────────┐
│                                                        │                    │
│   Nova Noticia RSS                                     │                    │
│        │                                               │                    │
│        ▼                                               │                    │
│   ┌─────────────────┐                                  │                    │
│   │ QUERY CLASSIFIER│──── Precisa RAG? ────────────────┘                    │
│   └─────────────────┘                                                       │
│        │                                                                    │
│        ├─── NAO (breaking news) ──▶ Gera direto                            │
│        │                                                                    │
│        ▼ SIM                                                                │
│   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐      │
│   │ RESEARCH AGENT  │────▶│ DUPLICATION     │────▶│  WRITER AGENT   │      │
│   │                 │     │ DETECTOR        │     │                 │      │
│   │ Tools:          │     │                 │     │ Tools:          │      │
│   │ • Vector Search │     │ Sim > 90%?      │     │ • Guidelines    │      │
│   │ • Price Data    │     │ → BLOQUEAR      │     │ • Glossary      │      │
│   │ • Baltic Data   │     └─────────────────┘     │ • Fact Check    │      │
│   └─────────────────┘                             └─────────────────┘      │
│                                                           │                 │
│                                                           ▼                 │
│                                                   ┌─────────────────┐      │
│                                                   │ VERIFY ANSWER   │      │
│                                                   │ Grounded?       │      │
│                                                   │ Score > 0.8?    │      │
│                                                   └─────────────────┘      │
│                                                           │                 │
│                                                           ▼                 │
│                                                      Artigo Final           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Schema do Banco de Dados

### 2.1 Habilitar pgvector

```sql
-- Executar uma vez no Supabase SQL Editor
CREATE EXTENSION IF NOT EXISTS vector;
```

### 2.2 Tabela Principal: 09_rag_knowledge_chunks

```sql
-- Tabela de chunks com embeddings (v2.0 - com hierarquia)
CREATE TABLE 09_rag_knowledge_chunks (
  -- Identificacao
  id bigserial PRIMARY KEY,

  -- Fonte do chunk
  source_type text NOT NULL CHECK (source_type IN (
    'post',           -- Artigos publicados
    'glossary',       -- Termos tecnicos
    'guideline',      -- Regras editoriais
    'price_context'   -- Contexto de precos
  )),
  source_id text NOT NULL,              -- UUID do post ou identificador unico
  chunk_index int NOT NULL DEFAULT 0,   -- Ordem do chunk no documento

  -- Conteudo
  chunk_text text NOT NULL,             -- Texto do chunk (max ~500 tokens)
  chunk_tokens int,                     -- Contagem de tokens

  -- Embedding (OpenAI text-embedding-3-small = 1536 dimensoes)
  embedding vector(1536),

  -- NOVO v2.0: Hierarquia do documento
  hierarchy_path text,                  -- Ex: "Mercado > Precos > IODEX"
  section_range int[],                  -- [start_index, end_index] da secao
  parent_range int[],                   -- [start_index, end_index] do documento
  headings_in_chunk jsonb DEFAULT '[]', -- Headings contidos neste chunk

  -- Metadados para filtros e contexto
  metadata jsonb DEFAULT '{}',
  -- Exemplos de metadata:
  -- post: {"title": "...", "date": "2026-01-05", "category": "prices", "tier": "T1", "doc_id": "uuid"}
  -- glossary: {"term": "IODEX", "category": "indices"}
  -- guideline: {"section": "tone", "priority": "high"}
  -- price_context: {"symbol": "IODEX62", "period": "7d"}

  -- Controle de versao
  content_hash text,                    -- Hash do conteudo para detectar mudancas
  version int DEFAULT 1,

  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  -- Soft delete
  is_active boolean DEFAULT true,

  -- Constraint para evitar duplicatas
  UNIQUE(source_type, source_id, chunk_index, version)
);

-- Comentario da tabela
COMMENT ON TABLE 09_rag_knowledge_chunks IS
'Knowledge base para RAG do blog. Contem chunks de posts, glossario e guidelines com embeddings vetoriais para busca semantica.';

-- Comentarios das colunas principais
COMMENT ON COLUMN 09_rag_knowledge_chunks.source_type IS 'Tipo da fonte: post, glossary, guideline, price_context';
COMMENT ON COLUMN 09_rag_knowledge_chunks.embedding IS 'Vetor de 1536 dimensoes (OpenAI text-embedding-3-small)';
COMMENT ON COLUMN 09_rag_knowledge_chunks.metadata IS 'Metadados JSON para filtros e contexto adicional';
```

### 2.3 Indices

```sql
-- Extensoes necessarias
CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fuzzy search

-- Indice vetorial para busca por similaridade (IVFFlat)
-- Bom para < 1M vetores, mais rapido que HNSW para insercao
CREATE INDEX idx_rag_chunks_embedding
  ON 09_rag_knowledge_chunks
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- Indice para filtros por tipo
CREATE INDEX idx_rag_chunks_source_type
  ON 09_rag_knowledge_chunks (source_type, is_active);

-- Indice para buscar chunks de um post especifico
CREATE INDEX idx_rag_chunks_source_id
  ON 09_rag_knowledge_chunks (source_id)
  WHERE is_active = true;

-- Indice para busca por metadata (GIN para JSONB)
CREATE INDEX idx_rag_chunks_metadata
  ON 09_rag_knowledge_chunks
  USING gin (metadata);

-- Indice para ordenacao por data
CREATE INDEX idx_rag_chunks_created
  ON 09_rag_knowledge_chunks (created_at DESC)
  WHERE is_active = true;

-- NOVO v2.0: Indice para hierarquia
CREATE INDEX idx_rag_chunks_hierarchy
  ON 09_rag_knowledge_chunks (hierarchy_path)
  WHERE is_active = true;

-- NOVO v2.0: Indice para fuzzy search (pg_trgm)
CREATE INDEX idx_rag_chunks_trgm
  ON 09_rag_knowledge_chunks
  USING gin (chunk_text gin_trgm_ops);

-- NOVO v2.0: Indice para full-text search em portugues
CREATE INDEX idx_rag_chunks_fts
  ON 09_rag_knowledge_chunks
  USING gin (to_tsvector('portuguese', chunk_text));
```

### 2.4 Record Manager (NOVO v2.0)

```sql
-- Tabela de controle de documentos indexados
-- Evita reprocessamento desnecessario e rastreia versoes
CREATE TABLE 09_rag_record_manager (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identificacao
  doc_id text UNIQUE NOT NULL,          -- UUID do post ou identificador
  doc_name text NOT NULL,               -- Titulo para facil identificacao
  source_type text NOT NULL,            -- post, glossary, guideline

  -- Controle de versao
  content_hash text NOT NULL,           -- SHA256 do conteudo
  version int DEFAULT 1,

  -- Estatisticas
  chunk_count int DEFAULT 0,            -- Quantos chunks foram gerados
  total_tokens int DEFAULT 0,           -- Total de tokens indexados

  -- Status do processamento
  status text DEFAULT 'pending' CHECK (status IN (
    'pending',      -- Aguardando processamento
    'processing',   -- Em processamento
    'complete',     -- Indexado com sucesso
    'error',        -- Erro na indexacao
    'outdated'      -- Nova versao disponivel
  )),
  error_message text,                   -- Mensagem de erro se houver

  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  indexed_at timestamptz,               -- Quando foi indexado

  -- Metadata adicional
  metadata jsonb DEFAULT '{}'
);

-- Indice para busca por status
CREATE INDEX idx_record_manager_status
  ON 09_rag_record_manager (status, source_type);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_record_manager_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_record_manager_updated
  BEFORE UPDATE ON 09_rag_record_manager
  FOR EACH ROW
  EXECUTE FUNCTION update_record_manager_timestamp();

-- Funcao para verificar se documento precisa reindexar
CREATE OR REPLACE FUNCTION check_document_update(
  p_doc_id text,
  p_content_hash text
)
RETURNS TABLE (
  needs_update boolean,
  current_version int,
  record_id uuid
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    (rm.content_hash != p_content_hash) as needs_update,
    rm.version as current_version,
    rm.id as record_id
  FROM 09_rag_record_manager rm
  WHERE rm.doc_id = p_doc_id;

  -- Se nao encontrou, retorna que precisa criar
  IF NOT FOUND THEN
    RETURN QUERY SELECT true, 0, NULL::uuid;
  END IF;
END;
$$;
```

### 2.5 Funcoes SQL para RAG

```sql
-- =============================================================================
-- HYBRID SEARCH (NOVO v2.0)
-- Combina 4 metodos de busca com pesos configuraveis
-- =============================================================================

CREATE OR REPLACE FUNCTION hybrid_search(
  query_text text,
  query_embedding vector(1536),
  match_count int DEFAULT 30,
  dense_weight float DEFAULT 0.7,      -- Busca vetorial (semantica)
  sparse_weight float DEFAULT 0.2,     -- Full-text search (keywords)
  ilike_weight float DEFAULT 0.05,     -- Busca exata (substring)
  fuzzy_weight float DEFAULT 0.05,     -- Busca fuzzy (typos)
  filter_source_type text DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  chunk_text text,
  metadata jsonb,
  hierarchy_path text,
  section_range int[],
  parent_range int[],
  dense_score float,
  sparse_score float,
  ilike_score float,
  fuzzy_score float,
  combined_score float
)
LANGUAGE plpgsql
AS $$
DECLARE
  ts_query tsquery;
BEGIN
  -- Prepara query para full-text search em portugues
  ts_query := plainto_tsquery('portuguese', query_text);

  RETURN QUERY
  WITH
  -- Busca vetorial (densa/semantica)
  dense_results AS (
    SELECT
      k.id,
      k.chunk_text,
      k.metadata,
      k.hierarchy_path,
      k.section_range,
      k.parent_range,
      1 - (k.embedding <=> query_embedding) as score
    FROM 09_rag_knowledge_chunks k
    WHERE k.is_active = true
      AND (filter_source_type IS NULL OR k.source_type = filter_source_type)
    ORDER BY k.embedding <=> query_embedding
    LIMIT match_count * 2
  ),

  -- Busca por keywords (esparsa) usando ts_vector
  sparse_results AS (
    SELECT
      k.id,
      ts_rank(to_tsvector('portuguese', k.chunk_text), ts_query) as score
    FROM 09_rag_knowledge_chunks k
    WHERE k.is_active = true
      AND (filter_source_type IS NULL OR k.source_type = filter_source_type)
      AND to_tsvector('portuguese', k.chunk_text) @@ ts_query
    ORDER BY score DESC
    LIMIT match_count * 2
  ),

  -- Busca ILIKE (substring exata)
  ilike_results AS (
    SELECT
      k.id,
      1.0 as score  -- Score binario
    FROM 09_rag_knowledge_chunks k
    WHERE k.is_active = true
      AND (filter_source_type IS NULL OR k.source_type = filter_source_type)
      AND k.chunk_text ILIKE '%' || query_text || '%'
    LIMIT match_count
  ),

  -- Busca fuzzy usando pg_trgm (tolera typos)
  fuzzy_results AS (
    SELECT
      k.id,
      similarity(k.chunk_text, query_text) as score
    FROM 09_rag_knowledge_chunks k
    WHERE k.is_active = true
      AND (filter_source_type IS NULL OR k.source_type = filter_source_type)
      AND similarity(k.chunk_text, query_text) > 0.1
    ORDER BY score DESC
    LIMIT match_count
  ),

  -- Combina todos os resultados com pesos
  combined AS (
    SELECT
      d.id,
      d.chunk_text,
      d.metadata,
      d.hierarchy_path,
      d.section_range,
      d.parent_range,
      COALESCE(d.score, 0) as dense_score,
      COALESCE(s.score, 0) as sparse_score,
      CASE WHEN i.id IS NOT NULL THEN 1.0 ELSE 0 END as ilike_score,
      COALESCE(f.score, 0) as fuzzy_score,
      (
        COALESCE(d.score, 0) * dense_weight +
        COALESCE(s.score, 0) * sparse_weight +
        (CASE WHEN i.id IS NOT NULL THEN 1.0 ELSE 0 END) * ilike_weight +
        COALESCE(f.score, 0) * fuzzy_weight
      ) as combined_score
    FROM dense_results d
    LEFT JOIN sparse_results s ON d.id = s.id
    LEFT JOIN ilike_results i ON d.id = i.id
    LEFT JOIN fuzzy_results f ON d.id = f.id
  )

  SELECT * FROM combined
  ORDER BY combined_score DESC
  LIMIT match_count;
END;
$$;

-- =============================================================================
-- BUSCA SIMPLES (fallback/compatibilidade)
-- =============================================================================

CREATE OR REPLACE FUNCTION search_knowledge_chunks(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.7,
  match_count int DEFAULT 5,
  filter_source_type text DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  source_type text,
  source_id text,
  chunk_text text,
  metadata jsonb,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    k.id,
    k.source_type,
    k.source_id,
    k.chunk_text,
    k.metadata,
    1 - (k.embedding <=> query_embedding) as similarity
  FROM 09_rag_knowledge_chunks k
  WHERE
    k.is_active = true
    AND (filter_source_type IS NULL OR k.source_type = filter_source_type)
    AND 1 - (k.embedding <=> query_embedding) > match_threshold
  ORDER BY k.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Funcao para detectar duplicacao
CREATE OR REPLACE FUNCTION check_duplication(
  query_embedding vector(1536),
  threshold float DEFAULT 0.90
)
RETURNS TABLE (
  is_duplicate boolean,
  similar_post_id text,
  similar_title text,
  similarity_score float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    (1 - (k.embedding <=> query_embedding) > threshold) as is_duplicate,
    k.source_id as similar_post_id,
    k.metadata->>'title' as similar_title,
    1 - (k.embedding <=> query_embedding) as similarity_score
  FROM 09_rag_knowledge_chunks k
  WHERE
    k.is_active = true
    AND k.source_type = 'post'
    AND k.chunk_index = 0  -- Primeiro chunk (titulo/resumo)
  ORDER BY k.embedding <=> query_embedding
  LIMIT 1;
END;
$$;

-- Funcao para obter contexto de precos recentes
CREATE OR REPLACE FUNCTION get_price_context(
  days_back int DEFAULT 7
)
RETURNS TABLE (
  symbol text,
  latest_price numeric,
  price_change numeric,
  trend text
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH recent_prices AS (
    SELECT
      p.symbol,
      p.price,
      p.chg_percent,
      p.assessed_date,
      ROW_NUMBER() OVER (PARTITION BY p.symbol ORDER BY p.assessed_date DESC) as rn
    FROM 07_mkt_iron_ore_prices p
    WHERE p.assessed_date >= CURRENT_DATE - days_back
  )
  SELECT
    rp.symbol,
    rp.price as latest_price,
    rp.chg_percent as price_change,
    CASE
      WHEN rp.chg_percent > 0 THEN 'UP'
      WHEN rp.chg_percent < 0 THEN 'DOWN'
      ELSE 'STABLE'
    END as trend
  FROM recent_prices rp
  WHERE rp.rn = 1
  AND rp.symbol IN ('IODEX', 'TSI62', 'PLATTS62')  -- Principais indices
  ORDER BY rp.symbol;
END;
$$;

-- =============================================================================
-- CONTEXT EXPANSION (NOVO v2.0)
-- Expande contexto buscando chunks adjacentes da mesma secao/documento
-- =============================================================================

CREATE OR REPLACE FUNCTION expand_context(
  p_chunk_id bigint,
  p_expansion_type text DEFAULT 'section'  -- 'section' ou 'parent'
)
RETURNS TABLE (
  id bigint,
  chunk_index int,
  chunk_text text,
  hierarchy_path text,
  is_original boolean
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_doc_id text;
  v_range int[];
BEGIN
  -- Busca informacoes do chunk original
  SELECT
    k.metadata->>'doc_id',
    CASE
      WHEN p_expansion_type = 'section' THEN k.section_range
      ELSE k.parent_range
    END
  INTO v_doc_id, v_range
  FROM 09_rag_knowledge_chunks k
  WHERE k.id = p_chunk_id;

  -- Retorna chunks no range especificado
  RETURN QUERY
  SELECT
    k.id,
    k.chunk_index,
    k.chunk_text,
    k.hierarchy_path,
    (k.id = p_chunk_id) as is_original
  FROM 09_rag_knowledge_chunks k
  WHERE k.is_active = true
    AND k.metadata->>'doc_id' = v_doc_id
    AND k.chunk_index >= v_range[1]
    AND k.chunk_index <= v_range[2]
  ORDER BY k.chunk_index;
END;
$$;
```

### 2.6 Tabela de Glossario (Dados Iniciais)

```sql
-- Tabela auxiliar para glossario (facilita manutencao)
CREATE TABLE 09_rag_glossary (
  id serial PRIMARY KEY,
  term text NOT NULL UNIQUE,
  definition text NOT NULL,
  category text DEFAULT 'general',
  aliases text[],  -- Termos alternativos
  created_at timestamptz DEFAULT now()
);

-- Dados iniciais do glossario de minerio de ferro
INSERT INTO 09_rag_glossary (term, definition, category, aliases) VALUES
-- Indices de Preco
('IODEX', 'Iron Ore Index - Indice de referencia da Platts para minerio de ferro 62% Fe CFR China. Publicado diariamente.', 'indices', ARRAY['Platts IODEX', 'IODEX 62%']),
('TSI', 'The Steel Index - Indice de preco de minerio de ferro da S&P Global.', 'indices', ARRAY['TSI 62', 'TSI Iron Ore']),
('MB65', 'Metal Bulletin 65% Fe Index - Indice para minerio de alto teor.', 'indices', ARRAY['Metal Bulletin', 'MB 65%']),

-- Termos de Comercio
('CFR', 'Cost and Freight - Preco inclui custo do minerio e frete ate o porto de destino. Vendedor paga frete.', 'incoterms', ARRAY['C&F']),
('FOB', 'Free On Board - Preco no porto de embarque. Comprador paga frete.', 'incoterms', NULL),
('CIF', 'Cost, Insurance and Freight - CFR mais seguro.', 'incoterms', NULL),

-- Qualidades
('Fines', 'Minerio fino (0-10mm), usado em sinterizacao.', 'quality', ARRAY['Sinter Fines', 'Sinter Feed']),
('Pellet', 'Minerio aglomerado em bolotas para uso direto em alto-fornos.', 'quality', ARRAY['Pellets', 'Pelotas']),
('Lump', 'Minerio em pedacos (6-40mm), pode ir direto ao alto-forno.', 'quality', ARRAY['Lumps', 'Granulado']),

-- Empresas
('Vale', 'Vale S.A. - Maior produtora de minerio de ferro do mundo, sediada no Brasil.', 'companies', ARRAY['VALE3', 'Vale SA']),
('Rio Tinto', 'Rio Tinto Group - Segunda maior mineradora, opera principalmente na Australia.', 'companies', ARRAY['RIO']),
('BHP', 'BHP Group - Terceira maior mineradora, Australia.', 'companies', ARRAY['BHP Billiton']),
('FMG', 'Fortescue Metals Group - Quarta maior, Australia.', 'companies', ARRAY['Fortescue']),

-- Portos
('Qingdao', 'Principal porto de importacao de minerio na China.', 'ports', ARRAY['Qingdao Port']),
('Tubarao', 'Porto da Vale em Vitoria-ES, maior terminal de minerio do mundo.', 'ports', ARRAY['Ponta da Madeira', 'PDM']),
('Port Hedland', 'Principal porto de exportacao da Australia.', 'ports', NULL),

-- Frete Maritimo
('BDI', 'Baltic Dry Index - Indice composto de frete maritimo para graneis secos.', 'freight', ARRAY['Baltic Dry']),
('Capesize', 'Navios > 100.000 DWT, usados para minerio de ferro em longas distancias.', 'freight', ARRAY['Cape']),
('C3', 'Rota Tubarao-Qingdao - Principal rota Brasil-China.', 'freight', ARRAY['Brazil-China']),
('C5', 'Rota West Australia-Qingdao.', 'freight', ARRAY['WA-China']),

-- Producao
('Run of Mine', 'Minerio bruto extraido, antes do beneficiamento.', 'production', ARRAY['ROM']),
('Pellet Feed', 'Minerio ultra-fino usado como materia-prima para pelotizacao.', 'production', NULL),

-- Mercado
('Spot', 'Mercado a vista, entrega imediata.', 'market', ARRAY['Spot Market']),
('Spread', 'Diferenca de preco entre duas referencias (ex: 65%-62%).', 'market', NULL),
('Contango', 'Quando preco futuro > preco spot.', 'market', NULL),
('Backwardation', 'Quando preco spot > preco futuro.', 'market', NULL);

COMMENT ON TABLE 09_rag_glossary IS 'Glossario de termos tecnicos do mercado de minerio de ferro para RAG';
```

---

## 3. Workflows n8n

### 3.1 WF009_rag_indexer (Novo)

**Funcao:** Indexar posts publicados, glossario e guidelines no vector store.

**Trigger:**
- Webhook de WF006a (apos publicacao)
- Schedule diario (reindexar precos)
- Manual (indexacao inicial)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         WF009_rag_indexer                                    │
└─────────────────────────────────────────────────────────────────────────────┘

TRIGGER (Webhook/Schedule/Manual)
    │
    ▼
┌─────────────────┐
│ DETERMINAR TIPO │ ─── post | glossary | guideline | price_context
└─────────────────┘
    │
    ├─── post ──────────────────────────────────────────┐
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ BUSCAR POST     │ ── Supabase: 02_cnt_posts           │
│ COMPLETO        │    JOIN 02_cnt_metadata              │
└─────────────────┘                                      │
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ CHUNKER         │ ── Split em ~500 tokens              │
│                 │    Preservar paragrafos              │
│                 │    Overlap de 50 tokens              │
└─────────────────┘                                      │
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ GERAR EMBEDDINGS│ ── OpenAI text-embedding-3-small    │
│ (Batch)         │    Batch de ate 100 chunks           │
└─────────────────┘                                      │
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ PREPARAR        │ ── Adicionar metadata:               │
│ METADATA        │    title, date, category, tier       │
└─────────────────┘                                      │
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ UPSERT CHUNKS   │ ── Supabase: 09_rag_knowledge_chunks │
│                 │    ON CONFLICT UPDATE                │
└─────────────────┘                                      │
    │                                                    │
    ▼                                                    │
┌─────────────────┐                                      │
│ LOG INDEXACAO   │ ── Registrar sucesso/erro            │
└─────────────────┘                                      │
```

**Nodes Detalhados:**

| Node | Tipo | Funcao |
|------|------|--------|
| TRIGGER | Webhook/Schedule | Recebe post_id ou tipo |
| DETERMINAR TIPO | Switch | Roteia por source_type |
| BUSCAR POST | Supabase | SELECT com JOIN |
| CHUNKER | Code | Split inteligente |
| GERAR EMBEDDINGS | HTTP Request | OpenAI API |
| PREPARAR METADATA | Set | Estrutura metadata JSON |
| UPSERT CHUNKS | Supabase | Insert/Update |
| LOG INDEXACAO | Supabase | 08_sys_errors se falhar |

### 3.2 WF002_content_ai_generator (Modificado)

**Modificacao:** Adicionar RAG antes da geracao de artigo.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WF002_content_ai_generator (com RAG)                      │
└─────────────────────────────────────────────────────────────────────────────┘

TRIGGER (de WF001)
    │
    ▼
┌─────────────────┐
│ BUSCAR NOTICIA  │ ── 01_ing_market_intelligence
└─────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NOVO: BLOCO RAG                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────┐                                                       │
│   │ QUERY CLASSIFIER│ ─── Precisa de contexto historico?                    │
│   │                 │     Output: { needs_rag: bool, query_type: string }   │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ├─── needs_rag = false ──▶ Pula para AI ARCHIVER                     │
│        │                                                                     │
│        ▼ needs_rag = true                                                   │
│   ┌─────────────────┐                                                       │
│   │ GERAR EMBEDDING │ ── OpenAI: embed(titulo + resumo)                     │
│   │ DA NOTICIA      │                                                       │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ▼                                                                     │
│   ┌─────────────────┐                                                       │
│   │ CHECK DUPLICATE │ ── Supabase: check_duplication()                      │
│   │                 │    Se similarity > 90% → BLOQUEAR                     │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ├─── is_duplicate = true ──▶ NOTIFICAR + PARAR                       │
│        │                                                                     │
│        ▼ is_duplicate = false                                               │
│   ┌─────────────────┐                                                       │
│   │ VECTOR SEARCH   │ ── Supabase: search_knowledge_chunks()                │
│   │ (Posts)         │    Top 5 posts similares                              │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ▼                                                                     │
│   ┌─────────────────┐                                                       │
│   │ BUSCAR GLOSSARIO│ ── Termos relevantes da noticia                       │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ▼                                                                     │
│   ┌─────────────────┐                                                       │
│   │ BUSCAR PRECOS   │ ── get_price_context(7)                               │
│   │ RECENTES        │    Ultimos 7 dias                                     │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ▼                                                                     │
│   ┌─────────────────┐                                                       │
│   │ MONTAR CONTEXTO │ ── Concatenar: posts + glossario + precos             │
│   │ RAG             │                                                       │
│   └─────────────────┘                                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────┐
│ AI ARCHIVER     │ ── MODIFICADO: Recebe contexto RAG
│ (Research Agent)│    System prompt inclui contexto
└─────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         NOVO: VERIFICACAO                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌─────────────────┐                                                       │
│   │ VERIFY GROUNDING│ ── O artigo esta baseado nas fontes?                  │
│   │                 │    Output: { is_grounded: bool, score: float }        │
│   └─────────────────┘                                                       │
│        │                                                                     │
│        ├─── score < 0.7 ──▶ REGENERAR com feedback                          │
│        │                                                                     │
│        ▼ score >= 0.7                                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────┐
│ PROCESSAR OUTPUT│ ── Continua fluxo normal
└─────────────────┘
    │
    ▼
INSERT Supabase → WF003 (preview)
```

---

## 4. Prompts dos Agents

### 4.1 Query Classifier Prompt

```markdown
## System Message

Voce e um classificador de queries para um sistema de blog sobre minerio de ferro.

Sua tarefa: Determinar se a noticia precisa de contexto historico (RAG) para ser bem escrita.

## Criterios para RAG = TRUE:
1. Menciona variacao de precos (precisa contexto de tendencia)
2. Menciona empresa especifica (precisa historico da empresa)
3. Menciona comparacao com periodo anterior
4. Menciona previsao ou expectativa de mercado
5. Topico complexo que beneficia de contexto

## Criterios para RAG = FALSE:
1. Breaking news simples (anuncio, evento)
2. Dados pontuais sem necessidade de contexto
3. Noticia auto-contida

## Output Format (JSON puro):
{
  "needs_rag": true,
  "query_type": "price_analysis|company_news|market_trend|breaking_news",
  "reasoning": "breve explicacao"
}
```

### 4.2 Research Agent com SOP (ATUALIZADO v2.0)

```markdown
# Role

Voce e o editor-chefe do Minerals Trading Daily, um blog especializado em minerio de ferro e commodities.

# Goal

Criar artigos de alta qualidade baseados EXCLUSIVAMENTE nas informacoes recuperadas pelas tools disponiveis. Voce NUNCA inventa dados.

# Standard Operating Procedure (SOP)

Siga estes passos na ordem:

## Passo 1: Verificar Duplicacao
- Use a tool "Duplicate Checker" com o titulo/resumo da noticia
- Se similaridade > 90%: PARE e reporte duplicacao
- Se similaridade 80-90%: Continue mas diferencie do post existente

## Passo 2: Buscar Contexto Historico
- Use "Hybrid Search" com query baseada no tema principal
- Analise os chunks retornados
- Se precisar mais contexto, use "Context Expansion" nos chunks mais relevantes

## Passo 3: Buscar Dados de Mercado
- Use "Price Search" para dados de precos IODEX/TSI (ultimos 7 dias)
- Use "Baltic Search" para indices de frete se relevante
- SEMPRE cite numeros exatos das fontes

## Passo 4: Verificar Terminologia
- Use "Glossary Search" para termos tecnicos mencionados
- Use EXATAMENTE a terminologia do glossario

## Passo 5: Gerar Artigo
- Estruture com: Titulo, Resumo, Corpo, Contexto
- Inclua dados numericos especificos
- Mantenha tom profissional e analitico
- Cite tendencias quando tiver dados historicos

## Passo 6: Auto-Verificacao
Antes de finalizar, verifique:
- [ ] Todos os numeros vem das fontes?
- [ ] Terminologia esta correta?
- [ ] Nao contradiz posts anteriores?
- [ ] Artigo e auto-suficiente (leitor entende sem contexto externo)?

# Response Format

{
  "title": "Titulo em portugues, max 70 chars, com dado especifico",
  "slug": "titulo-em-slug-format",
  "excerpt": "Resumo de 2-3 frases, max 160 chars",
  "content_html": "<p>Artigo completo em HTML semantico...</p>",
  "sources_used": ["chunk_id_1", "chunk_id_2"],
  "price_data_used": true,
  "grounding_confidence": 0.95
}

# Response Rules

- Responda SEMPRE em portugues brasileiro
- Use markdown dentro do content_html
- Maximo 800 palavras no artigo
- Inclua pelo menos 2 dados numericos especificos
- Se nao tiver informacao suficiente, diga explicitamente
```

### 4.3 Verify Grounding Prompt

```markdown
## System Message

Voce e um verificador de qualidade para artigos de blog.

Sua tarefa: Verificar se o artigo gerado esta "grounded" (baseado) nas fontes fornecidas.

## Entrada

### Artigo Gerado:
{{ $json.generated_article }}

### Fontes Utilizadas:
{{ $json.rag_context }}

### Noticia Original:
{{ $json.original_news }}

## Verificar:

1. **Fatos Numericos**: Todos os numeros do artigo estao nas fontes?
2. **Afirmacoes**: Todas as afirmacoes podem ser tracadas para uma fonte?
3. **Contradicoes**: O artigo contradiz alguma fonte?
4. **Terminologia**: Os termos usados estao corretos conforme glossario?

## Output Format (JSON puro):
{
  "is_fully_grounded": true,
  "score": 0.92,
  "unsupported_claims": [
    "Afirmacao X nao tem suporte nas fontes"
  ],
  "contradictions": [
    "Artigo diz Y, mas fonte diz Z"
  ],
  "terminology_issues": [
    "Usou 'iron ore' em vez de 'minerio de ferro'"
  ],
  "verification_summary": "Artigo bem fundamentado, apenas 1 termo incorreto"
}
```

### 4.4 Duplication Alert Prompt

```markdown
## System Message

Voce detectou uma possivel duplicacao de conteudo.

## Noticia Nova:
Titulo: {{ $json.new_title }}
Resumo: {{ $json.new_summary }}

## Post Similar Existente:
Titulo: {{ $json.similar_title }}
Data: {{ $json.similar_date }}
Similaridade: {{ $json.similarity_score }}%

## Decisao Necessaria:
- Se similaridade > 95%: Provavelmente duplicata exata, BLOQUEAR
- Se similaridade 90-95%: Verificar se e atualizacao ou duplicata
- Se similaridade 85-90%: Provavelmente relacionado mas diferente, PERMITIR com aviso

## Output:
{
  "action": "BLOCK|WARN|ALLOW",
  "reason": "explicacao",
  "suggestion": "Se WARN, sugerir como diferenciar"
}
```

---

## 5. Codigo JavaScript para n8n

### 5.1 Smart Chunker com Hierarquia (Code Node) - ATUALIZADO v2.0

```javascript
// Smart Markdown Chunker - Respeita hierarquia do documento
// Adaptado do TheAIAutomators SOTA Blueprint

const CONFIG = {
  MIN_CHUNK_SIZE: 400,       // Minimo de caracteres
  TARGET_CHUNK_SIZE: 600,    // Tamanho alvo
  MAX_CHUNK_SIZE: 800,       // Maximo antes de forcar split
  MAX_HEADING_LENGTH: 200,   // Truncar headings longos
  CHARS_PER_TOKEN: 4         // Aproximacao para portugues
};

class HierarchyNode {
  constructor(title, level) {
    this.title = title;
    this.level = level;
  }
}

class SmartMarkdownChunker {
  constructor(config) {
    this.config = config;
    this.chunks = [];
    this.hierarchyStack = [];
  }

  // Detecta heading e retorna nivel (1-6) ou null
  detectHeading(line) {
    const match = line.match(/^(#{1,6})\s+(.+)$/);
    if (match) {
      return {
        level: match[1].length,
        title: match[2].trim().substring(0, this.config.MAX_HEADING_LENGTH)
      };
    }
    return null;
  }

  // Atualiza stack de hierarquia
  updateHierarchy(level, title) {
    while (this.hierarchyStack.length > 0 &&
           this.hierarchyStack[this.hierarchyStack.length - 1].level >= level) {
      this.hierarchyStack.pop();
    }
    this.hierarchyStack.push(new HierarchyNode(title, level));
  }

  // Gera path da hierarquia atual
  getHierarchyPath() {
    return this.hierarchyStack.map(n => n.title).join(' > ');
  }

  // Estima tokens de um texto
  estimateTokens(text) {
    return Math.ceil(text.length / this.config.CHARS_PER_TOKEN);
  }

  // Processa documento completo
  chunk(markdown, metadata = {}) {
    const lines = markdown.split('\n');
    let currentChunk = {
      content: '',
      tokens: 0,
      headings: []
    };

    this.chunks = [];
    this.hierarchyStack = [];
    let chunkIndex = 0;

    const saveChunk = () => {
      if (currentChunk.content.trim()) {
        this.chunks.push({
          chunk_index: chunkIndex++,
          chunk_text: currentChunk.content.trim(),
          chunk_tokens: currentChunk.tokens,
          hierarchy_path: this.getHierarchyPath(),
          headings_in_chunk: currentChunk.headings,
          metadata: {
            ...metadata,
            hierarchy_stack: JSON.parse(JSON.stringify(this.hierarchyStack)),
            chunk_position: this.chunks.length === 0 ? 'start' : 'middle'
          }
        });
      }
      currentChunk = { content: '', tokens: 0, headings: [] };
    };

    for (const line of lines) {
      const heading = this.detectHeading(line);
      const lineTokens = this.estimateTokens(line);

      if (heading) {
        // Se chunk atual esta grande o suficiente, salva antes do novo heading
        if (currentChunk.tokens >= this.config.TARGET_CHUNK_SIZE) {
          saveChunk();
        }

        this.updateHierarchy(heading.level, heading.title);
        currentChunk.headings.push({
          level: heading.level,
          title: heading.title,
          path: this.getHierarchyPath()
        });
      }

      // Adiciona linha ao chunk
      currentChunk.content += (currentChunk.content ? '\n' : '') + line;
      currentChunk.tokens += lineTokens;

      // Se excedeu MAX, forca split
      if (currentChunk.tokens >= this.config.MAX_CHUNK_SIZE) {
        saveChunk();
      }
    }

    // Salva ultimo chunk
    saveChunk();

    // Marca ultimo como 'end'
    if (this.chunks.length > 0) {
      this.chunks[this.chunks.length - 1].metadata.chunk_position = 'end';
    }

    // Adiciona section_range e parent_range
    this.addRanges();

    return this.chunks;
  }

  // Adiciona ranges para context expansion
  addRanges() {
    const totalChunks = this.chunks.length;

    for (let i = 0; i < totalChunks; i++) {
      const chunk = this.chunks[i];
      const currentPath = chunk.hierarchy_path;

      // Section range: chunks com path relacionado
      let sectionStart = i;
      let sectionEnd = i;
      const rootSection = currentPath.split(' > ')[0];

      // Busca inicio da secao
      for (let j = i - 1; j >= 0; j--) {
        if (this.chunks[j].hierarchy_path.startsWith(rootSection)) {
          sectionStart = j;
        } else {
          break;
        }
      }

      // Busca fim da secao
      for (let j = i + 1; j < totalChunks; j++) {
        if (this.chunks[j].hierarchy_path.startsWith(rootSection)) {
          sectionEnd = j;
        } else {
          break;
        }
      }

      chunk.section_range = [sectionStart, sectionEnd];
      chunk.parent_range = [0, totalChunks - 1];  // Documento inteiro
    }
  }
}

// === USO NO N8N ===
const post = $input.first().json;

// Remove HTML e limpa texto
const cleanText = (post.content_html || post.content || '')
  .replace(/<[^>]+>/g, '')
  .replace(/&nbsp;/g, ' ')
  .replace(/&amp;/g, '&')
  .replace(/&lt;/g, '<')
  .replace(/&gt;/g, '>')
  .trim();

const metadata = {
  doc_id: post.id,
  doc_name: post.title,
  source_type: 'post',
  tier: post.tier,
  created_at: post.created_at
};

const chunker = new SmartMarkdownChunker(CONFIG);
const chunks = chunker.chunk(cleanText, metadata);

return chunks.map(chunk => ({ json: chunk }));
```

### 5.2 Reciprocal Rank Fusion (Code Node)

```javascript
// Reciprocal Rank Fusion - Combina rankings de multiplas buscas

const K = 60;  // Constante RRF padrao

// Funcao de hash simples para deduplicacao
function hashString(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash.toString(16);
}

// Agrupar por fonte (cada busca e uma fonte)
const items = $input.all();
const rankingsBySource = {};

items.forEach((item, globalIndex) => {
  const sourceIndex = item.json.search_source || 0;
  if (!rankingsBySource[sourceIndex]) {
    rankingsBySource[sourceIndex] = [];
  }
  rankingsBySource[sourceIndex].push({
    ...item.json,
    globalIndex
  });
});

// Calcular scores RRF com deduplicacao
const rrfScores = {};

Object.values(rankingsBySource).forEach(rankedItems => {
  rankedItems.forEach((item, rank) => {
    const chunkHash = hashString(item.chunk_text);
    const rrfContribution = 1 / (K + rank + 1);

    if (!rrfScores[chunkHash]) {
      rrfScores[chunkHash] = {
        score: 0,
        item: item,
        sources: []
      };
    }

    rrfScores[chunkHash].score += rrfContribution;
    rrfScores[chunkHash].sources.push(rank + 1);
  });
});

// Ordenar por score RRF e retornar top N
const sorted = Object.values(rrfScores)
  .sort((a, b) => b.score - a.score)
  .slice(0, 10);  // Top 10

return sorted.map(result => ({
  json: {
    chunk_text: result.item.chunk_text,
    metadata: result.item.metadata,
    rrf_score: result.score,
    appeared_in_ranks: result.sources
  }
}));
```

### 5.3 Context Builder (Code Node)

```javascript
// Context Builder - Monta contexto RAG para o prompt

const similarPosts = $('VECTOR SEARCH').all();
const glossary = $('BUSCAR GLOSSARIO').all();
const prices = $('BUSCAR PRECOS').all();

// Formatar posts similares
const postsContext = similarPosts.map((item, i) => {
  const p = item.json;
  return `### Post ${i + 1} (Similaridade: ${(p.similarity * 100).toFixed(1)}%)
Titulo: ${p.metadata?.title || 'N/A'}
Data: ${p.metadata?.date || 'N/A'}
Conteudo: ${p.chunk_text.substring(0, 500)}...`;
}).join('\n\n');

// Formatar glossario
const glossaryContext = glossary.map(item => {
  const g = item.json;
  return `- **${g.term}**: ${g.definition}`;
}).join('\n');

// Formatar precos
const pricesContext = prices.map(item => {
  const p = item.json;
  const arrow = p.trend === 'UP' ? '↑' : p.trend === 'DOWN' ? '↓' : '→';
  return `- ${p.symbol}: $${p.latest_price} (${arrow} ${p.price_change}%)`;
}).join('\n');

// Montar contexto completo
const ragContext = `
## CONTEXTO RAG

### Posts Anteriores Relevantes
${postsContext || 'Nenhum post similar encontrado.'}

### Glossario de Termos
${glossaryContext || 'Nenhum termo relevante.'}

### Precos Recentes (Ultimos 7 dias)
${pricesContext || 'Dados de precos nao disponiveis.'}
`;

return [{
  json: {
    rag_context: ragContext,
    similar_posts: similarPosts.map(p => p.json),
    glossary: glossary.map(g => g.json),
    prices: prices.map(p => p.json),
    context_tokens: Math.ceil(ragContext.length / 4)
  }
}];
```

### 5.4 Grounding Score Calculator (Code Node)

```javascript
// Grounding Score Calculator - Calcula score de verificacao

const verification = $input.first().json;

// Pesos para cada tipo de problema
const WEIGHTS = {
  unsupported_claim: 0.15,    // -15% por afirmacao sem suporte
  contradiction: 0.25,        // -25% por contradicao
  terminology_issue: 0.05     // -5% por problema de terminologia
};

// Calcular penalidades
let score = 1.0;

const unsupportedCount = verification.unsupported_claims?.length || 0;
const contradictionCount = verification.contradictions?.length || 0;
const terminologyCount = verification.terminology_issues?.length || 0;

score -= unsupportedCount * WEIGHTS.unsupported_claim;
score -= contradictionCount * WEIGHTS.contradiction;
score -= terminologyCount * WEIGHTS.terminology_issue;

// Garantir score entre 0 e 1
score = Math.max(0, Math.min(1, score));

// Determinar acao
let action = 'APPROVE';
let feedback = null;

if (score < 0.5) {
  action = 'REJECT';
  feedback = 'Artigo tem problemas serios de fundamentacao. Reescrever completamente.';
} else if (score < 0.7) {
  action = 'REVISE';
  feedback = `Corrigir: ${verification.unsupported_claims?.join('; ') || ''} ${verification.contradictions?.join('; ') || ''}`;
} else if (score < 0.85) {
  action = 'MINOR_FIXES';
  feedback = `Ajustes menores: ${verification.terminology_issues?.join('; ') || 'revisar terminologia'}`;
}

return [{
  json: {
    grounding_score: score,
    action: action,
    feedback: feedback,
    details: {
      unsupported_claims: unsupportedCount,
      contradictions: contradictionCount,
      terminology_issues: terminologyCount
    },
    is_acceptable: score >= 0.7
  }
}];
```

---

## 6. Integracao com Workflows Existentes

### 6.1 Mudancas em WF006a (Image Approval Publish)

Adicionar chamada ao WF009 apos publicacao bem-sucedida:

```
PUBLICAR NO WORDPRESS
        │
        ▼ (sucesso)
┌─────────────────┐
│ CHAMAR WF009    │ ── Webhook para indexar o novo post
│ RAG INDEXER     │    Body: { "type": "post", "post_id": "..." }
└─────────────────┘
```

### 6.2 Trigger de Reindexacao

Adicionar schedule no WF009 para:
- **Diario 6h:** Reindexar contexto de precos (ultimos 7 dias)
- **Semanal Domingo:** Verificar integridade dos chunks

---

## 7. Metricas e Monitoramento

### 7.1 Metricas a Rastrear

| Metrica | Descricao | Meta |
|---------|-----------|------|
| `rag_duplicates_blocked` | Duplicatas detectadas e bloqueadas | >0 (funcionando) |
| `rag_grounding_score_avg` | Media do score de grounding | >0.85 |
| `rag_retrieval_latency_ms` | Tempo de busca vetorial | <100ms |
| `rag_chunks_indexed` | Total de chunks no vector store | Crescendo |
| `rag_query_classification_accuracy` | % de classificacoes corretas | >90% |

### 7.2 Alertas

| Alerta | Condicao | Acao |
|--------|----------|------|
| Grounding baixo | score_avg < 0.7 por 3 artigos | Revisar prompts |
| Muitas duplicatas | >3 duplicatas/dia | Verificar fontes RSS |
| Latencia alta | >500ms consistente | Verificar indice |
| Falha indexacao | Erro em WF009 | Notificar Telegram |

---

## 8. Custos Estimados

### 8.1 OpenAI Embeddings

| Item | Calculo | Custo |
|------|---------|-------|
| Indexacao inicial | 65 posts × 3 chunks × 500 tokens = 97,500 tokens | $0.002 |
| Por artigo novo | 1 post × 3 chunks × 500 tokens = 1,500 tokens | $0.00003 |
| Query (busca) | 1 × 200 tokens | $0.000004 |
| **Mensal (30 artigos)** | 30 × indexacao + 30 × query | **~$0.01** |

### 8.2 Supabase

| Item | Custo |
|------|-------|
| pgvector storage | Incluido no plano |
| Queries adicionais | Incluido no plano |
| **Total adicional** | **$0** |

### 8.3 Reranking (Opcional)

| Item | Custo |
|------|-------|
| Cohere Rerank | $1/1000 queries |
| **Mensal (30 artigos)** | **~$0.03** |

### Total Mensal Estimado: **~$5-10** (com margem de seguranca)

---

## 9. Plano de Implementacao

### Fase 1: Schema (1-2 horas)
- [ ] Habilitar pgvector no Supabase
- [ ] Criar tabela 09_rag_knowledge_chunks
- [ ] Criar indices
- [ ] Criar funcoes SQL
- [ ] Popular glossario inicial

### Fase 2: WF009 Indexer (3-4 horas)
- [ ] Criar workflow WF009_rag_indexer
- [ ] Implementar chunker
- [ ] Integrar OpenAI embeddings
- [ ] Testar indexacao de 1 post
- [ ] Indexar todos os 65 posts existentes

### Fase 3: WF002 com RAG (4-5 horas)
- [ ] Adicionar bloco RAG ao WF002
- [ ] Implementar query classifier
- [ ] Implementar duplication check
- [ ] Implementar vector search
- [ ] Atualizar prompt do AI Archiver
- [ ] Implementar verify grounding
- [ ] Testar fluxo completo

### Fase 4: Integracao (1-2 horas)
- [ ] Conectar WF006a ao WF009
- [ ] Configurar schedule de reindexacao
- [ ] Adicionar metricas
- [ ] Configurar alertas

### Total Estimado: **10-13 horas**

---

## 10. Referencias

### Documentacao
- [Supabase pgvector](https://supabase.com/docs/guides/ai/vector-columns)
- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings)
- [n8n Vector Store Node](https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.vectorstoresupabase/)
- [Cohere Rerank API](https://docs.cohere.com/reference/rerank)

### Padroes RAG
- TheAIAutomators RAG Blueprint (arquivo local)
- [RAG Fusion Paper](https://arxiv.org/abs/2402.03367)
- [Reciprocal Rank Fusion](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)

---

## Historico

| Data | Versao | Autor | Mudanca |
|------|--------|-------|---------|
| 2026-01-05 | 1.0 | Claude Code | Documento inicial |
| 2026-01-05 | 2.0 | Claude Code | Integrado melhorias SOTA: Smart Chunker, Hybrid Search, Record Manager, Context Expansion, Agent SOP |

---

## Anexo: Comparacao Original vs Melhorado

| Aspecto | v1.0 Original | v2.0 Melhorado |
|---------|---------------|----------------|
| Chunking | Split por tokens simples | Smart Chunker com hierarquia de documento |
| Busca | Apenas vetorial (1 metodo) | Hybrid Search (4 metodos: dense, sparse, ilike, fuzzy) |
| Contexto | Chunk isolado | Context Expansion via ranges (section/parent) |
| Versionamento | Hash simples | Record Manager com status e estatisticas |
| Agent Prompt | Prompt basico | SOP estruturado com 6 passos |
| Reranking | Nenhum | Cohere opcional |
| Arquitetura | Inline | Sub-workflows reutilizaveis |

---

*Documento gerado com base na analise do RAG Blueprint TheAIAutomators v2.3.x e requisitos do projeto Minerals Trading Daily.*

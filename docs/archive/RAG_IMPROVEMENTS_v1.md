# RAG Improvements - Baseado em SOTA Blueprints

**Data:** 2026-01-05
**Versao:** 1.0
**Fonte:** TheAIAutomators SOTA RAG Blueprints v2.3.x
**Status:** Planejado

---

## Sumario Executivo

Apos analise profunda dos 4 blueprints SOTA RAG, identificamos **8 melhorias significativas** para nosso sistema RAG. Este documento detalha cada melhoria com codigo pronto para implementacao.

### Melhorias Identificadas

| # | Melhoria | Impacto | Esforco | Prioridade |
|---|----------|---------|---------|------------|
| 1 | Smart Chunker com Hierarquia | Alto | 3h | P0 |
| 2 | Document Hierarchy + Ranges | Alto | 2h | P0 |
| 3 | Dynamic Hybrid Search | Alto | 4h | P0 |
| 4 | Record Manager | Medio | 2h | P1 |
| 5 | Context Expansion | Alto | 2h | P1 |
| 6 | Agent SOP Structure | Alto | 1h | P0 |
| 7 | Cohere Reranking | Medio | 1h | P2 |
| 8 | Tools como Sub-Workflows | Medio | 3h | P1 |

---

## 1. Smart Chunker com Hierarquia

### Problema Original
Nosso chunker proposto era simples - split por tokens sem respeitar estrutura do documento.

### Solucao SOTA
Chunker que respeita hierarquia Markdown e mantém contexto.

### Codigo

```javascript
// Smart Markdown Chunker - Adaptado do SOTA Blueprint
// Para n8n Code Node

const CONFIG = {
  MIN_CHUNK_SIZE: 400,
  TARGET_CHUNK_SIZE: 600,
  MAX_CHUNK_SIZE: 800,
  MAX_HEADING_LENGTH: 200,
  CHARS_PER_TOKEN: 4  // Aproximacao para portugues
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

  // Detecta heading e retorna nivel (1-6) ou 0 se nao for heading
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
    // Remove niveis >= ao atual
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
      startHeading: null,
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
      currentChunk = { content: '', tokens: 0, startHeading: null, headings: [] };
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

      // Section range: chunks com mesmo path ou path filho
      let sectionStart = i;
      let sectionEnd = i;

      // Busca inicio da secao
      for (let j = i - 1; j >= 0; j--) {
        if (this.chunks[j].hierarchy_path.startsWith(currentPath.split(' > ')[0])) {
          sectionStart = j;
        } else {
          break;
        }
      }

      // Busca fim da secao
      for (let j = i + 1; j < totalChunks; j++) {
        if (this.chunks[j].hierarchy_path.startsWith(currentPath.split(' > ')[0])) {
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
const cleanText = post.content_html
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

---

## 2. Document Hierarchy + Ranges

### Schema Atualizado

```sql
-- Adicionar colunas ao schema proposto
ALTER TABLE 09_rag_knowledge_chunks ADD COLUMN IF NOT EXISTS
  hierarchy_path text;

ALTER TABLE 09_rag_knowledge_chunks ADD COLUMN IF NOT EXISTS
  section_range int[];  -- [start_index, end_index]

ALTER TABLE 09_rag_knowledge_chunks ADD COLUMN IF NOT EXISTS
  parent_range int[];   -- [start_index, end_index]

ALTER TABLE 09_rag_knowledge_chunks ADD COLUMN IF NOT EXISTS
  headings_in_chunk jsonb DEFAULT '[]';

-- Indice para busca por hierarquia
CREATE INDEX idx_rag_chunks_hierarchy
  ON 09_rag_knowledge_chunks (hierarchy_path)
  WHERE is_active = true;

-- Comentarios
COMMENT ON COLUMN 09_rag_knowledge_chunks.hierarchy_path IS
  'Caminho hierarquico do chunk, ex: "Mercado > Precos > IODEX"';
COMMENT ON COLUMN 09_rag_knowledge_chunks.section_range IS
  'Range de chunks na mesma secao [inicio, fim]';
COMMENT ON COLUMN 09_rag_knowledge_chunks.parent_range IS
  'Range de chunks no documento pai [inicio, fim]';
```

---

## 3. Dynamic Hybrid Search

### Supabase Edge Function

```sql
-- Funcao de busca hibrida com pesos configuraveis
CREATE OR REPLACE FUNCTION hybrid_search(
  query_text text,
  query_embedding vector(1536),
  match_count int DEFAULT 30,
  dense_weight float DEFAULT 0.7,
  sparse_weight float DEFAULT 0.2,
  ilike_weight float DEFAULT 0.05,
  fuzzy_weight float DEFAULT 0.05,
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
  -- Prepara query para full-text search
  ts_query := plainto_tsquery('portuguese', query_text);

  RETURN QUERY
  WITH
  -- Busca vetorial (densa)
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

  -- Busca ILIKE (exata)
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

  -- Busca fuzzy usando pg_trgm
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

  -- Combina resultados
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

-- Habilitar extensao pg_trgm para fuzzy search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Indice para fuzzy search
CREATE INDEX idx_rag_chunks_trgm
  ON 09_rag_knowledge_chunks
  USING gin (chunk_text gin_trgm_ops);

-- Indice para full-text search
CREATE INDEX idx_rag_chunks_fts
  ON 09_rag_knowledge_chunks
  USING gin (to_tsvector('portuguese', chunk_text));
```

---

## 4. Record Manager

### Schema

```sql
-- Tabela de controle de documentos indexados
CREATE TABLE 09_rag_record_manager (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identificacao
  doc_id text UNIQUE NOT NULL,
  doc_name text NOT NULL,
  source_type text NOT NULL,

  -- Controle de versao
  content_hash text NOT NULL,
  version int DEFAULT 1,

  -- Estatisticas
  chunk_count int DEFAULT 0,
  total_tokens int DEFAULT 0,

  -- Status
  status text DEFAULT 'pending' CHECK (status IN (
    'pending',      -- Aguardando processamento
    'processing',   -- Em processamento
    'complete',     -- Indexado com sucesso
    'error',        -- Erro na indexacao
    'outdated'      -- Nova versao disponivel
  )),
  error_message text,

  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  indexed_at timestamptz,

  -- Metadata adicional
  metadata jsonb DEFAULT '{}'
);

-- Indice para busca por status
CREATE INDEX idx_record_manager_status
  ON 09_rag_record_manager (status, source_type);

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
```

### Codigo para Verificar Update

```javascript
// Code Node: Verificar se documento precisa reindexar
const crypto = require('crypto');

const post = $input.first().json;
const content = post.content_html || post.content;

// Gera hash do conteudo
const contentHash = crypto
  .createHash('sha256')
  .update(content)
  .digest('hex');

// Busca no record manager (via node Supabase anterior)
const existingRecord = $('Check Record Manager').first().json;

let action = 'create';  // create, update, skip

if (existingRecord && existingRecord.id) {
  if (existingRecord.content_hash === contentHash) {
    action = 'skip';  // Conteudo identico, nao precisa reindexar
  } else {
    action = 'update';  // Conteudo mudou, precisa reindexar
  }
}

return [{
  json: {
    doc_id: post.id,
    doc_name: post.title,
    content_hash: contentHash,
    action: action,
    current_version: existingRecord?.version || 0,
    record_id: existingRecord?.id || null
  }
}];
```

---

## 5. Context Expansion

### Funcao SQL

```sql
-- Funcao para expandir contexto baseado em ranges
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

  -- Retorna chunks no range
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

### HTTP Tool para Agent

```javascript
// Configuracao do HTTP Request Tool para Context Expansion
// URL: POST para Supabase RPC

const chunkId = $fromAI('chunk_id', 'ID do chunk para expandir contexto');
const expansionType = $fromAI('expansion_type', 'Tipo: section ou parent', 'section');

return {
  method: 'POST',
  url: '{{ $env.SUPABASE_URL }}/rest/v1/rpc/expand_context',
  headers: {
    'apikey': '{{ $env.SUPABASE_ANON_KEY }}',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    p_chunk_id: parseInt(chunkId),
    p_expansion_type: expansionType
  })
};
```

---

## 6. Agent SOP Structure

### System Prompt Atualizado

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

---

## 7. Cohere Reranking (Opcional)

### HTTP Request Node

```javascript
// Configuracao para Cohere Rerank
// Adicionar apos Hybrid Search

const query = $('Hybrid Search').first().json.query;
const documents = $('Hybrid Search').all().map(item => item.json.chunk_text);

return {
  method: 'POST',
  url: 'https://api.cohere.com/v2/rerank',
  headers: {
    'Authorization': 'Bearer {{ $env.COHERE_API_KEY }}',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'rerank-v3.5',
    query: query,
    top_n: 10,
    documents: documents
  })
};
```

### Code Node para Reordenar

```javascript
// Reordena items baseado no resultado do Cohere
const originalItems = $('Hybrid Search').all();
const rerankResults = $input.first().json.results;

const reorderedItems = rerankResults.map(result => {
  const originalItem = originalItems[result.index];
  return {
    json: {
      ...originalItem.json,
      relevance_score: result.relevance_score,
      original_rank: result.index,
      new_rank: rerankResults.indexOf(result)
    }
  };
});

return reorderedItems;
```

---

## 8. Tools como Sub-Workflows

### Estrutura Recomendada

```
WF009_rag_indexer (principal)
    │
    ├── WF009a_rag_chunker (sub-workflow)
    │       Input: { content, metadata }
    │       Output: { chunks[] }
    │
    └── WF009b_rag_embedder (sub-workflow)
            Input: { chunks[] }
            Output: { chunks_with_embeddings[] }

WF002_rag_generator (principal)
    │
    ├── WF002a_rag_retrieval (sub-workflow / tool)
    │       Input: { query, filters }
    │       Output: { chunks[], scores[] }
    │
    ├── WF002b_rag_context_expansion (sub-workflow / tool)
    │       Input: { chunk_id, expansion_type }
    │       Output: { expanded_chunks[] }
    │
    └── WF002c_rag_price_search (sub-workflow / tool)
            Input: { days_back, symbols[] }
            Output: { prices[] }
```

### Vantagens

1. **Reutilizacao:** Mesma tool usada por multiplos agents
2. **Debugging:** Logs separados por sub-workflow
3. **Manutencao:** Atualizar tool nao afeta agent principal
4. **Testabilidade:** Testar tool isoladamente

---

## Plano de Implementacao Atualizado

### Fase 1: Fundacao (4-5 horas)
- [ ] Habilitar pgvector e pg_trgm
- [ ] Criar schema completo (chunks + record_manager)
- [ ] Criar funcoes SQL (hybrid_search, expand_context)
- [ ] Popular glossario inicial

### Fase 2: Ingestion (3-4 horas)
- [ ] Criar WF009_rag_indexer
- [ ] Implementar Smart Chunker
- [ ] Implementar Record Manager
- [ ] Indexar 65 posts existentes

### Fase 3: Retrieval (3-4 horas)
- [ ] Criar WF002a_rag_retrieval (sub-workflow)
- [ ] Testar Hybrid Search
- [ ] Implementar Context Expansion
- [ ] (Opcional) Adicionar Cohere Reranking

### Fase 4: Agent (3-4 horas)
- [ ] Duplicar WF001 → WF001_RAG_dev
- [ ] Configurar AI Agent com tools
- [ ] Implementar system prompt com SOP
- [ ] Testar fluxo completo

### Total: ~14-17 horas

---

## Comparacao: Design Original vs Melhorado

| Aspecto | Original | Melhorado |
|---------|----------|-----------|
| Chunking | Split por tokens | Smart Chunker com hierarquia |
| Busca | Apenas vetorial | Hybrid (4 metodos) |
| Context | Chunk isolado | Expansion via ranges |
| Versionamento | Nenhum | Record Manager |
| Reranking | Nenhum | Cohere opcional |
| Agent | Prompt basico | SOP estruturado |
| Tools | Inline | Sub-workflows |

---

## Referencias

- TheAIAutomators SOTA RAG AGENT v2.3.3
- TheAIAutomators SOTA RAG INGESTION v2.3.2
- TheAIAutomators SOTA RAG RETRIEVAL v2.3.3
- TheAIAutomators Knowledge Graph v1.1

---

## Historico

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 1.0 | Documento inicial baseado em analise SOTA |

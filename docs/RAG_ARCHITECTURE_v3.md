# RAG Architecture v3 - Minerals Trading Daily

**Data:** 2026-01-05
**Versao:** 3.0
**Status:** Aprovado

> Sintese dos documentos de arquitetura: Blueprint-Architecture-Analysis, Deep-Agents-Intelligence-Analysis, ARQUITETURA_AGENTIC_TOOLS_RAG, Agents-Implementation-Specification.

---

## Sumario

1. [Estrategia Dual](#estrategia-dual)
2. [O que ja foi implementado](#o-que-ja-foi-implementado)
3. [Arquitetura Tool-First](#arquitetura-tool-first)
4. [WF002_DEV v3 - Hybrid Workflow](#wf002_dev-v3---hybrid-workflow)
5. [Sub-Workflow Tools](#sub-workflow-tools)
6. [System Prompt](#system-prompt)
7. [Futuro: Agent Premium](#futuro-agent-premium)
8. [Referencias](#referencias)

---

## Estrategia Dual

### O Melhor dos Dois Mundos

```
TIPO DE TASK           | ARQUITETURA    | TEMPO   | CUSTO
-----------------------|----------------|---------|--------
Geracao de artigos     | HYBRID         | 10-20s  | $0.10-0.20
Ingestion/Indexacao    | WORKFLOW PURO  | 20-30s  | $0.001
Analise complexa       | AGENT + TOOLS  | 45-90s  | $0.50-1.00
```

### Divisao de Responsabilidades

| Cenario | Arquitetura | Justificativa |
|---------|-------------|---------------|
| Geracao automatica de artigos (80%) | **Hybrid Workflow** | Task repetitiva, bem-definida, precisa ser rapida e barata |
| Analise profunda on-demand (20%) | **Agent com Tools** | Task complexa, variavel, usuario espera qualidade premium |

### Por que nao usar Agent para tudo?

Do Blueprint-Architecture-Analysis:

- Agent e **40x mais caro** ($0.80 vs $0.02)
- Agent e **imprevisivel** para tasks bem definidas
- Agent pode entrar em **loops infinitos**
- Agent pode **alucinar** mesmo com tools

**Conclusao:** Use Agent apenas para features PREMIUM monetizaveis.

---

## O que ja foi Implementado

### Database (Supabase)

**Tabelas criadas:**
- `09_rag_knowledge_chunks` - Chunks com embeddings (pgvector 1536 dims)
- `09_rag_record_manager` - Controle de versionamento/dedup
- `09_rag_glossary` - 26 termos tecnicos do mercado

**Indices:**
- IVFFlat para busca vetorial
- pg_trgm para fuzzy search
- GIN para full-text search (portugues)
- GIN para metadata JSONB

**Funcoes RPC:**
- `hybrid_search(query, embedding, match_count, weights...)` - Busca hibrida 4 metodos
- `check_duplication(embedding, threshold)` - Detecta conteudo duplicado
- `get_price_context(days_back)` - Retorna precos recentes formatados
- `expand_context(chunk_id, type)` - Expande contexto section/parent

### WF011_rag_indexer

- **ID:** `rrQyiqg2BwQlm49m`
- **Funcao:** Indexa posts publicados no vector store
- **Features:** Smart Chunker com hierarquia, Record Manager para dedup

---

## Arquitetura Tool-First

### Principio Core

Do documento ARQUITETURA_AGENTIC_TOOLS_RAG:

> "Tratar o RAG como MAIS UM TOOL do agente, junto com consulta SQL, busca de precos, busca de noticias, validacoes, etc."

### Vantagens

1. **Menos acoplamento** - Troca o retriever sem reescrever o workflow
2. **Mais previsibilidade** - Tools retornam JSON limpo, workflow decide quando chamar
3. **Mais seguranca** - Cada tool tem schema fixo, limites e auditoria
4. **Testabilidade** - Cada tool pode ser testada isoladamente

---

## WF002_DEV v3 - Hybrid Workflow

### Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WF002_DEV_rag_generator v3                       │
│                    Tipo: HYBRID com SUB-WORKFLOWS                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [TRIGGERS] Manual + Schedule (0 */2 * * 1-5)                       │
│      ↓                                                              │
│  [FETCH] Supabase: noticias (blog_processed=false, limit 5)        │
│      ↓                                                              │
│  [LOOP] Para cada noticia:                                          │
│      │                                                              │
│      ├─[1] EMBED                                                    │
│      │     HTTP Request → OpenAI Embeddings API                     │
│      │     Input: titulo + summary (concatenado)                    │
│      │                                                              │
│      ├─[2] DEDUP (Execute Workflow)                                 │
│      │     Chama: WF_TOOL_check_duplicates                          │
│      │     IF is_duplicate=true → SKIP                              │
│      │                                                              │
│      ├─[3] RAG SEARCH (Execute Workflow)                            │
│      │     Chama: WF_TOOL_retrieve_knowledge                        │
│      │     Output: chunks com contexto relevante                    │
│      │                                                              │
│      ├─[4] PRICE DATA (Execute Workflow)                            │
│      │     Chama: WF_TOOL_get_price_data                            │
│      │     Output: precos formatados                                │
│      │                                                              │
│      ├─[5] GLOSSARY (Execute Workflow)                              │
│      │     Chama: WF_TOOL_get_glossary                              │
│      │     Output: termos tecnicos relevantes                       │
│      │                                                              │
│      ├─[6] BUILD CONTEXT (Code Node)                                │
│      │     Monta Evidence Pack JSON                                 │
│      │                                                              │
│      ├─[7] GENERATE (Anthropic Chat Model)                          │
│      │     NAO usar AI Agent! Usar Chat Model simples.              │
│      │     Output: JSON {title, slug, content_html, sources}        │
│      │                                                              │
│      ├─[8] VALIDATE OUTPUT (Code Node)                              │
│      │     Verifica JSON valido, campos obrigatorios                │
│      │                                                              │
│      ├─[9] SAVE (Supabase)                                          │
│      │     INSERT posts + metadata + workflow                       │
│      │                                                              │
│      └─[10] MARK PROCESSED                                          │
│             UPDATE raw_inputs SET blog_processed=true               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Diferenca vs Implementacao Anterior

| Aspecto | v2 (errado) | v3 (correto) |
|---------|-------------|--------------|
| Dedup | Node inline | Sub-workflow tool |
| Search | Node inline | Sub-workflow tool |
| AI | AI Agent node | Chat Model (simples) |
| Reuso | Zero | Tools reutilizaveis |
| RPCs | Nao usava | Usa hybrid_search, etc |

---

## Sub-Workflow Tools

### WF_TOOL_retrieve_knowledge

```
Input:
  - query: string
  - top_k: number (default 5)
  - filters: { doc_type?, recency_days? }

Processo:
  1. HTTP Request → OpenAI Embeddings (query)
  2. Supabase RPC → hybrid_search(embedding, query, top_k)
  3. Code → Format output

Output:
  {
    chunks: [{ id, text, score, source }],
    total_found: number
  }
```

### WF_TOOL_check_duplicates

```
Input:
  - embedding: number[1536]
  - threshold: number (default 0.90)

Processo:
  1. Supabase RPC → check_duplication(embedding, threshold)

Output:
  {
    is_duplicate: boolean,
    similarity: number,
    similar_doc_id: string | null
  }
```

### WF_TOOL_get_price_data

```
Input:
  - symbols: string[] (default ["iron_ore"])
  - range_days: number (default 7)

Processo:
  1. Supabase RPC → get_price_context(range_days)
  2. Code → Format tabular

Output:
  {
    prices: [{ symbol, price, change, trend }],
    period: string
  }
```

### WF_TOOL_get_glossary

```
Input:
  - terms_query: string

Processo:
  1. Supabase SELECT → glossario WHERE term ILIKE query

Output:
  {
    terms: [{ term, definition, category }]
  }
```

---

## System Prompt

### Para o Anthropic Chat Model (NAO Agent!)

```markdown
### SYSTEM: Minerals Trading Daily — Jornalista RAG

Voce e jornalista senior do Minerals Trading Daily.
Seu trabalho e produzir artigos em portugues brasileiro
com base em evidencias coletadas via ferramentas.

**Objetivo:** gerar conteudo factual, consistente e verificavel,
com dados numericos quando aplicavel.

#### Regras de Ouro
1) Nunca invente fatos, numeros, datas ou fontes.
2) Se nao houver evidencia suficiente, declare explicitamente.
3) Cada paragrafo deve ser suportado por chunk_id ou fonte externa.
4) Use terminologia do glossario fornecido.
5) Maximo 800 palavras.

#### Formato de saida (JSON)
{
  "title": "max 70 chars",
  "slug": "slug-format",
  "excerpt": "max 160 chars",
  "content_html": "<p>...</p>",
  "sources_used": ["chunk_id_1", "https://..."],
  "price_data_used": true,
  "grounding_confidence": 0.85
}
```

---

## Futuro: Agent Premium

### WF_PREMIUM_ANALYSIS (Fase 2)

Para ser implementado DEPOIS que o Hybrid Workflow estiver estavel.

```
Trigger: Chat/API request (usuario pede analise)

ORCHESTRATOR (Claude 3.5 Sonnet):
├─ Analisa complexidade da query
├─ Decide quais agents chamar
└─ Sintetiza resultados

AGENTS ESPECIALIZADOS:
├─ NEWS_AGENT: Busca noticias recentes
├─ FUNDAMENTAL_AGENT: Analisa supply/demand
├─ MACRO_AGENT: Contexto macroeconomico
├─ RISK_AGENT: Identificacao de riscos
└─ HISTORICAL_AGENT: Contexto historico

TOOLS COMPARTILHADAS (REUSO!):
├─ WF_TOOL_retrieve_knowledge
├─ WF_TOOL_get_price_data
├─ WF_TOOL_web_search (Perplexity/Firecrawl)
└─ WF_TOOL_verify_claims

OUTPUT: Analise profunda com cenarios e recomendacoes
CUSTO: $0.50-1.00 per analysis
MONETIZACAO: $199/mes premium
```

### Quando Implementar

- [ ] Hybrid Workflow funcionando e estavel
- [ ] Metricas de qualidade em >85%
- [ ] Demanda de usuarios por analises profundas
- [ ] Modelo de monetizacao definido

---

## Referencias

### Documentos de Arquitetura (docs/)

| Arquivo | Descricao |
|---------|-----------|
| `ARQUITETURA_AGENTIC_TOOLS_RAG_MineralsTradingDaily.md` | Tool-first approach |
| `Deep-Agents-Intelligence-Analysis.md` | Multi-Agent para premium |
| `Agents-Implementation-Specification.md` | Specs tecnicas n8n |

### Arquivos Arquivados (docs/archive/)

| Arquivo | Descricao |
|---------|-----------|
| `RAG_DESIGN_v2.md` | Design original detalhado |
| `RAG_IMPROVEMENTS_v1.md` | Melhorias SOTA |

---

## Historico

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 3.0 | Arquitetura consolidada: Hybrid + Agent Premium |
| 2026-01-05 | 2.0 | Integrado SOTA blueprints (arquivado) |
| 2026-01-05 | 1.0 | Design inicial (arquivado) |

# 📋 N8N IMPLEMENTATION GUIDE - Prático & Flexível

## Para acompanhar: RAG_ARCHITECTURE_v3.md

**Objetivo:** Este é um guia vivo, não um passo a passo rígido. Ele evolui conforme você implementa.

---

## PHASE 0: PRÉ-REQUISITOS (1-2 dias)

### ✅ Conta & Setup
```
1. Criar conta n8n (cloud.n8n.io ou self-hosted)
2. Setup kredensiais:
   - OpenAI (gpt-4o, claude-3.5-sonnet)
   - Supabase (PostgreSQL + pgvector)
   - Redis (para memory)
   - APIs: NewsAPI, Firecrawl, Fred API, etc

3. Criar workspace no Telegram (seu bot vai responder lá)
```

### 📚 Documentação para ter à mão
```
BOOKMARKS:
- docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/
- docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-langchain.chattrigger/
- docs.n8n.io/nodes/nodes-library/nodes-core/n8n-nodes-base.code/
```

---

## PHASE 1: ESTRUTURA BASE (3-4 dias)

### 1.1 - CREATE: Main Orchestrator Workflow

**Nome:** `Minerals-Trading-Agent-Orchestrator` (PROD)

**Primeira versão SIMPLES (não tente tudo de uma vez):**

```
[Chat Trigger] 
    ↓
[Function Node - Input Parser]
    ↓
[AI Agent Node - Orchestrator]
    ↓
[Respond to Chat Node]
```

#### Chat Trigger Setup

```yaml
Node: Chat Trigger (NATIVE)
├─ Mode: "Hosted Chat" (for testing)
├─ Load Previous Session: "From Memory"
├─ Response Mode: "When Last Node Finishes"
├─ Auth: Disabled (for now)
└─ Initial Message: "Olá! Sou seu analista de commodities. O que gostaria de analisar?"
```

**Tip:** Este node é o "portal de entrada". Tudo começa aqui.

#### Function Node - Input Parser

```javascript
// Simples: só passa o input adiante
return {
  query: $json.chatInput,
  user_id: "user_" + Date.now(),
  timestamp: new Date().toISOString(),
  context: {
    commodities: ["nickel", "copper", "iron"],
    depth: "professional"
  }
};
```

#### AI Agent Node - Orchestrator (Claude 3.5 Sonnet)

```yaml
Node: AI Agent (NATIVE)
├─ Model: "Claude 3.5 Sonnet"
├─ Prompt: "Take from previous node automatically"
├─ System Message: |
    Você é um analista experiente em commodities.
    Sua função: entender o query do usuário e responder com análise profunda.
    
    REGRAS:
    1. Responda em português
    2. Sempre cite fontes
    3. Mostre confiança (0-100)
    4. Estruture em ROOT CAUSE → EVIDENCE → RECOMMENDATION
└─ Max Iterations: 10
```

**Importante:** No início, SEM tools. Só o modelo pensando.

#### Respond to Chat Node

```yaml
Node: Respond to Chat
├─ Text: "{{ $json.output }}"
└─ Streaming: OFF (por enquanto)
```

**Resultado:** Workflow básico funciona. O usuário fala, o agent responde (sem tools, sem lookup, só reasoning).

---

### 1.2 - TEST: Valide o básico

```
1. Clique "Chat" no workflow
2. Digite: "Preço do níquel hoje?"
3. Veja a resposta (será genérica, está OK)
4. Continue a conversa (múltiplos turnos)
5. Verifique na aba "Executions"
```

**O que você vai notar:**
- ✅ Respostas chegam
- ❌ Sem dados reais (ok, é esperado)
- ✅ Memória funciona (agent lembra contexto anterior)

---

## PHASE 2: MEMORY + BASIC TOOLS (4-5 dias)

### 2.1 - ADD: Memory Sub-node

**Padrão n8n:** Memory DEVE conectar Chat Trigger + AI Agent

```yaml
Node: Memory (Sub-node)
├─ Type: "Buffer Window Memory" (simplest)
├─ Buffer: 10 messages
├─ Output: Keep messages in window
└─ Key: "conversation:{{ $json.user_id }}"
```

**Wiring:**
```
[Chat Trigger] -memory-> [AI Agent] -memory-> [Respond to Chat]
```

**Na prática:**
- Chat Trigger TEM conector de memória
- Clique no conector, selecione Memory node
- Memory node conecta ao AI Agent também
- AI Agent consegue acessar histórico

### 2.2 - ADD: First Tool - Web Search

**Nativo ou Community?**
```
NATIVO: Prefira sempre!
├─ Tools Agent pode usar: Code, HTTP Request, Call n8n Workflow
├─ Essas 3 são built-in e confiáveis

COMMUNITY: Se nativa não existe
├─ Pesquise: n8n-community-node-[toolname]
├─ Instale: Settings → Community Nodes → Install
├─ Exemplo: n8n-nodes-n8n-request (para chamar APIs)
```

**Para seu caso:** Use HTTP Request nativo para web search

```yaml
Node: HTTP Request (Web Search)
├─ Method: POST
├─ URL: https://api.newapi.io/search
├─ Headers:
│   ├─ Authorization: "Bearer {{ $env.NEWSAPI_KEY }}"
│   └─ Content-Type: application/json
├─ Body:
│   ├─ query: "{{ $json.query }}"
│   ├─ sortBy: "publishedAt"
│   └─ language: "pt"
└─ Response Format: JSON
```

**Como conectar ao Agent:**

Na n8n, Tools Agent tem conector de tools. Você arrasta HTTP Request para esse conector.

```yaml
AI Agent Node:
├─ Tem conector "Tools"
├─ Arraste HTTP Request pra lá
├─ Agent vê HTTP Request como "ferramenta disponível"
└─ Agent decide usar quando faz sentido
```

**System prompt ajustado:**

```
Você é um analista de commodities com acesso a ferramentas.

Ferramentas disponíveis:
- web_search: Busca notícias recentes sobre o assunto

PROCESSO:
1. Entenda o query
2. Se precisa de dados atuais: use web_search
3. Analise o resultado
4. Responda com evidência e confiança

Sempre cite a fonte das notícias!
```

---

## PHASE 3: MULTI-AGENT STRUCTURE (5-7 dias)

### 3.1 - NOVO PATTERN: Sub-workflows como Agents

**Ideia:** Em vez de tudo em 1 workflow gigante, crie workflows "especializados".

```
MAIN ORCHESTRATOR (nunca muda)
    ↓ calls
    ├─ news-agent-workflow
    ├─ fundamental-agent-workflow
    ├─ macro-agent-workflow
    ├─ risk-agent-workflow
    └─ synthesis-workflow
```

**Vantagem:**
- Cada agent pode ser debugado isoladamente
- Fácil adicionar/remover agents
- Manutenção simples
- Escalável

### 3.2 - CREATE: First Specialized Agent (News Agent)

**Novo workflow:** `news-aggregator-agent`

```yaml
Trigger: None (vai ser chamado por outro workflow)

Nodes:
├─ Input Handler (recebe query + memory)
├─ HTTP Request (NewsAPI)
├─ Parse Results (Function Node)
├─ AI Agent (analisa notícias)
├─ Format Output (Function Node)
└─ Output
```

**Code: Input Handler**
```javascript
// $json vem do workflow que chamou
return {
  query: $json.query,
  user_memory: $json.memory,
  timestamp: new Date().toISOString()
};
```

**NewsAPI HTTP Request:**
```yaml
Method: GET
URL: https://newsapi.org/v2/everything
Params:
  ├─ q: "{{ $json.query }}"
  ├─ sortBy: "publishedAt"
  ├─ language: "pt"
  ├─ pageSize: 10
  └─ apiKey: "{{ $env.NEWSAPI_KEY }}"
```

**AI Agent (especialista em notícias):**
```yaml
Model: GPT-4o
System Message: |
  Você é analista de commodities especializado em news.
  
  Tarefa: Analisar artigos de notícias e extrair:
  1. Fatos-chave (what happened?)
  2. Impacto no preço (why does it matter?)
  3. Sentimento (bullish/bearish/neutral)
  4. Confiança (0-100)
  
  Retorne JSON estruturado:
  {
    "findings": [...],
    "overall_sentiment": "bullish|bearish|neutral",
    "confidence": 85,
    "sources": [...]
  }

Prompt from previous: Yes
```

### 3.3 - CALL SUBWORKFLOW: How to wire it

**No Orchestrator, onde estava o Agent:**

```yaml
REMOVA: The simple Agent node

ADICIONE: Call n8n Workflow node
├─ Workflow: "news-aggregator-agent"
├─ Input:
│   ├─ query: "{{ $json.query }}"
│   ├─ memory: "{{ $json.memory }}"
│   └─ context: "{{ $json.context }}"
└─ Wait for Response: Yes
```

**Resultado:**
- Query chega no Orchestrator
- Orchestrator chama News Agent
- News Agent processa e retorna
- Orchestrator recebe resultado

---

## PHASE 4: DATA INTEGRATION (5-7 dias)

### 4.1 - Supabase Setup

**No seu Supabase:**

```sql
-- Já criado no doc, mas aqui está o checklist:
✅ conversations table
✅ agent_metrics table
✅ documents table (com vector)
✅ tool_calls table
✅ analyses table

-- Índices críticos:
✅ CREATE INDEX ON documents USING ivfflat (embedding);
```

### 4.2 - Add Database Tool to Agents

**HTTP Request node (Supabase):**

```yaml
Node: HTTP Request - Supabase Query
├─ Method: POST
├─ URL: https://[project].supabase.co/rest/v1/rpc/search_documents
├─ Headers:
│   ├─ apikey: "{{ $env.SUPABASE_ANON_KEY }}"
│   └─ Authorization: "Bearer {{ $env.SUPABASE_SERVICE_KEY }}"
├─ Body:
│   ├─ query_embedding: "{{ $json.embedding }}"
│   ├─ match_threshold: 0.7
│   └─ match_count: 5
└─ Response: JSON
```

**Melhor: Use Supabase Python function**

```python
# Na Supabase, crie uma função RPC:
create or replace function search_documents(
  query_embedding vector,
  match_threshold float default 0.7,
  match_count int default 5
) returns table(id uuid, content text, similarity float) as $$
  select id, content, 1 - (embedding <=> query_embedding) as similarity
  from documents
  where 1 - (embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
$$ language sql;
```

**Então no n8n:**

```yaml
HTTP Request:
├─ POST: https://[project].supabase.co/rest/v1/rpc/search_documents
├─ Headers: auth headers
├─ Body:
│   ├─ query_embedding: "{{ embedArray }}"
│   ├─ match_threshold: 0.7
│   └─ match_count: 5
```

---

## PHASE 5: PARALLEL EXECUTION (3-4 dias)

### 5.1 - Run Multiple Agents in Parallel

**Pattern em n8n:**

```
[Orchestrator Receives Query]
    ↓
[Merge Branches Node] - cria N ramos
    ├─ Branch 1: Call news-agent
    ├─ Branch 2: Call fundamental-agent
    ├─ Branch 3: Call macro-agent
    └─ Branch 4: Call risk-agent
    ↓
[Wait for all to complete]
    ↓
[Synthesis Node]
```

**Node: Merge (é como parallel em código)**

```yaml
No Merge node separado!
Em vez disso, conecte múltiplos "Call n8n Workflow" nodes simultaneamente.

Exemplo:
[Orchestrator]
    ├─ output → [Call news-agent-workflow]
    ├─ output → [Call fundamental-agent-workflow]
    ├─ output → [Call macro-agent-workflow]
    └─ output → [Call risk-agent-workflow]

Todos rodam "ao mesmo tempo" (n8n trata parallelismo internamente)
```

**Síntese depois:**

```yaml
Node: Function (Synthesizer)
├─ Recebe outputs de todos os 4 nodes acima
├─ Code:
    return {
      news_results: $json["Call news-agent-workflow"].output,
      fundamental: $json["Call fundamental-agent-workflow"].output,
      macro: $json["Call macro-agent-workflow"].output,
      risk: $json["Call risk-agent-workflow"].output
    }

├─ Passa para: AI Agent (synthesis)
```

---

## PHASE 6: STREAMING + OPTIMIZATION (2-3 dias)

### 6.1 - Enable Streaming Response

```yaml
Chat Trigger:
├─ Response Mode: "Streaming response"
└─ Isso faz resposta chegar em tempo real (melhor UX)

AI Agent nodes:
├─ Com streaming, você vê respostas aparecendo palavra a palavra
├─ Melhor para análises longas
```

### 6.2 - Token Optimization

**Antes de cada chamada LLM:**

```javascript
// Function Node - Compress Context
const relevantMemory = $json.memory
  .filter(m => 
    m.text.toLowerCase().includes($json.query.toLowerCase())
  )
  .slice(-3); // últimas 3 mensagens relevantes

return {
  compact_memory: JSON.stringify(relevantMemory),
  original_query: $json.query,
  timestamp: Date.now()
};
```

**Caching:**

```yaml
Node: Function - Check Cache
├─ query_hash = md5(query)
├─ Look in Redis: "analysis:{{ query_hash }}"
├─ If found (within 1 hour): return cached result
├─ If not: proceed to analysis
├─ Store result: "analysis:{{ query_hash }}" (ttl: 3600s)
```

---

## PHASE 7: MONITORING & ERROR HANDLING (2-3 dias)

### 7.1 - Error Handling Nodes

```yaml
Every AI Agent Node should have:

├─ Connect to: Error Output
├─ Add: Catch Node
├─ In Catch:
│   ├─ Send error to Slack/Telegram
│   ├─ Log to Supabase
│   ├─ Fallback response to user
│   └─ Retry logic (max 2x)
```

**Example Catch Setup:**

```yaml
Catch Node:
├─ Input: Error from previous node
├─ Function:
    return {
      error: $json.message,
      timestamp: new Date(),
      agent: $json.nodeName,
      retry_count: $json.retryCount || 0
    }

├─ If retry_count < 2:
│   └─ Wait 2s, then retry previous node
├─ Else:
│   ├─ Log to DB
│   └─ Return fallback response
```

### 7.2 - Logging Setup

```yaml
Node: HTTP Request (Log to Supabase)
├─ After every analysis:
│   ├─ POST to Supabase: analyses table
│   ├─ Store: query, results, confidence, cost, user_rating
│   └─ Create unique analysis_id for feedback
```

---

## PHASE 8: PRODUCTION CHECKLIST

### Before Going Live:

```
✅ Credentials stored in .env (não hardcoded)
✅ All error paths tested
✅ Streaming enabled
✅ Logging ativo
✅ Cost tracking implementado
✅ Memory cleanup (old conversations)
✅ Rate limiting (if needed)
✅ Webhook URLs in production mode
✅ Monitoring dashboard rodando
✅ Backup strategy (database + workflows)
```

### Deploy Options:

```
OPTION 1: n8n Cloud
├─ Pros: Sem DevOps, auto-scaling
├─ Cons: Mais caro ($25+/mês)
├─ Best for: Prototipagem rápida

OPTION 2: Self-hosted (Railway/Render)
├─ Pros: Full control, barato ($10-50/mês)
├─ Cons: Gerenciamento seu
├─ Best for: Produção sólida

OPTION 3: Docker (seu servidor)
├─ Pros: Controle total
├─ Cons: Você mantém infraestrutura
├─ Best for: Enterprise
```

---

## QUICK REFERENCE: NATIVE NODES TÁ USAR

```
TRIGGERS:
├─ Chat Trigger ✅ (seu main portal)
├─ Webhook ✅ (para APIs externas)
├─ Schedule ✅ (para tasks agendadas)
└─ Manual ✅ (para testes)

AGENTS:
├─ AI Agent ✅ (Claude/GPT-4o)
├─ AI Agent Tool ✅ (NEW in 1.103 - especializado tools)
└─ LLM Chain ✅ (deprecated, não use)

TOOLS:
├─ HTTP Request ✅ (call any API)
├─ Code ✅ (JavaScript/Python)
├─ Call n8n Workflow ✅ (subworkflows)
├─ Supabase ✅ (direct SQL)
└─ Telegram/Email ✅ (outputs)

UTILITY:
├─ Function ✅ (transform data)
├─ Switch ✅ (conditional routing)
├─ Merge ✅ (parallel branches)
├─ Wait ✅ (delays)
└─ Error Handler ✅ (catch failures)

MEMORY:
├─ Buffer Memory ✅ (conversas)
├─ RAG Memory ✅ (semantic search)
└─ Database Memory ✅ (persistent)

OUTPUT:
├─ Respond to Chat ✅ (chat response)
├─ Respond to Webhook ✅ (HTTP response)
└─ No Op ✅ (descarte output)
```

---

## GOTCHAS & TIPS

```
🔴 ERROS COMUNS:

1. Esquecer Memory connection
   → Fix: Chat Trigger -mem-> Agent -mem-> Response

2. Tool não sendo usado pelo Agent
   → Fix: Max Iterations >= 5, System Prompt mentions tools

3. JSON response quebrada
   → Fix: Use Output Parser node, formato estruturado

4. Streaming não funciona
   → Fix: Confirmar "Response Mode: Streaming response"

5. Custos altos
   → Fix: Cache, context compression, tool reuse

🟢 BOAS PRÁTICAS:

1. Test cada node isoladamente
   → Clique "Test" antes de conectar

2. Use expressions para debugging
   → {{ $json | json2 }} mostra toda a estrutura

3. Nomeie nodes descritivamente
   → "Parse News Results" not "Function1"

4. Versionamento
   → Salve backups antes de grandes mudanças

5. Monitoring desde o início
   → Adicione logging desde Phase 1
```

---

## ROADMAP SUGERIDO

```
SEMANA 1: Phases 0-1 (Chat básico rodando)
SEMANA 2: Phases 2-3 (Memory + 1 especialista agent)
SEMANA 3: Phases 4-5 (Database + Parallelismo)
SEMANA 4: Phases 6-8 (Otimização + Produção)

Por fora: Bug fixes, prompt tuning, feedback loops
```

---

## RECURSOS

```
Docs: https://docs.n8n.io
Community: https://community.n8n.io
Templates: https://n8n.io/templates
GitHub: https://github.com/n8n-io/n8n

YouTubers (confiáveis):
- Josh Mountain (full courses)
- FlowGrammer (advanced patterns)
- TG Shambhu (LLM chains)
```

---

## SUA PRÓXIMA AÇÃO

1. Leia seu `RAG_ARCHITECTURE_v3.md` novamente
2. Comece PHASE 1 (Chat Trigger + Basic Agent)
3. Teste no Telegram
4. Mostre resultado aqui
5. A partir daí, construímos incrementalmente

**Não tente fazer tudo ao mesmo tempo. Pequenos passos, testes frequentes.**

Este guide evolui conforme você implementa. Salve as mudanças aqui.

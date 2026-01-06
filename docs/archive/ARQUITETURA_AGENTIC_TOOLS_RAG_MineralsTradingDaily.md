# Arquitetura “Agentic + Tools + RAG” (n8n) — Minerals Trading Daily  
_Data: 2026-01-05 (America/Sao_Paulo)_

## 1) Resposta direta: “usar tools em AI Agents” é mais simples do que RAG?
**Sim — para o que é “ação” e “acesso a dados estruturados”.**  
**Não — para “memória longa” e conhecimento interno não-estruturado.**  

A forma mais simples e escalável (e que está virando padrão) é **tratar o RAG como *mais um tool*** do agente, junto com ferramentas como: **consulta SQL**, **busca de preços**, **busca de notícias/web**, **extração de documentos**, **cálculos**, **validações**, etc. Assim você sai do “RAG monolítico” e entra no “Tool-first agent” com **sub-workflows reutilizáveis**.

---

## 2) O que os blueprints SOTA (TheAIAutomators) estão “te dizendo” na prática
Os exemplos que você subiu já implementam exatamente esse modelo híbrido:

### 2.1 Ingestion com versionamento (Record Manager)
- Gera **hash** do texto (SHA256) e consulta `record_manager_v2` para deduplicar por `doc_id + hash`.  
- Se mudou, cria/atualiza registro e processa o pipeline.  
Isso é ouro para reduzir custo e evitar “indexar o mesmo doc mil vezes”.

### 2.2 Retrieval como “serviço” (sub-workflow)
- O “retrieval sub-workflow” recebe `query`, pesos (`dense_weight`, `sparse_weight`, `ilike_weight`, `fuzzy_weight`…), e faz:
  - embedding do query (ex.: `text-embedding-3-small`);
  - busca híbrida;
  - rerank opcional (Cohere `rerank-v3.5`);
  - retorno de top chunks + scores.

### 2.3 Agente como orquestrador
- Memória curta com Postgres chat memory (session_id customizado).
- Conecta o chat trigger ao “Agent of choice” e aciona as tools.

### 2.4 Structured outputs para controlar tools
- O blueprint inclui **output parser estruturado (JSON Schema)** para limitar o formato do que o LLM pode produzir (ex.: filtros e condições).  
Isso é guardrail forte contra tool misuse.

---

## 3) Minha conclusão independente (macro): o caminho “melhor” em 2026
### Tese
Para o seu caso (automação + geração de conteúdo + dados de mercado), o “melhor” é:

**Agente (tools) → coleta evidências (RAG + dados externos) → verificação → escrita**  
com **RAG modular** (ingestion/retrieval) e **tools** para tudo que for determinístico/estruturado.

### Por que isso melhora sua vida
- **Menos prompt-engenharia como muleta**, mais “capability engineering”.
- **Menos acoplamento**: você troca o retriever sem reescrever o agente.
- **Mais previsibilidade**: ferramentas retornam JSON “limpo”; o LLM só decide **quando** chamar e **como** compor.
- **Mais segurança**: cada tool tem escopo, schema, limites e auditoria.

---

## 4) Arquitetura completa recomendada (em camadas)

## 4.1 Camada A — Ingestion (offline/assíncrono)
**WF009_rag_indexer (principal)**  
1) Normaliza doc: `doc_id`, `doc_type`, `source`, `published_at`, `lang`, `tags`.  
2) `hash` do conteúdo + `record_manager`:
   - se hash igual: **skip**
   - se mudou: status=processing  
3) Chunking “hierárquico” (títulos/sections)  
4) Embedding + upsert no vetor  
5) (opcional) KG: upsert para LightRAG (somente se você realmente for usar grafo na retrieval)  
6) Atualiza `record_manager`: status=ready, stats (chunks, tokens, custo, timestamp)

**Melhoria que eu adicionaria:**  
- **HNSW** como default quando começar a crescer (robusto e rápido) e evitar dor com IVFFlat.  
- Uma política “recência” (ex.: reindexar posts recentes a cada X dias e os antigos 1x/mês).

---

## 4.2 Camada B — Knowledge Services (tools/sub-workflows)
Pense nisso como um “catálogo de APIs internas” para o agente.

### Tool 1 — `retrieve_knowledge(query, filters, top_k)`
- Chama o WF de retrieval híbrido.
- Retorna: `chunks[]` com `chunk_id`, `doc_id`, `title`, `published_at`, `score`, `text`.

### Tool 2 — `expand_context(chunk_id, mode)`
- “Section expansion”: pega chunks vizinhos (mesma seção/pai) para reduzir fragmentação.

### Tool 3 — `lookup_doc(doc_id)`
- Quando o agente precisa do documento inteiro (ou resumo), sem depender só de chunks.

### Tool 4 — `get_price_data(symbols, range)`
- **Determinístico**: consulta API/DB (ex.: preços, fretes, curvas).  
- Volta sempre em formato tabular (JSON) para evitar hallucination.

### Tool 5 — `search_news_web(query, recency_days)`
- Busca externa (quando você precisa de “fato fresco”).
- Salva fontes + faz caching por query.

### Tool 6 — `verify_claims(claims[], evidence[])`
- Valida se cada afirmação tem suporte.  
- Se não tiver, marca “needs_source”.

**Principio:** tudo isso são *tools* com schema fixo; o agente não “inventa”.

---

## 4.3 Camada C — Agent (orquestração)
**WF002_rag_generator (principal)**  
- Entrada: tema / pauta / brief.
- Saída: artigo + metadados + fontes utilizadas.

### Pipeline “ideal”
1) **Router/Planner**
   - Decide se a pergunta exige:  
     a) só RAG interno;  
     b) RAG + preços;  
     c) web/news;  
     d) combinação.  
2) **Evidence gather**
   - Chama tools e monta um “Evidence Pack” (JSON) com:
     - chunks citáveis, dados de preço, links externos, timestamps.
3) **Answer composer**
   - Escreve o artigo usando apenas o Evidence Pack.
4) **Verifier**
   - Re-checa grounding + coerência numérica.
5) **Publisher**
   - Exporta HTML + slug + excerpt.

**Guardrails obrigatórios**
- “Se não tem evidência, diga que não tem”.
- “Sempre citar chunk_id ou fonte externa por parágrafo”.
- “Limites por tool”: max calls, max tokens, timeouts.

---

## 5) Implementação (o “ponto 5” aprofundado): como eu faria no n8n

### 5.1 Transformar sub-workflows em tools de verdade
No n8n, prefira expor capabilities como **Tool Workflow** (ou sub-workflows chamados como tools).  
Você já está nesse caminho (Tools como Sub-Workflows).

**Implementação prática:**
- Cada tool = 1 workflow com:
  - `Execute Workflow Trigger` com inputs tipados
  - normalização e validação
  - retorno em JSON estável
- O Agent chama essas tools via Tool Workflow / tool nodes.

### 5.2 Como desenhar o “Router/Planner”
**Opção A (simples):** 1 LLM node com saída estruturada:
```json
{
  "needs_internal_rag": true,
  "needs_prices": true,
  "needs_web": false,
  "filters": {"doc_type": ["post","guideline"], "recency_days": 365},
  "symbols": ["iron_ore_62", "freight_bdi"]
}
```

**Opção B (melhor):** Router usando regras + LLM:
- regras determinísticas (ex.: se contém “preço”, “USD/t”, “frete”, “FOB” → `needs_prices=true`)
- LLM só completa detalhes (símbolos, filtros).

### 5.3 Retrieval “híbrido” com knobs controláveis
Mantenha pesos como inputs do retriever (como no blueprint), mas **não deixe o agente mexer neles livremente**.
- defina presets: `balanced`, `precision`, `recall`
- o agente escolhe preset; o workflow traduz para pesos.

### 5.4 Rerank (quando usar)
Use rerank quando:
- query é ambígua  
- muitos chunks similares  
- você quer qualidade “editorial”  

Se o retriever já retorna pouco e muito bom, rerank vira custo sem ganho.

### 5.5 Memória: curta vs longa
- **Curta (chat memory)**: por sessão (`session_id`)
- **Longa**: só se existir um caso claro (ex.: preferências editoriais do blog, estilo, termos) — e sempre com “scoping” por projeto/usuário.

### 5.6 Observabilidade e avaliação
Sem avaliação contínua, você não sabe se “melhorou”.

Mínimo que eu colocaria:
- tracing (id da execução, custo, latência, tools chamadas)
- taxa de “sem evidência”
- nDCG/Recall@k em um conjunto de 30-50 queries internas (curado)

---

## 6) “Ferramentas melhores” e tecnologias recentes que valem considerar
### 6.1 MCP (Model Context Protocol) como *tool bus*
Se você quer adicionar ferramentas sem virar um manicômio de integrações, MCP ajuda:
- padrões de tool schemas
- governança e permissionamento
- pluga servidores de tools prontos

No n8n, a tendência é MCP entrar como “padrão de integração” para tools agentic.

### 6.2 Quando eu trocaria o vector store (ou não)
**Se o volume é moderado:** Supabase/pgvector é excelente (simplicidade + SQL + custo).  
**Se crescer muito:** considere Qdrant/Weaviate/Pinecone, mas só quando houver dor real (latência, custo, escalabilidade).

### 6.3 Knowledge Graph (LightRAG): usar ou não?
Use **se**:
- você quer responder perguntas do tipo “quem/onde/relacionado a”
- você quer inferência de relações e navegação por entidades

Evite (por enquanto) se:
- 90% é “recuperar parágrafos” e escrever artigo
- time não vai manter grafo e ontologia

---

## 7) Prompt (estilo “LLM system prompt”) para o seu agente
> **Copie e cole como “System Prompt” do Agent** e mantenha as tools com schema fixo.

### SYSTEM: Minerals Trading Daily — Orquestrador Agentic
Você é um agente de automação e redação para o blog *Minerals Trading Daily*.  
Seu trabalho é produzir artigos em português brasileiro com base em evidências coletadas via ferramentas.

**Objetivo:** gerar conteúdo factual, consistente e verificável, com dados numéricos quando aplicável.

#### Regras de Ouro
1) Nunca invente fatos, números, datas ou fontes.  
2) Se não houver evidência suficiente, declare explicitamente o que falta.  
3) Use as ferramentas quando precisar de:
   - conhecimento interno (RAG)
   - dados de preço (tool determinística)
   - dados recentes (web/news)
4) Cada parágrafo do artigo deve ser suportado por:
   - `chunk_id` interno **ou**
   - link externo + timestamp.

#### Estratégia (sempre)
1) Planeje (decida quais tools chamar).  
2) Colete evidências (chame tools e monte um Evidence Pack).  
3) Escreva usando apenas o Evidence Pack.  
4) Verifique (grounding + consistência numérica).  
5) Retorne no formato JSON definido.

#### Formato de saída (JSON)
```json
{
  "title": "max 70 chars",
  "slug": "slug-format",
  "excerpt": "max 160 chars",
  "content_html": "<p>...</p>",
  "sources_used": ["chunk_id_1", "chunk_id_2", "https://..."],
  "price_data_used": true,
  "grounding_confidence": 0.0
}
```

---

## 8) Plano de rollout (curto e realista)
1) **Semana 1**: transformar retrieval + price search em tools (sub-workflows) e plugar no Agent  
2) **Semana 2**: adicionar verificador + métricas + caching  
3) **Semana 3**: web/news tool + citabilidade obrigatória  
4) **Semana 4**: avaliar KG/LightRAG com 10-20 queries “de grafo”; manter só se ganhar

---

## 9) O que eu mudaria “agora” no seu caminho (sem vies)
- Você já escolheu o núcleo certo: **hybrid + record manager + tools + verificação**.  
- Eu só apertaria 4 parafusos:
  1) **RAG como tool** (oficializar de vez)
  2) **Tools determinísticas** para preço/notícia (evita hallucination)
  3) **Presets de retrieval** (não deixar weights livres)
  4) **Observabilidade + eval** desde o dia 1

Se você fizer só isso, o seu projeto sobe de “bom RAG” para “sistema agentic robusto”.

# ROADMAP FINAL - Minerals Trading Daily

**Data:** 2026-01-05
**Versao:** 2.0 (Unificado v1 + v2)
**Projeto:** Blog Automation n8n

---

## SUMARIO EXECUTIVO

### Nota Atual: 6.0/10
### Meta: 8.5/10

| Metrica | Antes | Depois | Ganho |
|---------|-------|--------|-------|
| Custo/mes | ~$950 | ~$400 | -58% |
| Confiabilidade | 70% | 99% | +41% |
| Deteccao erro | 90min | <1min | -99% |
| Qualidade conteudo | Base | +50% | +50% |
| Plataformas sociais | 1 (X) | 3+ | 3x |

### Decisoes Chave

| Categoria | Escolha | Motivo |
|-----------|---------|--------|
| Vector DB | pgvector | Ja usa Supabase, menos pecas |
| Social | Blotato | 4x mais barato que Buffer |
| Newsletter | AWS SES | Mais barato que SendGrid |
| Observability | Prometheus + Grafana | Simples primeiro, OTel depois |

---

## FASE 0: URGENTE (Hoje - 7 dias)

### 0.1 CVE Patch + Hardening - CONCLUIDO

**Severidade:** CRITICA (CVSS 9.9/10)
**Status:** n8n atualizado para versao mais recente

**Hardening adicional:**
- [ ] Restringir acesso ao editor (VPN/allowlist IP)
- [ ] Desabilitar webhooks publicos sem verificacao
- [ ] Rotacionar tokens/keys expostos

### 0.2 Error Handler (WF000) - CONCLUIDO

**Status:** WF000_error_handler ativo

### 0.2.1 Newsletter Pipeline (WF008 + WF008a) - CONCLUIDO

**Status:** Pipeline de newsletter funcionando end-to-end

**Correcoes aplicadas:**
- WF008 `ATUALIZAR MESSAGE ID`: filterType string + expressoes corrigidas
- WF008a `ATUALIZAR NEWSLETTER ENVIADA`: filterType string
- WF008a `ENVIAR MSG FINAL`: Substituido HTTP por node Telegram nativo
- SendGrid integrado para envio de emails

**Padrao aprendido:** Supabase node typeVersion 1 tem bug no filterType "manual" - usar "string" ao inves.

| Nivel | Descricao | Acao |
|-------|-----------|------|
| P0 | Publicou errado/duplicou | Alerta imediato |
| P1 | Nao publicou/falhou | Alerta em 5 min |
| P2 | Rate limit/timeout | Retry automatico |
| P3 | Dados faltando | Log apenas |

### 0.3 Retry + Idempotencia (CRITICO)

**Problema:** Retry sem idempotencia = duplicacao
**Tempo:** 4 horas

**Retry com backoff:**
```javascript
// Exponential backoff: 1s -> 2s -> 4s -> 8s
// Retry apenas para: 429, 503, timeout
// NAO retry para: 400, 401, 403
```

**Idempotencia minima:**
```javascript
const runId = `publish:${postId}:${contentVersion}`;

// Antes de publicar
const existing = await db.get(runId);
if (existing.status === 'done') return existing.result;

// Executar e marcar
await db.set(runId, { status: 'running' });
const result = await publishToWP(post);
await db.set(runId, { status: 'done', result });
```

### 0.4 DB Hygiene

**Problema:** Execucoes acumulando, storage crescendo
**Tempo:** 1 hora

**Configurar:**
- Retencao de execucoes (30 dias)
- Pruning automatico
- Limpar execucoes com payloads grandes

---

## FASE 1: OBSERVABILIDADE (Semanas 1-2)

### 1.1 Logging Estruturado

**Tempo:** 2 horas

```bash
# Variaveis de ambiente
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console
```

**Padrao de log:**
- Incluir `run_id` em todos os logs
- Formato JSON para parsing

### 1.2 Prometheus /metrics

**Tempo:** 2 horas

```bash
# Habilitar endpoint
N8N_METRICS=true
```

**Metricas a coletar:**
- `n8n_workflow_executions_total`
- `n8n_workflow_execution_duration_seconds`
- `n8n_workflow_errors_total`

### 1.3 Grafana Basico

**Tempo:** 4 horas

```yaml
# docker-compose.yml
services:
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
```

**Dashboards:**
1. Overview: Execucoes/dia, taxa erro
2. Performance: Duracao media por workflow
3. Custos: Tokens AI por dia (se rastrear)

### 1.4 Alertas Telegram

**Tempo:** 2 horas

**Configurar alertas para:**
- Error rate > 5% em 5 min
- Workflow critico falhou
- API externa down (429/503)

---

## FASE 2: QUALIDADE (Semanas 2-4)

### 2.1 RAG com pgvector

**Escolha:** pgvector (NAO Pinecone)
**Motivo:** Ja usa Supabase, menos complexidade
**Tempo:** 8 horas

```sql
-- Habilitar extensao
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabela de chunks
CREATE TABLE knowledge_chunks (
  id bigserial PRIMARY KEY,
  source_type text NOT NULL,      -- post | guideline | glossary
  source_id text NOT NULL,
  chunk_index int NOT NULL,
  chunk_text text NOT NULL,
  embedding vector(1536),
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Indice para busca vetorial
CREATE INDEX ON knowledge_chunks
  USING ivfflat (embedding vector_cosine_ops);
```

**Workflows a criar:**
- `WF009_rag_indexer`: Indexa posts publicados
- `WF010_rag_query`: Retrieve + Generate

### 2.2 Evaluation Node

**Tempo:** 4 horas

**Usar n8n Evaluation Trigger:**
- Dataset fixo: 50-200 casos
- Rodar diariamente
- Bloquear se score < threshold

**Metricas:**
- Groundedness (com RAG)
- Duplicidade
- Estilo/voz (rubrica)

### 2.3 Guardrails de Publicacao

**Tempo:** 2 horas

**NAO publicar se:**
- Fonte insuficiente (RAG abaixo threshold)
- Score de avaliacao < X
- Risco de duplicacao alto
- Conteudo muito curto

### 2.4 Melhorar Prompts

**Prioridade:** LinkedIn e Instagram (2/10 -> 8/10)
**Tempo:** 4 horas

**LinkedIn - Estrutura:**
1. Hook (1-2 linhas): Pergunta provocadora
2. Story (3-5 linhas): Narrativa com numeros
3. Insights (3-5 linhas): Valor concreto
4. CTA (1 linha): Pergunta que gera comentario

**Instagram - Estrutura:**
1. Emoji Hook
2. Headline
3. Story/Contexto
4. Lesson
5. CTA + Hashtags

---

## FASE 3: DISTRIBUICAO (Semanas 4-6)

### 3.1 Social: Blotato

**Escolha:** Blotato ($29/mes) vs Buffer ($120/mes)
**Economia:** $91/mes = $1,092/ano
**Tempo:** 4 horas

**Vantagens:**
- AI writing ilimitado (Claude/GPT-4)
- API access para n8n
- Content repurposing automatico

**Integracao:**
```
n8n -> Blotato API -> Agenda em todas as redes
                   |
          Blotato -> Publica automaticamente
```

### 3.2 Newsletter: AWS SES

**Escolha:** AWS SES vs SendGrid
**Motivo:** SendGrid mudou pricing ($19.95+ agora)
**Tempo:** 2 horas

**Alternativas:**
| Servico | Custo | Melhor para |
|---------|-------|-------------|
| AWS SES | ~$0.10/1000 | Volume alto |
| Resend | $20+/mes | DX excelente |
| Brevo | Variavel | Suite completa |

### 3.3 Imagens

**Estado atual:** Gemini (7/10, ~$0.04/img)
**Avaliar:** DALL-E 3 (8/10, ~$0.02/img)
**Tempo:** 2 horas

---

## FASE 4: RESILIENCIA (Semanas 6-8)

### 4.1 LLM Fallback

**Tempo:** 3 horas

**Cascata:**
```
Claude Sonnet (primario)
    |
    v (se falha)
GPT-4o (backup)
    |
    v (se falha)
Gemini 2.0 (emergency)
```

### 4.2 State Machine

**Tempo:** 4 horas

**Estados por run_id:**
```
planned -> drafting -> approved -> published -> distributed
```

**Dead-letter:** Runs que falharam N vezes -> revisao humana

### 4.3 Backup/DR

**Tempo:** 2 horas

- [ ] Snapshot Supabase (diario)
- [ ] Export workflows JSON (semanal)
- [ ] Plano de restore testado

---

## FASE 5: ESCALA (Mes 2+)

### 5.1 Queue Mode

**Quando:** Se escalar muito (>100 execucoes/hora)
**Tempo:** 4 horas

```bash
N8N_EXECUTION_MODE=queue
N8N_QUEUE_DRIVER=redis
```

**Atencao:** Binarios em filesystem nao combina com queue. Usar S3/minio.

### 5.2 Source Control

**Tempo:** 3 horas

- Git para workflow JSONs
- Environments: dev/stage/prod
- PR review para mudancas

### 5.3 Analytics Dashboard

**Tempo:** 6 horas

**Metricas:**
- Posts publicados/dia
- Taxa aprovacao/rejeicao
- Tempo medio revisao
- Custo API por workflow
- ROI por canal

---

## FERRAMENTAS ESCOLHIDAS

| Categoria | Ferramenta | Custo/mes | Status |
|-----------|------------|-----------|--------|
| Database | Supabase (existente) | ~$25 | Manter |
| Vector DB | pgvector | $0 | Usar Supabase |
| Social | Blotato | $29 | Migrar |
| Newsletter | AWS SES | ~$5 | Migrar |
| Observability | Prometheus + Grafana | $0 | Implementar |
| Error Tracking | Sentry (opcional) | $0-29 | Avaliar |
| LLM | Claude (existente) | Variavel | Manter |
| Images | Gemini/DALL-E | ~$20-40 | Avaliar |

---

## CRONOGRAMA

```
JANEIRO 2026
|---- Hoje/Esta Semana ----|
  [P0] CVE Patch + Hardening
  [P0] Error Handler (WF000)
  [P0] Retry + Idempotencia
  [P0] DB Hygiene

|---- Semanas 1-2 ----|
  [P0] Logging estruturado
  [P0] Prometheus /metrics
  [P0] Alertas Telegram
  [P1] Grafana basico

|---- Semanas 2-4 ----|
  [P1] RAG com pgvector
  [P1] Evaluation node
  [P1] Prompts LinkedIn/Instagram
  [P1] Guardrails publicacao

FEVEREIRO 2026
|---- Semanas 4-6 ----|
  [P1] Blotato integration
  [P1] Newsletter AWS SES
  [P2] Avaliar imagens

|---- Semanas 6-8 ----|
  [P2] LLM Fallback
  [P2] State machine
  [P2] Backup/DR

MARCO+ 2026
  [P3] Queue Mode (se necessario)
  [P3] Source Control
  [P3] Analytics Dashboard
```

---

## INVESTIMENTO

### Tempo
| Fase | Horas | Prazo |
|------|-------|-------|
| Fase 0 (Urgente) | 10h | Esta semana |
| Fase 1 (Observability) | 10h | Semanas 1-2 |
| Fase 2 (Qualidade) | 18h | Semanas 2-4 |
| Fase 3 (Distribuicao) | 8h | Semanas 4-6 |
| Fase 4 (Resiliencia) | 9h | Semanas 6-8 |
| Fase 5 (Escala) | 13h | Mes 2+ |
| **TOTAL** | **~68h** | **~8 semanas** |

### Custo Mensal
| Item | Antes | Depois |
|------|-------|--------|
| APIs AI | ~$600 | ~$400 (cache + routing) |
| Imagens | ~$50 | ~$30 |
| Social | $0 | $29 (Blotato) |
| Newsletter | $0 | ~$5 (SES) |
| Infra | ~$300 | ~$25 (otimizado) |
| **TOTAL** | **~$950** | **~$489** |

### ROI
- **Economia:** ~$460/mes
- **Investimento tempo:** 68h
- **Payback:** ~2-3 meses
- **ROI anual:** ~$5,500

---

## PROXIMOS PASSOS IMEDIATOS

### Concluido
- [x] Verificar versao n8n (CVE) - Atualizado
- [x] Ativar WF000 Error Handler - Ativo

### Esta Semana
- [ ] Implementar retry + idempotencia
- [ ] Configurar DB hygiene
- [ ] Setup logging estruturado

### Proxima Semana
- [ ] Prometheus /metrics
- [ ] Alertas Telegram
- [ ] Primeiro dashboard Grafana

---

## REFERENCIAS

### Documentacao n8n
- [Error Trigger](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.errortrigger/)
- [Queue Mode](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [RAG in n8n](https://docs.n8n.io/advanced-ai/rag-in-n8n/)
- [Evaluations](https://docs.n8n.io/advanced-ai/evaluations/overview/)

### Ferramentas
- [Blotato](https://blotato.com/)
- [AWS SES](https://aws.amazon.com/ses/)
- [pgvector](https://github.com/pgvector/pgvector)

---

## HISTORICO

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 2.2 | Newsletter pipeline (WF008+WF008a) corrigido e funcionando |
| 2026-01-05 | 2.1 | CVE patch e Error Handler marcados como concluidos |
| 2026-01-05 | 2.0 | Unificacao v1 + v2, prioridades corrigidas |
| 2026-01-05 | 1.0 | Roadmap inicial (v1) |

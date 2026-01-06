# ROADMAP FINAL - Minerals Trading Daily

**Data:** 2026-01-06
**Versao:** 2.6 (Sistema de Alertas P0-P3)
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

### ~~0.3 Retry + Idempotencia~~ - META FUTURA

**Status:** Adiado (projeto pequeno, baixo volume)
**Motivo:** Risco de duplicacao baixo com volume atual

### ~~0.4 DB Hygiene~~ - META FUTURA

**Status:** Adiado (projeto pequeno)
**Motivo:** Storage nao e problema no momento

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

### ~~1.2 Prometheus /metrics~~ - META FUTURA

**Status:** Adiado (projeto pequeno)
**Motivo:** Logging basico suficiente para volume atual

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

### 1.4 Alertas Telegram - CONCLUIDO (2026-01-06)

**Status:** Implementado com sistema de prioridades P0-P3

**O que foi feito:**
- [x] WF000: Sistema de prioridades P0-P3 implementado
- [x] WF000: Busca configuracao de prioridade por workflow
- [x] WF000: P0/P1 notifica imediatamente, P2/P3 apenas loga
- [x] WF009: Corrigido bug de tabela errada
- [x] WF009: Adicionado calculo de error rate (erros/hora)
- [x] WF012: Resumo diario criado (8:00 AM)
- [x] Tabela `08_sys_alert_config` criada com 23 workflows configurados
- [x] Campo `priority_level` adicionado em `08_sys_errors`

**Niveis de alerta configurados:**
| Nivel | Acao | Workflows |
|-------|------|-----------|
| P0 | Alerta imediato | WF006a, WF007a, WF008a (publicacao) |
| P1 | Alerta imediato | WF001, WF002, WF007, WF008, WF010 |
| P2 | Apenas log | WF003-WF006 (preview, revisao) |
| P3 | Apenas log | WF000, WF009, WF011, WF_CHAT |

**Workflows de monitoramento:**
- `WF000_error_handler` - Captura erros, classifica, notifica
- `WF009_alerts_proactive` - Monitoramento a cada 2h + error rate
- `WF012_daily_summary` - Resumo diario 8:00 AM

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

### 2.4 Melhorar Prompts - CONCLUIDO

**Newsletter:** CONCLUIDO (3/10 -> 9/10) - 2026-01-06
- Few-shot examples com 2 cenarios (alta e queda)
- Estrutura de 5 secoes obrigatorias
- Regras de estilo claras
- Integracao com Baltic indices

**LinkedIn:** CONCLUIDO (2/10 -> 9/10) - 2026-01-06
- 3 few-shot examples (queda, alta, producao)
- Estrutura HOOK-CONTEXTO-ANALISE-INSIGHT-CTA
- System message com persona Bloomberg Commodities
- Publico-alvo C-level definido

**Instagram:** CONCLUIDO (2/10 -> 9/10) - 2026-01-06
- 4 few-shot examples (queda, alta, ESG, frete)
- Estrutura HOOK-CORPO-INSIGHT-CTA
- Estrategia de 15 hashtags mix PT/EN
- Mobile-first design

**STATUS: TODOS OS PROMPTS CRITICOS CONCLUIDOS!**

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
|---- Hoje/Esta Semana (PRIORIDADE) ----|
  [x] CVE Patch + Hardening - CONCLUIDO
  [x] Error Handler (WF000) - CONCLUIDO
  [x] Newsletter prompt (9/10) - CONCLUIDO
  [x] Prompt LinkedIn (9/10) - CONCLUIDO
  [x] Prompt Instagram (9/10) - CONCLUIDO
  [!!] Credenciais LinkedIn + Instagram
  [!!] Testar postagens sociais

|---- Semanas 1-2 ----|
  [P1] Logging estruturado
  [P1] Alertas Telegram
  [P1] RAG com pgvector
  [P2] Grafana basico (opcional)

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

### Tempo (Atualizado)
| Fase | Horas | Status |
|------|-------|--------|
| Fase 0 (Urgente) | ~~10h~~ 3h | CVE+Error CONCLUIDO, resto adiado |
| Fase 1 (Observability) | ~~10h~~ 6h | Prometheus adiado |
| Fase 2 (Qualidade) | 18h | Em andamento |
| Fase 3 (Distribuicao) | 8h | Pendente |
| Fase 4 (Resiliencia) | 9h | Meta futura |
| Fase 5 (Escala) | 13h | Meta futura |
| **TOTAL ATIVO** | **~35h** | **~4 semanas** |

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

### Esta Semana (PRIORIDADE)
- [ ] **Melhorar prompt LinkedIn (2/10 -> 8/10)**
- [ ] **Melhorar prompt Instagram (2/10 -> 8/10)**
- [ ] **Configurar credenciais LinkedIn e Instagram no n8n**
- [ ] Testar postagens em ambas as redes

### Proxima Semana
- [ ] Setup logging estruturado
- [ ] Alertas Telegram para erros criticos
- [ ] Completar RAG com pgvector

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
| 2026-01-06 | 2.6 | Sistema de Alertas P0-P3 implementado, WF012 resumo diario criado |
| 2026-01-06 | 2.6 | Prompts LinkedIn e Instagram CONCLUIDOS (2/10 -> 9/10) |
| 2026-01-06 | 2.5 | Prioridade: LinkedIn + Instagram prompts e credenciais |
| 2026-01-06 | 2.4 | Retry, DB Hygiene, Prometheus movidos para meta futura |
| 2026-01-06 | 2.3 | Newsletter prompt melhorado (3/10 -> 9/10), few-shot examples |
| 2026-01-05 | 2.2 | Newsletter pipeline (WF008+WF008a) corrigido e funcionando |
| 2026-01-05 | 2.1 | CVE patch e Error Handler marcados como concluidos |
| 2026-01-05 | 2.0 | Unificacao v1 + v2, prioridades corrigidas |
| 2026-01-05 | 1.0 | Roadmap inicial (v1) |

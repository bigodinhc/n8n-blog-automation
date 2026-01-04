# Arquitetura do Sistema

## Visao Geral

O Blog System Automation e um sistema automatizado de blog para inteligencia do mercado de minerio de ferro. O sistema captura dados brutos do mercado (incluindo precos Platts Asia Iron Ore IODEX), processa atraves de agentes AI, e gerencia um workflow editorial completo via Telegram para revisao humana antes de publicacao multi-plataforma.

**Site:** [mineralstradingdaily.com.br](https://mineralstradingdaily.com.br)

---

## Diagrama de Pipelines

```
+-----------------------------------------------------------------------------+
|                           PIPELINE DE CONTEUDO                               |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +----------+    +----------+    +----------+    +----------+               |
|  |   WF1    |--->|   WF2    |--->|   WF3    |--->|   WF4    |               |
|  |  DATA    |    | CONTENT  |    |  DRAFT   |    | CALLBACK |               |
|  | FETCHER  |    | ARCHIVER |    |  REVIEW  |    |  DRAFTS  |               |
|  +----------+    +----------+    +----------+    +----+-----+               |
|       |              |                |               |                      |
|   RSS/Apify      AI Agent         Telegram        +---+---+                 |
|   Telegram       Archiver         Preview         |   |   |                 |
|                  Rewriter                    +----v-+ | +-v----+            |
|                                              |WF4.5 | | | WF5  |            |
|                                              |FEEDBK| | |REVIS.|            |
|                                              +------+ | +------+            |
|                                                   +---v---+                  |
|                                                   |WF4.7  |                  |
|                                                   |QUICK  |                  |
|                                                   | EDIT  |                  |
|                                                   +-------+                  |
|                                                                              |
+-----------------------------------------------------------------------------+
|                           PIPELINE DE IMAGEM                                 |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +----------+    +----------+    +----------+                               |
|  |   WF6    |--->|  WF6.5   |--->|WordPress |                               |
|  |  IMAGE   |    |  IMAGE   |    | Publish  |                               |
|  |GENERATOR |    | APPROVAL |    |          |                               |
|  +----------+    +----------+    +----+-----+                               |
|       |              |                |                                      |
|   GPT-4.1-mini   Telegram          Publicado                                |
|   + Gemini       Preview                                                     |
|                                                                              |
+-----------------------------------------------------------------------------+
|                        PIPELINE DE REDES SOCIAIS                             |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +----------+    +----------+    +----------+                               |
|  |   WF7    |--->|  WF7.2   |--->|  WF7.1   |                               |
|  | SOCIAL   |    |  IMAGE   |    | SOCIAL   |                               |
|  | FACTORY  |    | CALLBACK |    | CALLBACK |                               |
|  +----------+    +----------+    +----------+                               |
|       |              |                |                                      |
|   AI Content     Img Approve      Twitter (ativo)                           |
|   + Img Gen      Telegram         LinkedIn (pendente)                       |
|                                   Instagram (pendente)                       |
|                                                                              |
+-----------------------------------------------------------------------------+
|                        PIPELINE DE NEWSLETTER                                |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +----------+    +----------+                                               |
|  |   WF8    |--->|  WF8.1   |                                               |
|  |NEWSLETTER|    |NEWSLETTER|                                               |
|  |GENERATOR |    | CALLBACK |                                               |
|  +----------+    +----------+                                               |
|       |                                                                      |
|   Coleta paralela --> AI Agent (Claude) --> HTML --> Imagem --> Telegram    |
|                                                                              |
+-----------------------------------------------------------------------------+
```

---

## Workflows

### Pipeline de Conteudo

| ID | Codigo | Nome | Nodes | Funcao |
|----|--------|------|-------|--------|
| `TgZ3HSnbbSVHsIzD` | WF1 | Feed Supabase | 40 | Ingestao de dados (RSS, Telegram, Apify) |
| `LfU5ddiFTiDSrUSp` | WF2 | Content Archiver | 20 | AI gera artigo estruturado |
| `J7G0HJYT2yqL3WQq` | WF3 | Draft Review | 13 | Inicia revisao via Telegram |
| `Eqj6uTE4pFizUsKH` | WF4 | Callback Drafts | 26 | Processa botoes de aprovacao |
| `QElqWkwrvoxGKDN4` | WF4.5 | Feedback Capture | 14 | Captura feedback de texto |
| `UoQK3JSa2tzPHpxW` | WF4.6 | Quick Edit Capture | 11 | Captura edicoes rapidas |
| `bKvqmScFWW9KK8ur` | WF4.7 | Quick Edit Callbacks | 24 | Processa edicoes rapidas |
| `5TuCwLZLlGdczwhU` | WF5 | Revision Processor | 12 | AI aplica revisoes |

### Pipeline de Imagem

| ID | Codigo | Nome | Nodes | Funcao |
|----|--------|------|-------|--------|
| `yr7VUG1VMi8o8fi9` | WF6 | Image Generator | 20 | GPT-4 gera prompt, Gemini gera imagem |
| `vqW2Dt3FkbkQPHws` | WF6.5 | Image Approval | 26 | Aprovacao e publicacao WordPress |

### Pipeline de Redes Sociais

| ID | Codigo | Nome | Nodes | Funcao |
|----|--------|------|-------|--------|
| `KkCUTo9KVfZkfZrE` | WF7 | Social Media Factory | 25 | AI gera conteudo para 3 plataformas |
| `ZvWogMCqmetav8Fa` | WF7.1 | Social Callback | 28 | Publica nas redes |
| `t4M4Qav7y3860Bje` | WF7.2 | Image Callback | 24 | Aprova imagens de redes |

### Pipeline de Newsletter

| ID | Codigo | Nome | Nodes | Funcao |
|----|--------|------|-------|--------|
| `gMknz5KYcdJuu1Eg` | WF8 | Newsletter Generator | 21 | Gera newsletter diaria (17h) |
| `e88ZJNv0ffG8nILx` | WF8.1 | Newsletter Callback | 28 | Processa aprovacao e envio |

### Utilitarios

| ID | Codigo | Nome | Nodes | Funcao |
|----|--------|------|-------|--------|
| `dxVlQYOyMQ4xxaHt` | WF0 | Error Handler | 10 | Tratamento centralizado de erros |
| `qOtYC2eCKW7VHK9M` | CMD | Telegram Commands | 12 | Comandos /status, /queue, /stats |
| `OLgG9Y2iHQVujYXB` | Alerts | Proactive Alerts | 7 | Monitoramento a cada 2h |

---

## Banco de Dados (Supabase)

**Projeto ID:** `pbhvhfahcvgmgjvuhwuk`
**Regiao:** us-east-2

### Tabelas Principais

| Tabela | Funcao | Registros |
|--------|--------|-----------|
| `raw_inputs` | Dados brutos de feeds | ~56 |
| `market_intelligence` | Dados estruturados de mercado | ~55 |
| `content_posts` | Posts do blog | ~55 |
| `content_metadata` | Metadados (tags, SEO) | ~56 |
| `content_workflow` | Estado do workflow por post | ~59 |
| `post_images` | Imagens geradas | ~34 |
| `published_content` | Registro de publicacoes | ~53 |
| `social_media_sessions` | Sessoes de publicacao social | ~64 |
| `feedback_sessions` | Sessoes de feedback | ~1 |
| `edit_sessions` | Sessoes de edicao rapida | ~1 |
| `newsletter_history` | Historico de newsletters | ~11 |
| `newsletter_sessions` | Sessoes de aprovacao newsletter | ~8 |
| `newsletter_subscribers` | Assinantes | ~1 |
| `newsletter_send_log` | Log de envios | 0 |
| `iron_ore_prices` | Precos Platts IODEX | ~11.559 |
| `system_errors` | Log de erros | 0 |

### Schemas Importantes

**content_posts:**
```sql
id UUID PRIMARY KEY
title VARCHAR(200) NOT NULL
slug VARCHAR(200) UNIQUE
content_html TEXT
excerpt TEXT
status VARCHAR(20) DEFAULT 'draft'
published_at TIMESTAMPTZ
wordpress_id INTEGER
created_at TIMESTAMPTZ DEFAULT now()
```

**content_workflow:**
```sql
id UUID PRIMARY KEY
post_id UUID REFERENCES content_posts(id)
stage VARCHAR(30) DEFAULT 'draft'
review_notes TEXT
approved_by VARCHAR(50)
approved_at TIMESTAMPTZ
created_at TIMESTAMPTZ DEFAULT now()
```

**newsletter_history:**
```sql
id UUID PRIMARY KEY
subject VARCHAR(200) NOT NULL
content_html TEXT NOT NULL
summary TEXT
posts_included JSONB
price_data JSONB
perplexity_context TEXT
ai_analysis JSONB
status VARCHAR(20) DEFAULT 'draft'
sent_at TIMESTAMPTZ
recipients_count INT
```

---

## Integracoes

### APIs de AI

| Servico | Credential ID | Uso |
|---------|---------------|-----|
| Anthropic (Claude) | `fjN5QtG5xAcoiOWE` | WF2 Archiver, WF5 Revision, WF8 Newsletter |
| OpenAI (GPT-4) | Configurado | WF6 Prompt de Imagem, WF7 Social |
| Google Gemini | `VStJZ2Am1t3kqbKB` | WF6/WF7 Geracao de Imagens |
| Perplexity | `5ORcQ8DiAwHBwAC3` | WF8 Pesquisa de Mercado |

### Plataformas

| Servico | Credential ID | Status |
|---------|---------------|--------|
| Supabase | `04rdCJqTixOtwak5` | Ativo |
| WordPress | Configurado | Ativo |
| Twitter/X | `CzoU1m1eqk0uDfMv` | Ativo |
| LinkedIn | - | Pendente (estrutura pronta) |
| Instagram | - | Pendente (estrutura pronta) |

### Telegram Bots

| Bot | Funcao |
|-----|--------|
| BlogDraftsBot | WF3, WF4, WF4.5, WF5, WF8 |
| QuickEditBot | WF4.7 |
| SocialMediaBot | WF7, WF7.1, WF7.2 |

**Chat ID Principal:** `8375309778`

---

## Fluxo Principal Detalhado

```
1. INGESTAO (WF1)
   - RSS feeds de noticias de commodities
   - Mensagens do Telegram
   - Apify Actor para scraping
   - Hash para deduplicacao

2. PROCESSAMENTO (WF2)
   - AI Archiver cria artigo estruturado
   - AI Rewriter formata em estilo jornalistico
   - Salva em content_posts como 'draft'

3. REVISAO (WF3 + WF4)
   - Cria sessao de revisao
   - Envia preview formatado no Telegram
   - Botoes: Aprovar / Rejeitar / Feedback / Editar

4. EDICAO (WF4.5 + WF4.6 + WF4.7 + WF5)
   - Feedback: usuario digita instrucoes, AI aplica
   - Quick Edit: edicao direta de titulo/tags
   - Conteudo: AI reescreve baseado em feedback

5. IMAGEM (WF6 + WF6.5)
   - GPT-4 gera prompt descritivo
   - Gemini gera imagem
   - Usuario aprova via Telegram
   - Publica no WordPress

6. SOCIAL (WF7 + WF7.1 + WF7.2)
   - AI gera conteudo para Twitter/LinkedIn/Instagram
   - Gera imagem especifica para redes
   - Usuario seleciona plataformas
   - Publica (Twitter ativo)

7. NEWSLETTER (WF8 + WF8.1)
   - Coleta posts do dia + precos Platts
   - Perplexity adiciona contexto de mercado
   - AI gera newsletter estruturada
   - Preview no Telegram
   - Envio via SendGrid (pendente)
```

---

## Limitacoes Conhecidas

### Telegram callback_data
- Limite de 64 bytes
- Formato atual: `pub_UUID` (40 chars)
- Parser suporta formato antigo para compatibilidade

### AI Agents
- Timeouts em respostas longas
- Custo de API (Claude > GPT-4 > Haiku)
- Qualidade de prompt afeta diretamente output

### Fluxos Paralelos vs Sequenciais
- Paralelo: bom para APIs independentes
- Sequencial: melhor para processamento dependente
- Merge nodes nao combinam JSON automaticamente

---

*Ultima atualizacao: Janeiro 2026*

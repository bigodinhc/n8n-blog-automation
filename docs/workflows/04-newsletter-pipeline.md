# 04 - Newsletter Pipeline

Pipeline de geracao e envio de newsletter diaria.

## Fluxo Geral

```
WF8 Newsletter Generator → WF8.1 Newsletter Callback
         │                          │
    Coleta paralela            Aprovar/Enviar
    AI + Imagem                Gmail/WhatsApp
    Telegram Preview
```

## Workflows

### WF8 - Newsletter Generator (21 nodes)
**ID:** `gMknz5KYcdJuu1Eg`
**Status:** Ativo

Geracao automatica de newsletter diaria.

```
TRIGGER 17H DIAS UTEIS → INIT DATA
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
     BUSCAR POSTS        BUSCAR PRECOS    PERPLEXITY MERCADO
     DO DIA              PLATTS               │
            │                 │                 │
            └─────────────────┼─────────────────┘
                              ▼
                            Merge
                              │
                              ▼
                      CONSOLIDAR DADOS
                              │
                              ▼
                      AI Agent (Claude)
                              │
                              ▼
                      PARSE AI RESPONSE
                              │
                              ▼
                         GERAR HTML
                              │
                              ▼
                   AI PROMPT TWITTER IMAGE (GPT-4.1-mini)
                              │
                              ▼
                   GERAR IMAGEM NEWSLETTER (Gemini)
                              │
                              ▼
                      CONSOLIDAR FINAL
                              │
                              ▼
                      SALVAR NEWSLETTER
                              │
                              ▼
                        CRIAR SESSAO
                              │
                              ▼
                      PREPARAR PREVIEW
                              │
                              ▼
                   ENVIAR PREVIEW TELEGRAM
                              │
                              ▼
                    ATUALIZAR MESSAGE ID
                              │
                              ▼
                         LOG FINAL
```

**Trigger:** Cron 17h dias uteis (0 20 * * 1-5 UTC)

**Coleta paralela:**
- Posts publicados ontem
- Precos Platts IODEX (12 indicadores)
- Contexto de mercado via Perplexity

**AI Agent (Claude):**
Gera JSON estruturado com:
- `resumo_executivo`: 2-3 paragrafos
- `destaques`: 3 bullet points
- `perspectivas`: 1-2 paragrafos
- `whatsapp_text`: Versao curta (max 500 chars)
- `subject_line`: Assunto do email (max 60 chars)

**Geracao de imagem:**
- GPT-4.1-mini: Prompt contextual
- Gemini: Imagem industrial tematica

**Tabelas afetadas:** `newsletter_history`, `newsletter_sessions`

---

### WF8.1 - Newsletter Callback (28 nodes)
**ID:** `e88ZJNv0ffG8nILx`
**Status:** Inativo

Aprovacao e envio de newsletter.

```
TRIGGER TELEGRAM → PROCESSAR CALLBACK → EH NEWSLETTER?
                                              │
                                              ▼
                                    RESPONDER CALLBACK
                                              │
                                              ▼
                                        BUSCAR SESSAO
                                              │
                                              ▼
                                      BUSCAR NEWSLETTER
                                              │
                                              ▼
                                         QUAL ACAO?
                                              │
      ┌───────────────┬───────────────┬───────┼───────────────┬───────────────┐
      ▼               ▼               ▼       ▼               ▼               ▼
APROVAR CONTEUDO  VER IMAGEM   APROVAR IMAGEM  ENVIAR TODOS  CANCELAR
      │               │               │           │               │
      ▼               ▼               ▼           ▼               ▼
UPDATE CONTENT   SEND PREVIEW  UPDATE IMAGE   ENVIAR GMAIL  UPDATE CANCELLED
      │                              │           │               │
      ▼                              ▼           ▼               ▼
SEND MSG          ...          SEND MSG    UPDATE SENT      SEND MSG
                                                │
                                                ▼
                                          SEND CONFIRMACAO
```

**Acoes disponiveis:**
- `nl_approve_content` → Aprovar conteudo textual
- `nl_view_image` → Ver preview da imagem
- `nl_approve_image` → Aprovar imagem
- `nl_send_all` → Enviar para todos os assinantes
- `nl_cancel` → Cancelar newsletter

**Canais de envio:**
- Gmail: Ativo
- WhatsApp via UaZapi: Desabilitado (nodes disabled)

**Tabelas afetadas:** `newsletter_history`, `newsletter_sessions`

## Tabelas do Banco

### newsletter_history
```sql
CREATE TABLE newsletter_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject VARCHAR(200) NOT NULL,
  content_html TEXT NOT NULL,
  summary TEXT,
  posts_included JSONB,
  price_data JSONB,
  perplexity_context TEXT,
  ai_analysis JSONB,
  status VARCHAR(20) DEFAULT 'draft',
  sent_at TIMESTAMPTZ,
  recipients_count INT,
  open_rate DECIMAL,
  click_rate DECIMAL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### newsletter_sessions
```sql
CREATE TABLE newsletter_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  newsletter_id UUID REFERENCES newsletter_history(id),
  chat_id VARCHAR(50) NOT NULL,
  message_id INTEGER,
  stage VARCHAR(20) DEFAULT 'pending_content',
  content_approved BOOLEAN DEFAULT false,
  image_approved BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## Dependencias

- **Supabase**: Tabelas de newsletter + precos
- **Anthropic Claude**: AI para conteudo
- **OpenAI GPT-4.1-mini**: Prompt de imagem
- **Google Gemini**: Geracao de imagem
- **Perplexity**: Pesquisa de mercado
- **Gmail**: Envio de emails
- **Telegram Bot**: BlogDraftsBot

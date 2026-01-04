# 01 - Content Pipeline

Pipeline principal de criacao e revisao de conteudo.

## Fluxo Geral

```
WF1 Feed → WF2 Archiver → WF3 Draft Review → WF4 Callback
                                                   │
                     ┌─────────────────────────────┼─────────────────────────────┐
                     ▼                             ▼                             ▼
              WF4.5 Feedback                WF4.6 Quick Edit              WF4.7 Quick Edit CB
                     │                             │                             │
                     └─────────────────────────────┴─────────────────────────────┘
                                                   │
                                                   ▼
                                          WF5 Revision Processor
```

## Workflows

### WF1 - Feed Supabase Blogging (37 nodes)
**ID:** `TgZ3HSnbbSVHsIzD`
**Status:** Ativo

Entrada de dados com 3 triggers diferentes.

**Triggers:**
1. **Telegram Trigger** - Entrada manual de noticias
2. **Schedule Trigger** - Scraping automatico via Apify
3. **Execute Workflow Trigger** - Chamado por outros workflows

**Funcionalidades:**
- Filtragem por canal
- Hash para deduplicacao (Crypto node)
- AI Agent (Claude) para sumarizacao inicial
- Armazenamento em Supabase

**Tabelas afetadas:** `raw_content`, `content_posts`

---

### WF2 - Blog Content Archiver (20 nodes)
**ID:** `LfU5ddiFTiDSrUSp`
**Status:** Ativo

Criacao de conteudo com AI em duas etapas.

```
Schedule Trigger → Date & Time → Code → Get many rows → Loop Over Items
                                                              │
                                                    ┌─────────┴─────────┐
                                                    ▼                   ▼
                                              No Operation        Code in JavaScript1
                                                    │                   │
                                                    ▼                   ▼
                                         Call '[BLOG] 3 DRAFT'    Edit Fields
                                                                        │
                                                                        ▼
                                                                   Get a row
                                                                        │
                                                                        ▼
                                                                   Edit Fields1
                                                                        │
                                                                        ▼
                                                                    Archiver (AI Agent)
                                                                        │
                                                                        ▼
                                                                    Rewriter (AI Agent)
                                                                        │
                                                                        ▼
                                                                  Code in JavaScript3
                                                                        │
                                                                        ▼
                                                              INSERT CONTENT POSTS
                                                                        │
                                                                        ▼
                                                            INSERT CONTENT METADATA
                                                                        │
                                                                        ▼
                                                            INSERT CONTENT WORKFLOW
                                                                        │
                                                                        ▼
                                                                  Update a row
```

**AI Agents:**
- **Archiver**: Cria artigo estruturado a partir do conteudo bruto
- **Rewriter**: Reescreve em formato jornalistico

**Modelo:** Claude (Anthropic)

**Tabelas afetadas:** `content_posts`, `content_metadata`, `content_workflow`

---

### WF3 - Draft Review (13 nodes)
**ID:** `J7G0HJYT2yqL3WQq`
**Status:** Ativo

Revisao humana via Telegram.

```
TRIGGER → DATA HORA → CALC DATAS BR → BUSCAR DRAFTS → CRIAR SESSAO → LOOP ITEMS
                                                                          │
                                                                ┌─────────┴─────────┐
                                                                ▼                   ▼
                                                           FIM LOOP           SALVAR SESSAO
                                                                │
                                                                ▼
                                                          BUSCAR POST 1
                                                                │
                                                                ▼
                                                        PREPARAR TELEGRAM
                                                                │
                                                                ▼
                                                         ENVIAR TELEGRAM
                                                                │
                                                                ▼
                                                         EXTRAIR MSG ID
                                                                │
                                                                ▼
                                                          SALVAR MSG ID
```

**Funcao:**
- Cria sessao de revisao
- Loop por cada draft pendente
- Envia preview formatado com botoes inline (Aprovar/Rejeitar/Feedback)
- Salva message_id para edicao posterior

**Tabelas afetadas:** `review_sessions`, `content_workflow`

---

### WF4 - Callback Drafts (26 nodes)
**ID:** `Eqj6uTE4pFizUsKH`
**Status:** Ativo

Hub central de processamento de callbacks do Telegram.

**Router para:**
- `callback_query` → Processar botoes
- `message` → WF4.5 (feedback textual)

**Acoes disponiveis:**
- `approve` → Aprovar post
- `reject` → Rejeitar post
- `feedback` → Solicitar feedback (chama WF4.5)
- `edit_*` → Quick edit (chama WF4.7)
- `next` → Proximo draft
- `done` → Finalizar sessao (chama WF6)

---

### WF4.5 - Feedback Capture (14 nodes)
**ID:** `QElqWkwrvoxGKDN4`
**Status:** Ativo

Captura feedback textual do usuario.

```
TRIGGER DO WF4 → VALIDAR FEEDBACK → E FEEDBACK? → BUSCAR SESSAO ATIVA → ENCONTROU SESSAO?
                                                                              │
                                                                              ▼
                                                                     PROCESSAR FEEDBACK
                                                                              │
                                                                              ▼
                                                                     SALVAR REVIEW NOTES
                                                                              │
                                                                              ▼
                                                                     PREPARAR DADOS WF5
                                                                              │
                                                                              ▼
                                                               EXECUTAR REVISION PROCESSOR (WF5)
                                                                              │
                                                                              ▼
                                                                     BUSCAR POST REVISADO
                                                                              │
                                                                              ▼
                                                               PREPARAR TELEGRAM REVISADO
                                                                              │
                                                                              ▼
                                                                      ENVIAR TELEGRAM
                                                                              │
                                                                              ▼
                                                                      EXTRAIR MSG ID
                                                                              │
                                                                              ▼
                                                                       SALVAR MSG ID
```

**Tabelas afetadas:** `content_workflow` (review_notes)

---

### WF4.6 - Quick Edit Capture (11 nodes)
**ID:** `UoQK3JSa2tzPHpxW`
**Status:** Ativo

Captura texto de edicao rapida via mensagem do Telegram.

```
TRIGGER MENSAGEM → BUSCAR SESSAO ATIVA → TEM SESSAO?
                                              │
                              ┌───────────────┴───────────────┐
                              ▼                               ▼
                         BUSCAR POST                  SEM SESSAO (IGNORAR)
                              │
                              ▼
                        VALIDAR INPUT
                              │
                              ▼
                        VALIDACAO OK?
                              │
                  ┌───────────┴───────────┐
                  ▼                       ▼
      ATUALIZAR SESSAO (PREVIEW)     ENVIAR ERROS
                  │
                  ▼
           FORMATAR PREVIEW
                  │
                  ▼
            ENVIAR PREVIEW
```

**Tabelas afetadas:** `edit_sessions`

---

### WF4.7 - Quick Edit Callbacks (24 nodes)
**ID:** `bKvqmScFWW9KK8ur`
**Status:** Ativo

Processa callbacks de edicao rapida.

**Menu de edicao:**
- Titulo (direto)
- Tags (direto)
- Conteudo (via AI - WF5)

**Acoes:**
- `qe_menu` → Mostrar menu
- `qe_title` / `qe_tags` / `qe_content` → Iniciar edicao
- `qe_confirm` → Confirmar edicao
- `qe_redo` → Refazer
- `qe_cancel` → Cancelar

**Tabelas afetadas:** `edit_sessions`, `content_posts`

---

### WF5 - Revision Processor (12 nodes)
**ID:** `5TuCwLZLlGdczwhU`
**Status:** Ativo

Revisao de conteudo com AI.

```
TRIGGER SINGLE POST → BUSCAR POST ESPECIFICO → PREPARAR PROMPT EDITOR
                                                        │
                                                        ▼
                                                AI AGENT EDITOR (Claude)
                                                        │
                                                        ▼
                                               PROCESSAR RESPOSTA AI
                                                        │
                                                        ▼
                                              ATUALIZAR CONTENT POSTS
                                                        │
                                                        ▼
                                            ATUALIZAR CONTENT METADATA
                                                        │
                                                        ▼
                                            ATUALIZAR WORKFLOW STATUS
                                                        │
                                                        ▼
                                              PREPARAR NOTIFICACAO
                                                        │
                                                        ▼
                                               ENVIAR NOTIFICACAO
```

**AI Agent:** Claude com ferramenta Think
**Funcao:** Aplica revisoes baseadas em feedback do usuario

**Tabelas afetadas:** `content_posts`, `content_metadata`, `content_workflow`

## Dependencias

- **Supabase**: Todas as tabelas de conteudo
- **Anthropic Claude**: WF2, WF5
- **Telegram Bot**: BlogDraftsBot

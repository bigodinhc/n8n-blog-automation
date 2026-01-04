# 03 - Social Pipeline

Pipeline de publicacao em redes sociais.

## Fluxo Geral

```
WF7 Social Media Factory → WF7.2 Image Callback → WF7.1 Social Callback
         │                         │                      │
    AI Content              Aprovar Imagem          Twitter Thread
    + Imagem                  ou Redo               LinkedIn (pendente)
                                                    Instagram (pendente)
```

## Workflows

### WF7 - Social Media Factory (25 nodes)
**ID:** `KkCUTo9KVfZkfZrE`
**Status:** Ativo

Geracao de conteudo para multiplas redes sociais.

```
TRIGGER SOCIAL MEDIA → EXTRAIR DADOS POST
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
         AI TWITTER                  AI PROMPT TWITTER IMAGE
              │                             │
              ▼                             ▼
        PARSEAR TWITTER              PREPARAR GEMINI TWITTER
              │                             │
              ▼                             ▼
         AI LINKEDIN               GERAR IMAGEM TWITTER
              │                             │
              ▼                             ▼
        PARSEAR LINKEDIN            UPLOAD TWITTER IMAGE
              │                             │
              ▼                             ▼
         AI INSTAGRAM              CONSTRUIR URL TWITTER
              │                             │
              ▼                             ▼
        PARSEAR INSTAGRAM                   │
              │                             │
              └──────────────┬──────────────┘
                             ▼
                       MERGE CONTEUDO
                             │
                             ▼
                      PREPARAR PREVIEW
                             │
                             ▼
                           If (tem imagem?)
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
     SALVAR SESSAO IMAGEM           SALVAR SESSAO SOCIAL
              │                             │
              ▼                             ▼
    ENVIAR IMAGEM TELEGRAM            ENVIAR TELEGRAM
              │                             │
              ▼                             ▼
   AGUARDAR APROVACAO IMAGEM         CONFIRMAR ENVIO
```

**AI Agents (Claude - modelo compartilhado):**
- **AI TWITTER**: Thread de 4 tweets (hook, contexto, brasil, CTA)
- **AI LINKEDIN**: Post profissional (estrutura formal)
- **AI INSTAGRAM**: Caption engajadora (emojis, hashtags)

**Geracao de imagem:**
- GPT-4.1-mini para prompt
- Gemini para imagem
- Upload para Supabase

**Tabelas afetadas:** `social_media_sessions`, `social_images`

---

### WF7.1 - Social Callback (28 nodes)
**ID:** `ZvWogMCqmetav8Fa`
**Status:** Ativo

Publicacao efetiva nas redes sociais.

```
TRIGGER SOCIAL CALLBACK → TIPO DE CALLBACK?
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
     EXTRAIR DADOS CALLBACK           EXECUTAR WF7.2 IMAGE
               │
               ▼
      RESPONDER CALLBACK
               │
               ▼
           CANCELOU?
               │
   ┌───────────┴───────────┐
   ▼                       ▼
ATUALIZAR CANCELADO   BUSCAR SESSAO
   │                       │
   ▼                       ▼
NOTIFICAR CANCELAMENTO PREPARAR PUBLICACAO
                           │
                           ▼
                    PUBLICAR TWITTER?
                           │
           ┌───────────────┴───────────────┐
           ▼                               ▼
     If (tem imagem?)                 SKIP TWITTER
           │                               │
   ┌───────┴───────┐                       │
   ▼               ▼                       │
BAIXAR IMAGEM  TWEET 1 HOOK               │
   │               │                       │
   ▼               ▼                       │
UPLOAD MEDIA   Edit Fields                 │
   │               │                       │
   ▼               ▼                       │
EXTRAIR ID    TWEET 2 CONTEXTO            │
   │               │                       │
   ▼               ▼                       │
TWEET 1 IMG   TWEET 3 BRASIL              │
   │               │                       │
   ▼               ▼                       │
EXTRAIR ID    TWEET 4 CTA                 │
   │               │                       │
   └───────┬───────┘                       │
           ▼                               │
     SALVAR TWITTER                        │
           │                               │
           ▼                               │
    RESULTADO TWITTER                      │
           │                               │
           └───────────────┬───────────────┘
                           ▼
                    PREPARAR RELATORIO
                           │
                           ▼
                    ATUALIZAR SESSAO
                           │
                           ▼
                    ENVIAR RELATORIO
```

**Twitter Thread:**
- Tweet 1: Hook chamativo (com ou sem imagem)
- Tweet 2: Contexto do mercado
- Tweet 3: Impacto no Brasil
- Tweet 4: CTA + link + hashtags

**APIs utilizadas:**
- Twitter API v2 para tweets
- Twitter Media Upload para imagens

**Status das redes:**
- Twitter: Ativo
- LinkedIn: Pendente (estrutura pronta)
- Instagram: Pendente (estrutura pronta)

**Tabelas afetadas:** `social_media_sessions`, `published_social`

---

### WF7.2 - Image Callback (24 nodes)
**ID:** `t4M4Qav7y3860Bje`
**Status:** Ativo

Gerencia aprovacao de imagem do Twitter.

```
TRIGGER IMAGE CALLBACK → EXTRAIR DADOS IMG → RESPONDER CALLBACK → QUAL ACAO?
                                                                      │
              ┌───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┐
              ▼                                                       ▼                                                       ▼
        BUSCAR SESSAO                                         BUSCAR SESSAO REDO                                    ATUALIZAR CANCELADO
              │                                                       │                                                       │
              ▼                                                       ▼                                                       ▼
       ATUALIZAR APROVADO                                        BUSCAR POST                                         NOTIFICAR CANCELADO
              │                                                       │
              ▼                                                       ▼
     PREPARAR PREVIEW TEXTO                                   NOTIFICAR GERANDO
              │                                                       │
              ▼                                                       ▼
      EDITAR MSG APROVADO                                        PREPARAR REDO
              │                                                       │
              ▼                                                       ▼
      ENVIAR PREVIEW TEXTO                               AI PROMPT NOVA IMAGEM (GPT-4.1-mini)
                                                                      │
                                                                      ▼
                                                              PREPARAR GEMINI REDO
                                                                      │
                                                                      ▼
                                                               GERAR IMAGEM REDO
                                                                      │
                                                                      ▼
                                                              UPLOAD IMAGEM REDO
                                                                      │
                                                                      ▼
                                                              CONSTRUIR URL REDO
                                                                      │
                                                                      ▼
                                                             ATUALIZAR SESSAO REDO
                                                                      │
                                                                      ▼
                                                              ENVIAR NOVA IMAGEM
                                                                      │
                                                                      ▼
                                                              DELETAR MSG ANTIGA
```

**Acoes disponiveis:**
- `social_img_approve` → Aprovar imagem, seguir para texto
- `social_img_redo` → Regenerar imagem
- `social_img_cancel` → Cancelar publicacao social

**Tabelas afetadas:** `social_media_sessions`, `social_images`

## Dependencias

- **Supabase**: Storage + tabelas
- **Anthropic Claude**: AI para conteudo
- **OpenAI GPT-4.1-mini**: Prompts de imagem
- **Google Gemini**: Geracao de imagem
- **Twitter API**: Publicacao de threads
- **Telegram Bot**: SocialMediaBot

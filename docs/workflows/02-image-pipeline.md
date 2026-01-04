# 02 - Image Pipeline

Pipeline de geracao e aprovacao de imagens.

## Fluxo Geral

```
WF6 Image Generator → WF6.5 Image Approval → WordPress Publish
                                   │
                                   ├──▶ Regenerar (volta para WF6)
                                   └──▶ Cancelar
```

## Workflows

### WF6 - Image Generator + Preview (18 nodes)
**ID:** `yr7VUG1VMi8o8fi9`
**Status:** Ativo

Geracao de imagem featured para o post.

```
TRIGGER PUBLICACAO → BUSCAR POSTS APROVADOS → TEM POSTS?
                                                   │
                                    ┌──────────────┴──────────────┐
                                    ▼                             ▼
                           PROCESSAR UM POR UM           NENHUM POST APROVADO
                                    │
                          ┌─────────┴─────────┐
                          ▼                   ▼
                    No Operation      PREPARAR DADOS POST
                                              │
                                              ▼
                                   AI GERAR PROMPT IMAGEM (GPT-4.1-mini)
                                              │
                                              ▼
                                   PREPARAR PROMPT GEMINI
                                              │
                                              ▼
                                   GERAR IMAGEM GEMINI
                                              │
                                              ▼
                                  UPLOAD SUPABASE STORAGE
                                              │
                                              ▼
                                   CONSTRUIR URL IMAGEM
                                              │
                                              ▼
                                   SALVAR EM POST_IMAGES
                                              │
                                              ▼
                                 PREPARAR PREVIEW TELEGRAM
                                              │
                                              ▼
                                 ENVIAR PREVIEW TELEGRAM
                                              │
                                              ▼
                                 ATUALIZAR STATUS AWAITING
                                              │
                                              ▼
                                   VERIFICAR MAIS POSTS
```

**AI Models:**
- **OpenAI GPT-4.1-mini**: Gera prompt descritivo para imagem
- **Google Gemini**: Gera imagem a partir do prompt

**Storage:** Supabase Storage (bucket: post-images)

**Tabelas afetadas:** `post_images`, `content_workflow`

---

### WF6.5 - Image Approval Handler (24 nodes)
**ID:** `vqW2Dt3FkbkQPHws`
**Status:** Ativo

Aprovacao de imagem e publicacao no WordPress.

```
TELEGRAM TRIGGER → PARSE CALLBACK DATA → ANSWER CALLBACK QUERY → QUAL ACAO?
                                                                      │
              ┌───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┐
              ▼                                                       ▼                                                       ▼
     BUSCAR DADOS PUBLISH                                  ATUALIZAR STATUS APPROVED                              ATUALIZAR STATUS CANCELLED
              │                                                       │                                                       │
              ▼                                                       ▼                                                       ▼
     BUSCAR IMAGEM APROVADA                                 DELETAR IMAGEM ANTIGA                                 ATUALIZAR IMAGEM REJECTED
              │                                                       │                                                       │
              ▼                                                       ▼                                                       ▼
    DOWNLOAD IMAGEM SUPABASE                                CHAMAR WF6 REGENERAR                                   NOTIFICAR CANCELADO
              │                                                       │
              ▼                                                       ▼
       PREPARAR UPLOAD WP                                    NOTIFICAR REGENERANDO
              │
              ▼
       UPLOAD IMAGEM WP
              │
              ▼
       DEFINIR ALT IMAGEM
              │
              ▼
      PREPARAR CONTEUDO WP
              │
              ▼
     PUBLICAR NO WORDPRESS
              │
              ▼
   ATUALIZAR IMAGEM PUBLISHED
              │
              ▼
    SALVAR PUBLISHED CONTENT
              │
              ▼
   ATUALIZAR STATUS PUBLISHED
              │
              ▼
      NOTIFICAR PUBLICADO
              │
              ▼
     CHAMAR SOCIAL MEDIA (WF7)
```

**Acoes disponiveis:**
- `img_publish` → Publicar no WordPress + chamar WF7 Social
- `img_regen` → Regenerar imagem (volta para WF6)
- `img_cancel` → Cancelar publicacao

**Integracao WordPress:**
- Upload de imagem via REST API
- Criacao de post com featured image
- Definicao de alt text para SEO

**Tabelas afetadas:** `post_images`, `published_content`, `content_workflow`

## Dependencias

- **Supabase**: Storage + tabelas
- **OpenAI**: GPT-4.1-mini para prompts
- **Google Gemini**: Geracao de imagem
- **WordPress**: REST API para publicacao
- **Telegram Bot**: BlogDraftsBot

# Blog System Automation - Minerals Trading Daily

---

## TRABALHO EM ANDAMENTO (Atualizado 2026-01-05)

### Contexto
Fluxo SEO implementado. Workflows renomeados para nova convencao `WF[XXX]_[tipo]_[descricao]`.

### O que ja foi feito

**Sessao 2026-01-04:**
- [x] WF002: Rewriter removido (economia 50% API)
- [x] WF006a `PREPARAR CONTEUDO WP`: Campos SEO adicionados
- [x] WF006a `PUBLICAR NO WORDPRESS`: Campos Rank Math adicionados
- [x] Supabase MCP configurado
- [x] WF005a SEO ENRICHMENT criado
- [x] WF005b SEO CALLBACK criado

**Sessao 2026-01-05 (Bugs SEO corrigidos):**
- [x] WF004, WF005a, WF005b: Multiplas correcoes de expressions e filters
- [x] WF005a `SALVAR MSG ID`: Substituido por Supabase Update
- [x] WF005b `BUSCAR POST`: Filtro por `seo_telegram_message_id`

**Sessao 2026-01-05 (Padronizacao):**
- [x] Criado `NAMING_CONVENTIONS.md` com diretrizes de nomenclatura
- [x] Criado `improvements/ROADMAP_FINAL.md` unificando v1 + v2
- [x] Renomeados 18 workflows para nova convencao

### PROXIMOS PASSOS (ROADMAP FASE 0)
1. **Testar fluxo SEO completo**: Aprovar draft e verificar publicacao
2. **Instalar Rank Math** no WordPress
3. **Ativar WF000_error_handler**: Error Trigger + alertas Telegram
4. **Implementar idempotencia**: run_id antes de publicar

### Tarefas Pendentes (Qualidade)
| Prioridade | Tarefa | Nota |
|------------|--------|------|
| Alta | Melhorar prompt LinkedIn (WF007) | 2/10 |
| Alta | Melhorar prompt Instagram (WF007) | 2/10 |
| Media | Melhorar prompt Newsletter (WF008) | 3/10 |

### Arquivos de Referencia
- Roadmap: `improvements/ROADMAP_FINAL.md`
- Nomenclatura: `NAMING_CONVENTIONS.md`
- Backlog: `docs/BACKLOG.md`

---

## Visao Geral do Projeto

Sistema de automacao de blog para o site mineralstradingdaily.com.br usando n8n workflows.
O sistema processa feeds RSS, gera artigos com AI, cria imagens, e publica no WordPress.

## Estrutura do Projeto

```
n8n-full/
├── docs/                       # Documentacao
│   ├── ARCHITECTURE.md         # Arquitetura detalhada
│   ├── BACKLOG.md              # Backlog de tarefas (PRINCIPAL)
│   ├── SEO_ANALYSIS.md         # Analise SEO
│   └── workflows/              # Documentacao por pipeline
├── workflows/                  # JSONs dos workflows n8n
│   ├── 00-utils/
│   ├── 01-content-pipeline/
│   ├── 02-image-pipeline/
│   ├── 03-social-pipeline/
│   └── 04-newsletter-pipeline/
├── database/
│   └── schema.sql
├── prompts/                    # Prompts de AI extraidos
│   ├── archiver.md             # WF2 (4/10)
│   ├── rewriter.md             # WF2 (3/10)
│   ├── editor.md               # WF5 (9/10) - MODELO
│   ├── twitter.md              # WF7 (7/10)
│   ├── linkedin.md             # WF7 (2/10) - CRITICO
│   ├── instagram.md            # WF7 (2/10) - CRITICO
│   └── newsletter.md           # WF8 (3/10)
├── scripts/
│   ├── export_workflows.sh
│   └── import_workflows.sh
├── .gitignore
├── LICENSE
├── CLAUDE.md                   # Este arquivo
└── README.md
```

## IDs dos Workflows Principais

| Workflow | ID | Status | Funcao |
|----------|-----|--------|--------|
| WF000_error_handler | dxVlQYOyMQ4xxaHt | Ativo | Tratamento de erros global |
| WF001_content_feed_ingestion | TgZ3HSnbbSVHsIzD | Ativo | Ingestao (RSS, Telegram, Apify) |
| WF002_content_ai_generator | LfU5ddiFTiDSrUSp | Ativo | AI gera artigo |
| WF003_content_draft_preview | J7G0HJYT2yqL3WQq | Ativo | Preview Telegram |
| WF004_content_approval_callback | Eqj6uTE4pFizUsKH | Inativo | Processa aprovacao |
| WF004a_content_feedback_capture | QElqWkwrvoxGKDN4 | Ativo | Captura feedback |
| WF004b_content_quick_edit_capture | UoQK3JSa2tzPHpxW | Ativo | Captura edicoes |
| WF004c_content_quick_edit_callback | bKvqmScFWW9KK8ur | Ativo | Processa edicoes |
| WF005_content_revision_processor | 5TuCwLZLlGdczwhU | Ativo | AI aplica revisoes |
| WF005a_seo_enrichment | MT3TXgKk6e9K5RHj | Ativo | Enriquece SEO com Perplexity+AI |
| WF005b_seo_approval_callback | Zkibw3SPFF4cZtxG | Ativo | Processa aprovacao SEO |
| WF006_image_generator | yr7VUG1VMi8o8fi9 | Ativo | Gera imagem (Gemini) |
| WF006a_image_approval_publish | vqW2Dt3FkbkQPHws | Ativo | Publica no WordPress |
| WF007_social_content_factory | KkCUTo9KVfZkfZrE | Ativo | AI gera posts sociais |
| WF007a_social_publish_callback | ZvWogMCqmetav8Fa | Ativo | Publica nas redes |
| WF007b_social_image_callback | t4M4Qav7y3860Bje | Ativo | Aprova imagens sociais |
| WF008_newsletter_generator | gMknz5KYcdJuu1Eg | Ativo | Gera newsletter |
| WF008a_newsletter_send_callback | e88ZJNv0ffG8nILx | Ativo | Processa envio |

## Banco de Dados (Supabase)

### Projeto
- **ID:** `pbhvhfahcvgmgjvuhwuk`
- **Regiao:** us-east-2
- **Credential ID:** `04rdCJqTixOtwak5` (nome: "blogging")

### Tabelas Principais
- `content_posts` - Posts do blog
- `content_metadata` - Metadados (tags, SEO)
- `content_workflow` - Estado do workflow por post
- `post_images` - Imagens geradas
- `published_content` - Registro de publicacoes
- `social_media_sessions` - Sessoes de publicacao social
- `newsletter_history` - Historico de newsletters
- `iron_ore_prices` - Precos Platts IODEX (~11.500 registros)

## Telegram Bots

| Bot | Chat ID | Uso |
|-----|---------|-----|
| BlogDraftsBot | 8375309778 | WF3, WF4, WF4.5, WF5, WF8 |
| QuickEditBot | 8375309778 | WF4.7 |
| SocialMediaBot | 8375309778 | WF7, WF7.1, WF7.2 |

### Formato de Callback Data
**IMPORTANTE**: Telegram limita callback_data a 64 bytes!

Formato atual (corrigido 2025-12-30):
```
pub_IMAGE_UUID    # Publicar (40 chars)
reg_IMAGE_UUID    # Regenerar
can_IMAGE_UUID    # Cancelar
```

## Qualidade dos Prompts

Ver `prompts/README.md` para analise completa.

| Prompt | Nota | Status |
|--------|------|--------|
| Editor (WF5) | 9/10 | MODELO A SEGUIR |
| Archiver (WF2) | 7/10 | Atualizado 2026-01-04 |
| Twitter (WF7) | 7/10 | Bom |
| Newsletter (WF8) | 3/10 | Precisa melhoria |
| LinkedIn (WF7) | 2/10 | CRITICO |
| Instagram (WF7) | 2/10 | CRITICO |
| ~~Rewriter (WF2)~~ | - | REMOVIDO 2026-01-04 |

## Comandos MCP Uteis

```bash
# Listar workflows
mcp__n8n-mcp__n8n_list_workflows

# Ver estrutura
mcp__n8n-mcp__n8n_get_workflow id="WORKFLOW_ID" mode="structure"

# Validar workflow
mcp__n8n-mcp__n8n_validate_workflow id="WORKFLOW_ID"

# Atualizar node
mcp__n8n-mcp__n8n_update_partial_workflow id="ID" operations=[...]
```

## Documentacao

- `docs/ARCHITECTURE.md` - Arquitetura tecnica completa
- `docs/BACKLOG.md` - **PRINCIPAL** - Tarefas, prioridades, analise de prompts
- `docs/SEO_ANALYSIS.md` - Analise SEO do site
- `docs/workflows/` - Documentacao detalhada de cada pipeline
- `prompts/` - Prompts de AI com notas e sugestoes de melhoria

## Notas Importantes

1. **Consultar docs/BACKLOG.md** para tarefas pendentes e prioridades
2. **Prompts criticos:** LinkedIn e Instagram precisam de melhoria urgente
3. **Modelo de prompt:** Usar WF5 Editor como referencia
4. **Validacao:** Warnings de typeVersion sao normais apos updates
5. **Callbacks Telegram:** Limite de 64 bytes - usar formato curto
6. **Nomenclatura:** Seguir `NAMING_CONVENTIONS.md` para novos workflows/arquivos
7. **Roadmap:** Ver `improvements/ROADMAP_FINAL.md` para proximos passos

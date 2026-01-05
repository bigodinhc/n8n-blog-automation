# Blog System Automation - Minerals Trading Daily

---

## ⚡ TRABALHO EM ANDAMENTO (Atualizado 2026-01-05)

### Contexto
Fluxo SEO implementado e funcionando. Pendente apenas teste de integracao completo.

### O que ja foi feito

**Sessao 2026-01-04:**
- [x] WF2: Rewriter removido (economia 50% API)
- [x] WF6.5 `PREPARAR CONTEUDO WP`: Campos SEO adicionados
- [x] WF6.5 `PUBLICAR NO WORDPRESS`: Campos Rank Math adicionados
- [x] Supabase MCP configurado
- [x] WF5.5 SEO ENRICHMENT criado
- [x] WF5.6 SEO CALLBACK criado

**Sessao 2026-01-05 (8 bugs corrigidos):**
- [x] WF4 `FOI APROVADO?`: Expression corrigida
- [x] WF4 `CHAMAR WF5.5 SEO`: post_id expression corrigida
- [x] WF4: Adicionado `VERIFICAR APROVACAO` node (resolve timeout Telegram)
- [x] WF5.5 `BUSCAR POST APROVADO`: Adicionado `condition: "eq"`
- [x] WF5.5 `ATUALIZAR SUPABASE`: Adicionado `condition: "eq"`
- [x] WF5.5: Adicionado node `PREPARAR PROMPT SEO`
- [x] WF5.5 `ATUALIZAR SUPABASE`: Adicionado fieldsUi config
- [x] WF5.5 `ATUALIZAR SUPABASE`: Corrigido `fieldId` (era `fieldName`)

### PROXIMO PASSO IMEDIATO
1. **Testar fluxo completo**: Aprovar um draft e verificar se SEO e salvo
2. **Ajustar WF5.6** se necessario apos teste
3. **Usuario instala Rank Math** no WordPress

### Tarefas Pendentes (apos SEO)
| Prioridade | Tarefa | Nota |
|------------|--------|------|
| Alta | Melhorar prompt LinkedIn (WF7) | 2/10 |
| Alta | Melhorar prompt Instagram (WF7) | 2/10 |
| Media | Melhorar prompt Newsletter (WF8) | 3/10 |

### Arquivos de Referencia
- Plano atual: `/Users/hanna/.claude/plans/nifty-kindling-marble.md`
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
| WF0 Error Handler | dxVlQYOyMQ4xxaHt | INATIVO | Tratamento de erros global |
| WF1 Feed Supabase | TgZ3HSnbbSVHsIzD | Ativo | Ingestao (RSS, Telegram, Apify) |
| WF2 Content Archiver | LfU5ddiFTiDSrUSp | Ativo | AI gera artigo |
| WF3 Draft Review | J7G0HJYT2yqL3WQq | Ativo | Preview Telegram |
| WF4 Callback Drafts | Eqj6uTE4pFizUsKH | Ativo | Processa aprovacao |
| WF4.5 Feedback Capture | QElqWkwrvoxGKDN4 | Ativo | Captura feedback |
| WF4.6 Quick Edit Capture | UoQK3JSa2tzPHpxW | Ativo | Captura edicoes |
| WF4.7 Quick Edit Callbacks | bKvqmScFWW9KK8ur | Ativo | Processa edicoes |
| WF5 Revision Processor | 5TuCwLZLlGdczwhU | Ativo | AI aplica revisoes |
| WF5.5 SEO Enrichment | MT3TXgKk6e9K5RHj | Ativo | Enriquece SEO com Perplexity+AI |
| WF5.6 SEO Callback | Zkibw3SPFF4cZtxG | Ativo | Processa aprovacao SEO |
| WF6 Image Generator | yr7VUG1VMi8o8fi9 | Ativo | Gera imagem (Gemini) |
| WF6.5 Image Approval | vqW2Dt3FkbkQPHws | Ativo | Publica no WordPress |
| WF7 Social Media Factory | KkCUTo9KVfZkfZrE | Ativo | AI gera posts sociais |
| WF7.1 Social Callback | ZvWogMCqmetav8Fa | Ativo | Publica nas redes |
| WF7.2 Image Callback | t4M4Qav7y3860Bje | Ativo | Aprova imagens sociais |
| WF8 Newsletter Generator | gMknz5KYcdJuu1Eg | Ativo | Gera newsletter |
| WF8.1 Newsletter Callback | e88ZJNv0ffG8nILx | Ativo | Processa envio |

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
5. **Error Handler:** WF0 esta INATIVO - considerar ativar
6. **Callbacks Telegram:** Limite de 64 bytes - usar formato curto

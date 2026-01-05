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

**Sessao 2026-01-05 (Baltic Exchange):**
- [x] Criada pasta `baltic/` com estrutura completa
- [x] Criado prompt `baltic/prompts/baltic_data_extractor.md` para Claude Vision
- [x] Criada tabela `baltic_indices` no Supabase
- [x] WF010: Refatorado workflow para usar Claude Vision

**Sessao 2026-01-05 (Baltic Trigger Optimization):**
- [x] WF010: Removido TRIGGER OUTLOOK (polling problematico)
- [x] WF010: Adicionado TRIGGER SCHEDULE (cron `0,30 9,10 * * 1-5`)
- [x] WF010: Horarios de execucao: 9:00, 9:30, 10:00, 10:30 seg-sex
- [x] WF010: DEDUPE configurado para evitar duplicatas por email ID
- [x] WF010: Template WhatsApp atualizado com rotas C2, C3, C5, C7, C8
- [x] WF010: Emojis melhorados para tipos de navio (🔷🔶🔸▫️)
- [x] Confirmado UNIQUE constraint em `report_date` (proteção duplicatas)

**Sessao 2026-01-05 (Reorganizacao DB):**
- [x] Removidas 3 tabelas obsoletas (blog_content, blog_content_backup, social_media_queue)
- [x] Renomeadas 17 tabelas com prefixos numericos por dominio
- [x] Recriada view vw_blog_drafts com novos nomes
- [x] Atualizados todos os workflows n8n (WF000-WF008a)

**Sessao 2026-01-05 (Bot SEO + Correcoes WF007):**
- [x] Criado bot Telegram dedicado `MT_SEO_bot` para aprovacoes SEO
- [x] WF005a: Atualizado para usar novo bot (token na URL HTTP)
- [x] WF005b: Atualizado trigger e nodes Telegram para novo bot
- [x] WF005b: Corrigidos nodes Supabase (BUSCAR POST, ATUALIZAR APROVADO/REJEITADO)
- [x] WF005b: Corrigidos nodes Telegram (RESPONDER APROVADO/REJEITADO com queryId)
- [x] WF007: Corrigido AI TWITTER - adicionado `=` no campo text para avaliar expressoes
- [x] Fluxo SEO testado e funcionando end-to-end

### PROXIMOS PASSOS (ROADMAP FASE 0)
1. ~~**Testar fluxo SEO completo**: Aprovar draft e verificar publicacao~~ CONCLUIDO
2. **Instalar Rank Math** no WordPress
3. **Implementar idempotencia**: run_id antes de publicar
4. **DB Hygiene**: Configurar retencao de execucoes

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
n8n-blog-automation/
├── baltic/                     # Modulo Baltic Exchange (NOVO)
│   ├── README.md               # Documentacao do modulo
│   ├── prompts/                # Prompts para extracao
│   │   └── baltic_data_extractor.md
│   ├── docs/
│   │   └── INTEGRATION.md      # Detalhes tecnicos
│   └── samples/                # PDFs de exemplo
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
│   ├── archiver.md             # WF2 (7/10)
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
| WF010_baltic_email_ingestion | 4kThouFXX7FP9XnX | Ativo | Coleta indices Baltic Exchange |

## Banco de Dados (Supabase)

### Projeto
- **ID:** `pbhvhfahcvgmgjvuhwuk`
- **Regiao:** us-east-2
- **Credential ID:** `04rdCJqTixOtwak5` (nome: "blogging")

### Tabelas (Reorganizadas 2026-01-05)

**Prefixos por dominio:**
- `01_ing_*` - Ingestao
- `02_cnt_*` - Conteudo
- `03_pub_*` - Publicacao
- `04_soc_*` - Social
- `05_news_*` - Newsletter
- `06_ses_*` - Sessoes
- `07_mkt_*` - Market Data
- `08_sys_*` - Sistema

| Tabela | Descricao |
|--------|-----------|
| `01_ing_raw_inputs` | Entradas RSS/Telegram/Apify |
| `01_ing_market_intelligence` | Dados de mercado extraidos |
| `02_cnt_posts` | Posts do blog (PRINCIPAL) |
| `02_cnt_metadata` | Metadados SEO, tags |
| `02_cnt_workflow` | Estado do pipeline por post |
| `02_cnt_images` | Imagens geradas |
| `03_pub_content` | Registro de publicacoes WP |
| `04_soc_sessions` | Sessoes de publicacao social |
| `05_news_subscribers` | Assinantes da newsletter |
| `05_news_history` | Historico de newsletters |
| `05_news_sessions` | Sessoes de envio |
| `05_news_send_log` | Log de envios |
| `06_ses_feedback` | Feedback de revisao |
| `06_ses_edit` | Edicoes rapidas |
| `07_mkt_iron_ore_prices` | Precos Platts IODEX (~11.500 registros) |
| `07_mkt_baltic_indices` | Indices Baltic Exchange (BDI, Capesize, etc.) |
| `07_mkt_baltic_routes` | Rotas detalhadas Baltic (C2, C3, C5, C7, C8, etc.) |
| `08_sys_errors` | Erros do sistema (WF000) |

**View:** `vw_blog_drafts` - Join de posts + metadata + workflow

## Telegram Bots

| Bot | Chat ID | Uso |
|-----|---------|-----|
| BlogDraftsBot | 8375309778 | WF3, WF4, WF4.5, WF5, WF8 |
| QuickEditBot | 8375309778 | WF4.7 |
| SocialMediaBot | 8375309778 | WF7, WF7.1, WF7.2 |
| MT_SEO_bot | 8375309778 | WF005a, WF005b (aprovacao SEO) |

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
8. **Baltic Exchange:** Ver `baltic/README.md` para documentacao do modulo de frete maritimo
9. **Expressoes n8n:** Campos com `{{ $json.xxx }}` DEVEM comecar com `=` para serem avaliados

## Troubleshooting Comum

### AI Agent nao recebe dados (pede input)
**Causa:** Campo `text` do AI Agent nao comeca com `=`
**Solucao:** Adicionar `=` no inicio do campo text
```
Antes: "Crie uma thread sobre {{ $json.title }}"
Depois: "=Crie uma thread sobre {{ $json.title }}"
```

### Callback Telegram nao funciona
**Causa:** Workflow de callback inativo ou credential errada
**Solucao:**
1. Verificar se workflow esta ativo
2. Verificar se credential do bot esta correta no trigger
3. Verificar se `queryId` esta configurado nos nodes de resposta

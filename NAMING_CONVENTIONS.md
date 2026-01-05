# Diretrizes de Nomenclatura - Blog Automation

**Data:** 2026-01-05
**Versao:** 1.0
**Projeto:** Minerals Trading Daily

---

## Por Que Seguir Convencoes

- **Consistencia:** Facilita encontrar e entender componentes
- **Manutencao:** Reduz tempo de debug e onboarding
- **Colaboracao:** Todos falam a mesma lingua
- **Automacao:** Permite scripts e buscas padronizadas

---

## 1. Workflows n8n

### Formato
```
WF[XXX]_[tipo]_[descricao]
```

### Componentes
| Parte | Descricao | Exemplo |
|-------|-----------|---------|
| `WF` | Prefixo fixo (workflow) | `WF` |
| `[XXX]` | ID numerico com zero-padding | `001`, `005`, `008` |
| `[a/b/c]` | Sufixo para subworkflows | `005a`, `007b` |
| `[tipo]` | Categoria do workflow | `content`, `social` |
| `[descricao]` | O que faz (snake_case) | `feed_ingestion` |

### Tipos Validos
| Tipo | Descricao | Exemplos |
|------|-----------|----------|
| `error` | Tratamento de erros | `WF000_error_handler` |
| `content` | Pipeline de conteudo | `WF001_content_feed_ingestion` |
| `seo` | Otimizacao SEO | `WF005a_seo_enrichment` |
| `image` | Geracao de imagens | `WF006_image_generator` |
| `social` | Redes sociais | `WF007_social_content_factory` |
| `newsletter` | Email marketing | `WF008_newsletter_generator` |

### Exemplos do Projeto
```
WF000_error_handler
WF001_content_feed_ingestion
WF002_content_ai_generator
WF003_content_draft_preview
WF004_content_approval_callback
WF004a_content_feedback_capture
WF004b_content_quick_edit_capture
WF004c_content_quick_edit_callback
WF005_content_revision_processor
WF005a_seo_enrichment
WF005b_seo_approval_callback
WF006_image_generator
WF006a_image_approval_publish
WF007_social_content_factory
WF007a_social_publish_callback
WF007b_social_image_callback
WF008_newsletter_generator
WF008a_newsletter_send_callback
```

### Evitar
- Espacos no nome (`WF001 content feed` -> `WF001_content_feed`)
- Prefixos antigos (`[BLOG] 1 FEED` -> `WF001_content_feed`)
- Numeros sem padding (`WF1` -> `WF001`)
- CamelCase (`WF001_ContentFeed` -> `WF001_content_feed`)

---

## 2. Nodes n8n

### Formato
```
VERBO OBJETO
```

Usar **UPPERCASE** para visibilidade no canvas.

### Verbos Comuns
| Verbo | Uso | Exemplo |
|-------|-----|---------|
| `BUSCAR` | Ler dados (SELECT) | `BUSCAR POST APROVADO` |
| `ATUALIZAR` | Modificar dados (UPDATE) | `ATUALIZAR SUPABASE` |
| `ENVIAR` | Notificacoes/APIs | `ENVIAR SEO TELEGRAM` |
| `PROCESSAR` | Transformacoes | `PROCESSAR CALLBACK` |
| `VERIFICAR` | Condicoes (IF) | `VERIFICAR APROVACAO` |
| `GERAR` | Criar conteudo | `GERAR IMAGEM AI` |
| `CHAMAR` | Invocar subworkflow | `CHAMAR WF006 IMAGEM` |
| `SALVAR` | Persistir dados | `SALVAR MSG ID` |

### Exemplos do Projeto
```
TRIGGER
BUSCAR POST APROVADO
PERPLEXITY KEYWORDS
PREPARAR PROMPT SEO
AI SEO OPTIMIZER
PROCESSAR OUTPUT
ATUALIZAR SUPABASE
ENVIAR SEO TELEGRAM
SALVAR MSG ID
FOI APROVADO?
CHAMAR WF006 IMAGEM
```

### Evitar
- Nomes genericos: `node1`, `function`, `HTTP Request`
- Placeholders: `TODO_FIX_THIS`, `TEMP`
- Sem contexto: `request`, `code`

---

## 3. Tabelas Supabase

### Formato
```
snake_case
```

Usar nomes descritivos, consistentes em singular/plural.

### Exemplos do Projeto
| Tabela | Descricao |
|--------|-----------|
| `content_posts` | Posts do blog |
| `content_metadata` | Metadados SEO |
| `content_workflow` | Estado do pipeline por post |
| `post_images` | Imagens geradas |
| `published_content` | Registro de publicacoes |
| `social_media_sessions` | Sessoes de publicacao social |
| `newsletter_history` | Historico de newsletters |
| `iron_ore_prices` | Precos Platts IODEX |

### Evitar
- CamelCase: `ContentPosts` -> `content_posts`
- Prefixos desnecessarios: `tbl_posts` -> `posts`
- Abreviacoes confusas: `cnt_psts` -> `content_posts`

---

## 4. Colunas Supabase

### Formato
```
snake_case
```

### Convencoes de Sufixo
| Sufixo | Uso | Exemplo |
|--------|-----|---------|
| `_id` | Foreign keys | `post_id`, `author_id` |
| `_at` | Timestamps | `created_at`, `approved_at` |
| `is_` | Booleanos (prefixo) | `is_published`, `is_active` |
| `_count` | Contadores | `view_count`, `like_count` |
| `_url` | URLs | `image_url`, `source_url` |
| `_status` | Estados | `seo_status`, `workflow_status` |

### Exemplos do Projeto
```sql
-- Timestamps
created_at, updated_at, published_at
seo_approved_at, seo_enriched_at

-- Foreign Keys
post_id, author_id, image_id

-- Booleanos
is_published, is_active, is_verified

-- Especificos
seo_telegram_message_id
focus_keyword
meta_title
meta_description
secondary_keywords
```

### Evitar
- camelCase: `createdAt` -> `created_at`
- Inconsistencia: `creation_date` vs `created_at`
- Ambiguidade: `price` -> `price_usd`, `price_brl`

---

## 5. Arquivos

### Por Tipo
| Tipo | Formato | Exemplo |
|------|---------|---------|
| Documentacao | `UPPERCASE.md` | `CLAUDE.md`, `ROADMAP.md` |
| Codigo TS/JS | `kebab-case.ts` | `article.service.ts` |
| SQL Migrations | `NNN_descricao.sql` | `001_create_tables.sql` |
| JSON Workflows | `WF[XXX]_nome.json` | `WF001_content_feed.json` |
| Prompts | `lowercase.md` | `editor.md`, `linkedin.md` |
| Scripts | `snake_case.sh` | `export_workflows.sh` |

### Estrutura de Pastas
```
n8n-blog-automation/
|-- docs/                    # Documentacao
|   |-- ARCHITECTURE.md
|   |-- BACKLOG.md
|   `-- workflows/
|-- workflows/               # JSONs dos workflows
|   |-- 00-utils/
|   |-- 01-content-pipeline/
|   |-- 02-image-pipeline/
|   `-- 03-social-pipeline/
|-- prompts/                 # Prompts de AI
|-- database/                # SQL
|   `-- schema.sql
|-- scripts/                 # Scripts shell
|-- improvements/            # Pesquisas e roadmaps
|-- CLAUDE.md
|-- NAMING_CONVENTIONS.md
`-- README.md
```

---

## 6. Variaveis e Funcoes (Codigo)

### Formato
| Tipo | Formato | Exemplo |
|------|---------|---------|
| Variaveis | `camelCase` | `postId`, `isPublished` |
| Funcoes | `camelCase` | `fetchCommodityPrices()` |
| Constantes | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `API_URL` |
| Classes | `PascalCase` | `ArticleService` |

### Exemplos
```javascript
// Variaveis
const postId = '123';
const isPublished = true;
const seoData = {};

// Constantes
const MAX_RETRIES = 3;
const API_TIMEOUT_MS = 30000;

// Funcoes
async function fetchCommodityPrices() { }
function formatDateAsISO(date) { }

// Classes
class ArticleService { }
class CommodityPriceParser { }
```

---

## 7. Callbacks Telegram

### Formato
```
[acao]_[id_truncado]
```

**IMPORTANTE:** Telegram limita callback_data a **64 bytes**!

### Exemplos
```
pub_IMAGE_UUID    # Publicar (40 chars max)
reg_IMAGE_UUID    # Regenerar
can_IMAGE_UUID    # Cancelar
seoa_POST_ID      # SEO Aprovado
seor_POST_ID      # SEO Rejeitado
```

### Evitar
- IDs completos sem truncar
- Prefixos longos
- Caracteres especiais

---

## 8. Checklist Rapido

Antes de criar/modificar qualquer elemento:

### Workflow
- [ ] Formato: `WF[XXX]_[tipo]_[descricao]`?
- [ ] Tipo valido: error, content, seo, image, social, newsletter?
- [ ] Zero-padding: `WF001` nao `WF1`?
- [ ] snake_case na descricao?

### Node
- [ ] Formato: `VERBO OBJETO`?
- [ ] UPPERCASE?
- [ ] Verbo adequado: BUSCAR, ATUALIZAR, ENVIAR, etc?

### Tabela Supabase
- [ ] snake_case?
- [ ] Nome descritivo?
- [ ] Consistente com outras tabelas?

### Coluna Supabase
- [ ] snake_case?
- [ ] Sufixo correto: `_at`, `_id`, `is_`, `_count`?
- [ ] Nao ambiguo?

### Arquivo
- [ ] Segue padrao do tipo?
- [ ] Esta na pasta correta?

### Variavel/Funcao
- [ ] camelCase para variaveis/funcoes?
- [ ] UPPER_SNAKE_CASE para constantes?
- [ ] PascalCase para classes?

---

## Historico

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 1.0 | Criacao inicial |

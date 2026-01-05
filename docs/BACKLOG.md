# BACKLOG - Blog System Automation

> **Projeto:** Minerals Trading Daily
> **Ultima Atualizacao:** 2026-01-04
> **Consolidado de:** IMPROVEMENT_SUGGESTIONS.md, PROMPT_IMPROVEMENTS_PLAN.md, QUICK_WINS.md

---

## Indice

1. [Concluido](#-concluido)
2. [Pendente - Critico](#-pendente---critico)
3. [Pendente - Alto](#-pendente---alto)
4. [Pendente - Medio](#-pendente---medio)
5. [Backlog Futuro](#-backlog-futuro)
6. [Analise de Prompts](#-analise-de-prompts)
7. [Referencia Rapida](#-referencia-rapida)

---

## ✅ CONCLUIDO

### Bugs Corrigidos (Sessao 29-30/12/2025)

| Item | Workflow | Descricao |
|------|----------|-----------|
| ✅ | WF6.5 | Switch Node "QUAL ACAO?" com condicoes vazias |
| ✅ | WF6.5 | Filtro de imagem incorreto (buscava por post_id sem status) |
| ✅ | WF6.5 | Regeneracao nao passava post_id para WF6 |
| ✅ | WF7 | Gemini "undefined.find()" - faltava cachedResultName |
| ✅ | WF6/WF6.5 | callback_data excedendo 64 bytes do Telegram |

### Workflows Ativos

| Item | Workflow | Status |
|------|----------|--------|
| ✅ | WF0 Error Handler | Ativo (verificar se funcionando) |
| ✅ | WF8.1 Newsletter Callback | Ativo |

### Otimizacoes (Sessao 04/01/2026)

| Item | Workflow | Descricao |
|------|----------|-----------|
| ✅ | WF2 | Removido node Rewriter redundante (-50% custo API) |
| ✅ | WF6.5 | Node PREPARAR CONTEUDO WP: campos SEO adicionados |
| ✅ | WF6.5 | Node PUBLICAR NO WORDPRESS: campos Rank Math adicionados |

### Infraestrutura (Sessao 04/01/2026)

| Item | Descricao |
|------|-----------|
| ✅ | Supabase MCP configurado para Claude Code |

---

## 🔴 EM ANDAMENTO - SEO

### Implementacao SEO (Bloqueado)

**Status:** Aguardando correcao da view Supabase

| Etapa | Status | Descricao |
|-------|--------|-----------|
| WF6.5 PREPARAR CONTEUDO WP | ✅ | Campos SEO extraidos |
| WF6.5 PUBLICAR NO WORDPRESS | ✅ | Campos Rank Math enviados |
| View vw_blog_drafts | ❌ BLOQUEADO | Precisa JOIN com content_metadata |
| Instalar Rank Math | ⏳ PENDENTE | Usuario instala no WordPress |

**Proximo passo:** Usar Supabase MCP para ver estrutura das tabelas e criar view correta

**Campos Rank Math a enviar:**
- `meta[rank_math_title]` <- meta_title
- `meta[rank_math_description]` <- meta_description
- `meta[rank_math_focus_keyword]` <- primary_keyword (ou primeira tag)

---

## 🔴 PENDENTE - CRITICO

### 1. Testar Fluxos de Imagem Corrigidos

**Status:** AGUARDANDO TESTE

**Workflows:** WF6, WF6.5

**O que testar:**
- [ ] Fluxo de publicacao normal (clicar "Publicar")
- [ ] Fluxo de regeneracao (clicar "Nova Imagem")
- [ ] Fluxo de cancelamento (clicar "Cancelar")
- [ ] Verificar se imagem publicada = imagem aprovada

**Impacto:** Sistema de imagens pode estar quebrado sem saber.

---

### 2. Melhorar Prompt WF7 LinkedIn

**Workflow:** `KkCUTo9KVfZkfZrE` | Node: `AI LINKEDIN`

**Problema Atual:**
```
System Message: "Voce e copywriter de LinkedIn. Responda SOMENTE com JSON puro..."
```
Apenas 1 linha! Sem persona, sem tom, sem exemplos.

**Nota Atual:** 2/10

**Solucao:**
```
Voce e o head de comunicacao corporativa da Bloomberg Commodities Brasil.
Seu publico: C-level, traders institucionais, analistas de mercado.

TOM:
- Profissional e analitico
- Dados sempre com fonte
- Sem emojis excessivos (max 2)
- Estrutura: Hook → Analise → Insight → CTA

EXEMPLO:
INPUT: "IODEX cai 3% apos China reduzir importacoes"
OUTPUT: "A reducao de 15% nas importacoes chinesas sinaliza uma mudanca estrutural...
[3 paragrafos de analise]
Link para analise completa: [URL]
#MinerioFerro #Commodities"
```

**Esforco:** 1 hora

---

### 3. Melhorar Prompt WF7 Instagram

**Workflow:** `KkCUTo9KVfZkfZrE` | Node: `AI INSTAGRAM`

**Problema Atual:**
```
System Message: "Voce e copywriter de Instagram. Responda SOMENTE com JSON puro..."
```
Mesmo problema do LinkedIn - sem persona.

**Nota Atual:** 2/10

**Solucao:**
```
Voce e social media manager especializado em B2B industrial no Instagram.
Seu publico: profissionais jovens do setor, estudantes, interessados em commodities.

TOM:
- Visual e engajador
- Emojis estrategicos como marcadores
- Hashtags relevantes (15-20)
- CTA: "Salve esse post" ou "Link na bio"

EXEMPLO:
INPUT: "Vale aumenta producao em Carajas"
OUTPUT: "🏭 RECORDE em Carajas!

⛏️ Producao +12% no trimestre
📈 Meta 2024 superada
🌍 Brasil lidera exportacao global

Salve esse post para acompanhar o mercado! 👆

#minerio #ironore #vale #carajas #commodities #mining..."
```

**Esforco:** 1 hora

---

### 4. Melhorar Prompt WF8 Newsletter

**Workflow:** `gMknz5KYcdJuu1Eg` | Node: `AI Agent`

**Problema Atual:**
```
"Voce e o editor-chefe da newsletter..."
"Gere a newsletter seguindo EXATAMENTE esta estrutura em formato JSON:
- resumo_executivo (2-3 paragrafos)
- destaques (array de 3-5 strings)
..."
```
Generico demais. Sem tom definido, sem exemplos.

**Nota Atual:** 3/10

**Solucao:** Adicionar estrutura de 5 secoes com exemplos:
```
SECAO 1 - DESTAQUE DO DIA (150 palavras)
Comece com o fato mais impactante. Use dados especificos.
Exemplo: "O IODEX 62% Fe CFR China fechou em $104.75/t, queda de 2.3%..."

SECAO 2 - ANALISE DE PRECOS (tabela + insight)
| Indicador | Valor | Var |
|-----------|-------|-----|
| IODEX 62% | $104.75 | -2.3% |

SECAO 3 - DESTAQUES (3-5 bullets)
- Bullet com dado especifico
- Bullet com contexto

SECAO 4 - PERSPECTIVAS (1-2 paragrafos)
O que esperar nos proximos dias.

SECAO 5 - WHATSAPP (max 500 chars)
Versao ultra-resumida para mobile.
```

**Esforco:** 2 horas

---

## 🟠 PENDENTE - ALTO

### 5. Adicionar Few-Shot ao WF6 Image (antigo #6)

**Workflow:** `yr7VUG1VMi8o8fi9` | Node: `AI GERAR PROMPT IMAGEM`

**Problema Atual:** Define 3 cenarios visuais mas sem exemplos de OUTPUT.

**Nota Atual:** 6/10

**Solucao:** Adicionar 3 exemplos completos:
```
CENARIO 1 - LOGISTICS (portos, navios)
INPUT: "China aumenta importacoes via Porto de Qingdao"
OUTPUT: "Massive bulk carrier ship at dawn, entering a bustling Chinese port,
cranes loading iron ore, warm golden light, industrial atmosphere,
photorealistic, 4K, cinematic composition"

CENARIO 2 - MINING (producao, mineracao)
INPUT: "Vale bate recorde de producao em Carajas"
OUTPUT: "Aerial view of open-pit iron ore mine in Brazilian Amazon,
giant haul trucks, red earth contrasting with green forest,
dramatic clouds, documentary style photography"

CENARIO 3 - MARKET (precos, financeiro)
INPUT: "IODEX cai 5% em uma semana"
OUTPUT: "Abstract visualization of falling commodity prices,
iron ore rocks tumbling down a stylized graph,
cold blue lighting, bearish atmosphere, financial news aesthetic"
```

**Esforco:** 1-2 horas

---

### 7. Melhorar Prompt WF2 Archiver

**Workflow:** `LfU5ddiFTiDSrUSp` | Node: `Archiver`

**Problema:** Sem exemplos de transformacao RSS → Artigo.

**Nota Atual:** 4/10

**Solucao:** Adicionar 2 exemplos:
```
EXEMPLO 1:
INPUT (RSS): "Iron ore prices fell 2% on Tuesday as Chinese steel mills..."
OUTPUT (Artigo):
{
  "title": "Minerio de ferro recua 2% com demanda chinesa mais fraca",
  "excerpt": "Precos do minerio cairam na terca-feira...",
  "content_html": "<p>O mercado de minerio de ferro registrou queda...</p>"
}

EXEMPLO 2:
INPUT (RSS): "Vale SA reported Q3 production of 89Mt..."
OUTPUT (Artigo):
{
  "title": "Vale reporta producao de 89Mt no 3T",
  ...
}
```

**Esforco:** 2 horas

---

## 🟡 PENDENTE - MEDIO

### 8. Mover Tokens Hardcoded para Credentials

**Workflows afetados:** WF0, WF5, WF6, WF6.5, WF7, WF8

**Problema:** Tokens Telegram nos nodes HTTP Request:
```javascript
"url": "https://api.telegram.org/bot8566018567:AAHiLiFUO0tsiE-3GZpFii3JRluPNEy_4F8/sendMessage"
```

**Risco:** Vazamento se JSONs compartilhados.

**Solucao:**
1. Criar credential "Telegram Bot API" no n8n
2. Substituir HTTP Request por Telegram node nativo
3. Ou usar variaveis de ambiente

**Esforco:** 1 hora

---

### 9. Paralelizar WF7 Social Media

**Workflow:** `KkCUTo9KVfZkfZrE`

**Problema:** Twitter → LinkedIn → Instagram sequencial.

**Solucao:**
```
Atual:    Twitter → LinkedIn → Instagram (sequencial)
Sugerido: Twitter ─┬─ LinkedIn ─┬─ Instagram (paralelo)
                   └────────────┘
```

**Esforco:** 2 horas

---

## 🟢 BACKLOG FUTURO

### Integracoes

| Item | Requisitos | Esforco |
|------|------------|---------|
| LinkedIn API | App aprovado, OAuth 2.0 | 4+ horas |
| Instagram API | Meta Business Account | 4+ horas |
| WhatsApp Business | UaZapi configurado | 2 horas |

### Features Avancadas

| Item | Descricao |
|------|-----------|
| A/B Testing Headlines | Testar variacoes de titulos |
| Podcast Automatico | ElevenLabs para audio |
| Infograficos | Gerar visualizacoes de precos |
| Alertas de Preco | Notificar niveis criticos |
| Sentiment Analysis | Classificar tom bullish/bearish |
| Multi-idioma | Versao em ingles |
| RSS Feed proprio | Gerar feed do blog |

---

## 📊 ANALISE DE PROMPTS

### Notas por Workflow (Atualizado 2026-01-04)

| Workflow | Node | Few-Shot | Persona | Constraints | Nota |
|----------|------|----------|---------|-------------|------|
| WF2 | Archiver | ✅ 2 exemplos | ✅ | ✅ | 7/10 |
| ~~WF2~~ | ~~Rewriter~~ | - | - | - | REMOVIDO |
| **WF5** | **Editor** | **✅ 5 exemplos** | **✅** | **✅** | **9/10** |
| WF6 | Image Prompt | ⚠️ Conceitual | ✅ | ❌ | 6/10 |
| WF7 | Twitter | ⚠️ Parcial | ✅ | ✅ | 7/10 |
| WF7 | LinkedIn | ❌ | ❌ | ⚠️ | 2/10 |
| WF7 | Instagram | ❌ | ❌ | ⚠️ | 2/10 |
| WF8 | Newsletter | ❌ | ❌ | ⚠️ | 3/10 |

### Modelo a Seguir: WF5 AI AGENT EDITOR

O prompt do WF5 e o melhor do sistema. Contem:
- 5 exemplos few-shot de transformacao
- Regras claras DEVE/NAO PODE
- Constraints especificos (max chars)
- Output JSON estruturado
- Campo `changes_made[]` obrigatorio

**Recomendacao:** Usar WF5 como template para melhorar os outros.

---

## 📋 REFERENCIA RAPIDA

### IDs dos Workflows

| Codigo | Nome | ID |
|--------|------|-----|
| WF0 | Error Handler | `dxVlQYOyMQ4xxaHt` |
| WF1 | Feed Supabase | `TgZ3HSnbbSVHsIzD` |
| WF2 | Content Archiver | `LfU5ddiFTiDSrUSp` |
| WF3 | Draft Review | `J7G0HJYT2yqL3WQq` |
| WF4 | Callback Drafts | `Eqj6uTE4pFizUsKH` |
| WF4.5 | Feedback Capture | `QElqWkwrvoxGKDN4` |
| WF4.6 | Quick Edit Capture | `UoQK3JSa2tzPHpxW` |
| WF4.7 | Quick Edit Callbacks | `bKvqmScFWW9KK8ur` |
| WF5 | Revision Processor | `5TuCwLZLlGdczwhU` |
| WF6 | Image Generator | `yr7VUG1VMi8o8fi9` |
| WF6.5 | Image Approval | `vqW2Dt3FkbkQPHws` |
| WF7 | Social Media Factory | `KkCUTo9KVfZkfZrE` |
| WF7.1 | Social Callback | `ZvWogMCqmetav8Fa` |
| WF7.2 | Image Callback | `t4M4Qav7y3860Bje` |
| WF8 | Newsletter Generator | `gMknz5KYcdJuu1Eg` |
| WF8.1 | Newsletter Callback | `e88ZJNv0ffG8nILx` |

### Credentials

| Servico | ID | Nome |
|---------|-----|------|
| Supabase | `04rdCJqTixOtwak5` | blogging |
| Telegram | `m9XVahL3E2MwSiLA` | MT_Publisher |
| Anthropic | `fjN5QtG5xAcoiOWE` | Anthropic account |
| Gemini | `VStJZ2Am1t3kqbKB` | - |
| Twitter | `CzoU1m1eqk0uDfMv` | OAuth2 |

### Supabase

- **Projeto:** `pbhvhfahcvgmgjvuhwuk`
- **Regiao:** us-east-2
- **Tabelas principais:** content_posts, content_workflow, post_images, social_media_sessions, newsletter_history

---

## 📝 CHANGELOG

### 2026-01-04
- **WF2 OTIMIZADO:** Removido node Rewriter redundante
  - Economia de ~50% em custos de API Anthropic
  - Fluxo simplificado: Archiver → Code → INSERT (antes passava por Rewriter)
  - Conexoes AI limpas automaticamente
  - Backup salvo em `backups/WF2-pre-optimization.json`
- Atualizada analise de prompts: Archiver agora 7/10 (ja tinha few-shot)
- Renumerados itens pendentes

### 2025-01-04
- Documento consolidado de 3 arquivos
- Adicionada analise de prompts com notas
- Corrigido: WF5 JA TEM 5 exemplos few-shot (antes dizia que nao tinha)
- Corrigido: ID do WF8 (era `9KjSwQjXaXKQHZKs`, correto `gMknz5KYcdJuu1Eg`)
- Adicionada secao de referencia rapida

### 2025-12-30
- Bugs de imagem corrigidos (5 items)
- Quick wins documentados

### 2025-12-29
- Documento inicial criado

---

*Este documento consolida: IMPROVEMENT_SUGGESTIONS.md, PROMPT_IMPROVEMENTS_PLAN.md, QUICK_WINS.md*

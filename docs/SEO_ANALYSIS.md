# Analise Completa de SEO - Minerals Trading Daily

> **Website:** mineralstradingdaily.com.br
> **Nicho:** Commodities minerais (minerio de ferro, aco, pelotas)
> **Publico-alvo:** Traders, analistas, profissionais do mercado de commodities
> **Data da Analise:** 2026-01-04
> **Versao:** 1.0

---

## Sumario Executivo

Este documento apresenta uma analise completa de SEO para o blog Minerals Trading Daily, com foco em:
- Otimizacao on-page para noticias de mercado
- Schema markup especializado para NewsArticle
- Estrategia de keywords para commodities em PT-BR
- Configuracoes tecnicas para WordPress automatizado via n8n

**Prioridades Identificadas:**
1. P0 (Critico): Schema NewsArticle incompleto no WF2
2. P1 (Alto): Meta descriptions dinamicas ausentes
3. P1 (Alto): Open Graph e Twitter Cards nao otimizados
4. P2 (Medio): Estrategia de keywords nao documentada

---

## 1. SEO On-Page

### 1.1 Titulos (Title Tags)

**Problema Identificado:**
O WF2 (Content Archiver) gera `meta_title` de ate 60 caracteres, mas nao ha validacao de:
- Palavra-chave primaria nos primeiros 50 caracteres
- Separador padrao (ex: ` | Minerals Trading Daily`)
- Evitar duplicacao com o `title` do post

**Recomendacao:**

```
Estrutura ideal para title tag:
[Keyword Principal] + [Contexto] | Minerals Trading Daily

Exemplos:
- "Minerio de Ferro Cai 2% com Demanda China Fraca | Minerals Trading Daily"
- "IODEX 62% Fe Atinge US$105: Maior Alta em 2 Semanas | Minerals Trading Daily"
- "Vale Reporta Producao Recorde em Carajas | Minerals Trading Daily"

Regras:
- Maximo: 60 caracteres (incluindo marca)
- Marca: " | Minerals Trading Daily" (26 chars) = 34 chars para conteudo
- Keyword primaria: Primeiros 30 caracteres
```

**Implementacao no WF2:**

Adicionar ao prompt do Archiver:
```
META_TITLE:
- Maximo 60 caracteres incluindo " | Minerals Trading Daily"
- Keyword principal nos primeiros 30 caracteres
- Nao repetir exatamente o titulo do post
- Usar numeros quando houver dados (precos, percentuais)
```

**Impacto Estimado:**
- CTR esperado: +15-25% em SERPs
- Posicao media: Melhoria de 2-5 posicoes para keywords de cauda longa

---

### 1.2 Meta Descriptions

**Problema Identificado:**
O campo `meta_description` existe no schema, mas:
- Nao ha validacao de tamanho (ideal: 150-160 chars)
- Falta CTA (Call to Action) nos finais
- Nao inclui dados especificos (precos, percentuais)

**Recomendacao:**

```
Estrutura ideal para meta description:
[Resumo do fato] + [Dado especifico] + [CTA implicito]

Exemplos:
- "O IODEX 62% Fe fechou em US$105,20/t, alta de 0,19%. Analise completa do
   mercado de minerio de ferro e impactos para exportadores brasileiros."
   (158 caracteres)

- "Vale atinge producao recorde de 89Mt no 3T. Entenda os impactos no mercado
   global de minerio de ferro e previsoes para o 4T." (142 caracteres)

Regras:
- Minimo: 120 caracteres
- Maximo: 160 caracteres
- Incluir pelo menos um numero (preco, %, toneladas)
- Terminar com frase que convida a leitura
```

**Implementacao no WF2:**

Atualizar prompt:
```
META_DESCRIPTION:
- Exatamente 150-160 caracteres
- OBRIGATORIO incluir dado numerico do artigo
- Estrutura: Fato + Dado + Contexto
- NAO usar "Clique aqui" ou "Leia mais"
- Terminar com frase completa (nao cortar no meio)
```

---

### 1.3 Estrutura de Headings (H1-H6)

**Problema Identificado:**
O `content_html` gerado nao segue hierarquia consistente de headings.

**Recomendacao:**

```html
<!-- Estrutura ideal para artigo de noticia -->
<article>
  <h1>[Titulo Principal - Unico por pagina]</h1>

  <p>[Lead - primeiro paragrafo com fato principal]</p>

  <p>[Desenvolvimento 1]</p>
  <p>[Desenvolvimento 2]</p>

  <!-- Se houver secoes distintas: -->
  <h2>Impacto no Mercado Brasileiro</h2>
  <p>[Contexto Brasil]</p>

  <h2>Proximos Passos</h2>
  <p>[O que esperar]</p>
</article>

PROIBIDO:
- Multiplos H1 na mesma pagina
- H3 sem H2 anterior
- Pular niveis (H1 direto para H3)
- Subtitulos genericos ("Detalhes", "Mais informacoes")
```

**Nota:** O prompt atual do WF2 ja proibe bullet points e subtitulos academicos - MANTER.

---

### 1.4 URLs (Slugs)

**Status Atual:** BOM

O `Code in JavaScript3` no WF2 ja gera slugs otimizados:
- Remove acentos
- Adiciona timestamp unico
- Limita a 50 caracteres base

**Melhoria Sugerida:**

Adicionar keyword principal ao inicio do slug:
```javascript
// Atual: "vale-producao-recorde-20260104-1530-abc123"
// Melhor: "minerio-ferro-vale-producao-recorde-20260104"
```

**Implementacao:**
```javascript
// Adicionar ao generateUniqueSlug()
function generateUniqueSlug(baseText, category, intelligenceId) {
  const categoryPrefix = {
    'price_update': 'minerio-ferro-precos',
    'corporate_news': 'minerio-ferro',
    'trade_flow': 'minerio-ferro-comercio',
    'market_sentiment': 'mercado-commodities'
  };

  const prefix = categoryPrefix[category] || '';
  // ... resto do codigo
}
```

---

### 1.5 Imagens

**Status Atual:** INCOMPLETO

O WF6 gera imagens com Gemini, mas:
- Alt text nao e gerado automaticamente
- File names nao sao otimizados
- Falta caption/legenda

**Recomendacao:**

Adicionar ao WF6.5 (Image Approval) ou WF2:
```json
{
  "featured_image": {
    "url": "https://...",
    "alt": "Navio graneleiro no Porto de Qingdao descarregando minerio de ferro",
    "title": "Porto de Qingdao - Importacao de Minerio de Ferro China",
    "caption": "Importacoes chinesas de minerio atingem recorde em 2025. Fonte: Minerals Trading Daily"
  }
}
```

**Prompt para geracao de alt text:**
```
GERE ALT TEXT para imagem de noticia:
- Descreva o que aparece na imagem (nao o que ela representa)
- Maximo 125 caracteres
- Inclua keyword se natural
- NAO use "imagem de" ou "foto de"

Exemplo: "Navio graneleiro ancorado em porto chines com guindastes descarregando minerio"
```

---

## 2. SEO Tecnico

### 2.1 Schema Markup (JSON-LD)

**Status Atual:** PARCIALMENTE IMPLEMENTADO

O WF2 gera `structured_data` no prompt, mas e basico.

**Problema Identificado:**
```json
// Schema atual (incompleto)
{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "headline": "...",
  "datePublished": "...",
  "author": {"@type": "Organization", "name": "Minerals Trading Daily"},
  "publisher": {"@type": "Organization", "name": "Minerals Trading Daily"},
  "description": "..."
}
```

**Faltam campos obrigatorios do Google News:**
- `image` (obrigatorio desde 2024)
- `dateModified`
- `mainEntityOfPage`
- Logo do publisher

---

#### 2.1.1 Schema NewsArticle Completo

```json
{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://mineralstradingdaily.com.br/minerio-ferro-iodex-62-alta-105-2026/"
  },
  "headline": "IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada",
  "description": "O indice Platts IODEX 62% Fe fechou em alta de 0,19% nesta quinta-feira, refletindo expectativas de estimulos chineses.",
  "image": [
    "https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/minerio-ferro-porto-qingdao-1200x630.jpg",
    "https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/minerio-ferro-porto-qingdao-1200x900.jpg",
    "https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/minerio-ferro-porto-qingdao-1200x1200.jpg"
  ],
  "datePublished": "2026-01-04T10:30:00-03:00",
  "dateModified": "2026-01-04T10:30:00-03:00",
  "author": {
    "@type": "Organization",
    "name": "Minerals Trading Daily",
    "url": "https://mineralstradingdaily.com.br/sobre/"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Minerals Trading Daily",
    "url": "https://mineralstradingdaily.com.br/",
    "logo": {
      "@type": "ImageObject",
      "url": "https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png",
      "width": 600,
      "height": 60
    },
    "sameAs": [
      "https://twitter.com/MineralsTNews",
      "https://www.linkedin.com/company/minerals-trading-daily"
    ]
  },
  "keywords": ["minerio de ferro", "IODEX", "commodities", "China", "precos minerio"],
  "articleSection": "Mercado",
  "wordCount": 450,
  "inLanguage": "pt-BR",
  "isAccessibleForFree": true,
  "hasPart": {
    "@type": "WebPageElement",
    "isAccessibleForFree": true
  }
}
```

**Implementacao no WF2:**

Substituir o schema atual no prompt por:
```
STRUCTURED_DATA (JSON-LD NewsArticle):
{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "URL_DO_POST"
  },
  "headline": "MESMO_DO_TITLE",
  "description": "MESMO_DA_META_DESCRIPTION",
  "image": ["URL_IMAGEM_GERADA"],
  "datePublished": "ISO_DATE_CREATED_AT",
  "dateModified": "ISO_DATE_CREATED_AT",
  "author": {
    "@type": "Organization",
    "name": "Minerals Trading Daily",
    "url": "https://mineralstradingdaily.com.br/sobre/"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Minerals Trading Daily",
    "logo": {
      "@type": "ImageObject",
      "url": "https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png"
    }
  },
  "keywords": MESMO_DAS_TAGS,
  "articleSection": "Mercado",
  "wordCount": WORD_COUNT,
  "inLanguage": "pt-BR"
}
```

---

#### 2.1.2 Schema Organization

Adicionar no header do WordPress (functions.php ou plugin SEO):

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Minerals Trading Daily",
  "alternateName": "MTD",
  "url": "https://mineralstradingdaily.com.br",
  "logo": {
    "@type": "ImageObject",
    "url": "https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png",
    "width": 600,
    "height": 60
  },
  "description": "Portal de noticias e inteligencia de mercado para o setor de minerio de ferro e commodities minerais. Cobertura diaria de precos, producao e comercio global.",
  "foundingDate": "2024",
  "founders": [
    {
      "@type": "Person",
      "name": "Equipe Minerals Trading Daily"
    }
  ],
  "address": {
    "@type": "PostalAddress",
    "addressCountry": "BR"
  },
  "sameAs": [
    "https://twitter.com/MineralsTNews",
    "https://www.linkedin.com/company/minerals-trading-daily",
    "https://www.instagram.com/mineralstradingdaily"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "contactType": "editorial",
    "email": "contato@mineralstradingdaily.com.br",
    "availableLanguage": ["Portuguese", "English"]
  },
  "knowsAbout": [
    "Minerio de ferro",
    "Commodities minerais",
    "Aco",
    "Pelotas de minerio",
    "IODEX",
    "Platts",
    "Mercado de commodities",
    "Vale S.A.",
    "BHP",
    "Rio Tinto",
    "Comercio internacional"
  ],
  "areaServed": {
    "@type": "GeoCircle",
    "geoMidpoint": {
      "@type": "GeoCoordinates",
      "latitude": -23.5505,
      "longitude": -46.6333
    },
    "geoRadius": "Global"
  }
}
```

---

#### 2.1.3 Schema WebSite (Sitelinks Search Box)

Adicionar no header do WordPress:

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Minerals Trading Daily",
  "alternateName": "MTD",
  "url": "https://mineralstradingdaily.com.br",
  "description": "Noticias e inteligencia de mercado para commodities minerais",
  "inLanguage": "pt-BR",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://mineralstradingdaily.com.br/?s={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Minerals Trading Daily",
    "logo": {
      "@type": "ImageObject",
      "url": "https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png"
    }
  }
}
```

---

#### 2.1.4 Schema BreadcrumbList

Para cada artigo:

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Inicio",
      "item": "https://mineralstradingdaily.com.br/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Mercado",
      "item": "https://mineralstradingdaily.com.br/categoria/mercado/"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada"
    }
  ]
}
```

---

### 2.2 Sitemap XML

**Recomendacao:**

Configurar plugin SEO (Yoast ou Rank Math) para gerar:
- `sitemap.xml` (indice)
- `post-sitemap.xml` (artigos)
- `category-sitemap.xml` (categorias)
- `page-sitemap.xml` (paginas estaticas)

**Configuracoes:**
```
- Frequencia de atualizacao: hourly (para noticias)
- Prioridade de posts: 0.8
- Prioridade de categorias: 0.6
- Excluir: tags com menos de 3 posts
```

**News Sitemap (Google News):**

Se o site for aceito no Google News, adicionar news sitemap:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:news="http://www.google.com/schemas/sitemap-news/0.9">
  <url>
    <loc>https://mineralstradingdaily.com.br/minerio-ferro-iodex-62-alta/</loc>
    <news:news>
      <news:publication>
        <news:name>Minerals Trading Daily</news:name>
        <news:language>pt</news:language>
      </news:publication>
      <news:publication_date>2026-01-04T10:30:00-03:00</news:publication_date>
      <news:title>IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada</news:title>
      <news:keywords>minerio de ferro, IODEX, commodities, China</news:keywords>
    </news:news>
  </url>
</urlset>
```

---

### 2.3 Robots.txt

**Recomendacao:**

```
# robots.txt para mineralstradingdaily.com.br

User-agent: *
Allow: /

# Bloquear areas administrativas
Disallow: /wp-admin/
Disallow: /wp-includes/
Disallow: /wp-content/plugins/
Disallow: /wp-content/cache/
Disallow: /wp-json/

# Bloquear parametros de busca duplicados
Disallow: /*?s=
Disallow: /*?replytocom=
Disallow: /*?filter_*

# Bloquear feeds (opcional, depende da estrategia)
# Disallow: /feed/
# Disallow: /comments/feed/

# Sitemaps
Sitemap: https://mineralstradingdaily.com.br/sitemap_index.xml
Sitemap: https://mineralstradingdaily.com.br/news-sitemap.xml

# Crawl-delay para bots agressivos
User-agent: AhrefsBot
Crawl-delay: 10

User-agent: SemrushBot
Crawl-delay: 10

User-agent: MJ12bot
Disallow: /
```

---

### 2.4 Core Web Vitals

**Metricas-alvo:**

| Metrica | Alvo | Descricao |
|---------|------|-----------|
| LCP (Largest Contentful Paint) | < 2.5s | Carregamento do maior elemento |
| FID (First Input Delay) | < 100ms | Tempo de resposta a interacao |
| CLS (Cumulative Layout Shift) | < 0.1 | Estabilidade visual |
| INP (Interaction to Next Paint) | < 200ms | Substitui FID em 2024 |

**Otimizacoes Recomendadas:**

1. **Imagens (LCP):**
   - Usar WebP com fallback para JPEG
   - Lazy loading para imagens abaixo do fold
   - Preload da featured image: `<link rel="preload" as="image" href="...">`

2. **CSS/JS (FID/INP):**
   - Minificar e combinar CSS
   - Defer JavaScript nao-critico
   - Usar plugin de cache (WP Rocket, LiteSpeed Cache)

3. **Fonts (CLS):**
   - Usar `font-display: swap`
   - Preload de fontes: `<link rel="preload" as="font" type="font/woff2" href="...">`

4. **Imagens geradas pelo WF6:**
   - Dimensoes fixas: 1200x630 (Open Graph)
   - Comprimir antes de upload (Gemini ja gera otimizado)
   - Width/height explicitos no HTML

---

## 3. Estrategia de Keywords

### 3.1 Keywords Primarias (Head Terms)

| Keyword | Volume Mensal (BR) | Dificuldade | Intencao |
|---------|-------------------|-------------|----------|
| minerio de ferro | 18.100 | Alta | Informacional |
| preco minerio de ferro | 6.600 | Media | Comercial |
| cotacao minerio de ferro | 4.400 | Media | Comercial |
| minerio de ferro hoje | 2.900 | Media | Navegacional |
| vale minerio de ferro | 1.900 | Media | Navegacional |

### 3.2 Keywords Secundarias (Long Tail)

| Keyword | Volume | Uso Ideal |
|---------|--------|-----------|
| preco minerio de ferro hoje | 1.600 | Titulo/H1 de atualizacoes diarias |
| cotacao minerio de ferro china | 480 | Posts sobre importacoes chinesas |
| minerio de ferro tonelada preco | 390 | Posts de analise de precos |
| exportacao minerio de ferro brasil | 320 | Posts sobre Vale, comercio |
| minerio de ferro 62 fe | 260 | Posts sobre IODEX especificamente |
| pelota de minerio de ferro | 210 | Posts sobre pelotizacao |
| frete minerio de ferro | 170 | Posts sobre Baltic Dry Index |
| minerio de ferro platts | 140 | Posts citando Platts IODEX |
| acoes minerio de ferro | 110 | Posts sobre Vale, CSN |
| demanda minerio de ferro china | 90 | Posts sobre siderurgicas chinesas |

### 3.3 Keywords LSI (Semanticamente Relacionadas)

Incluir naturalmente nos textos:
- commodities minerais
- aco e siderurgia
- teor de ferro (62%, 65%)
- CFR Norte da China
- Porto de Qingdao
- usinas siderurgicas
- alto-forno
- pelotizacao
- concentrado de minerio
- graneleiro / bulk carrier
- Baltic Dry Index
- Carajas (mina da Vale)
- mineiradora / mineradora

### 3.4 Topical Clusters

**Cluster 1: Precos e Indices**
- Hub: "Guia Completo: Indices de Preco do Minerio de Ferro"
- Spokes:
  - "O que e o IODEX 62% Fe e como e calculado"
  - "Diferenca entre CFR e FOB no minerio de ferro"
  - "Historico de precos do minerio de ferro (ultimos 10 anos)"
  - "Como os spreads de qualidade afetam o preco"

**Cluster 2: Producao e Empresas**
- Hub: "Maiores Produtores de Minerio de Ferro do Mundo"
- Spokes:
  - "Vale: Producao, Operacoes e Resultados"
  - "BHP e Rio Tinto: Pilbara vs Carajas"
  - "Fortescue Metals: Ascensao e Estrategia"
  - "Producao de minerio no Brasil vs Australia"

**Cluster 3: Mercado China**
- Hub: "China e o Mercado Global de Minerio de Ferro"
- Spokes:
  - "Importacoes chinesas de minerio: dados mensais"
  - "Siderurgicas chinesas: producao de aco"
  - "Estoques de minerio nos portos chineses"
  - "Politica ambiental da China e impacto no aco"

---

### 3.5 Implementacao no WF2

Adicionar ao prompt do Archiver:

```
KEYWORDS:
Sempre inclua naturalmente no texto:
- Keyword primaria no titulo e primeiro paragrafo
- Pelo menos 2 keywords secundarias no corpo
- Keywords LSI distribuidas (nao forcar)

Para posts de PRECO:
- "minerio de ferro" (obrigatorio)
- "preco" ou "cotacao"
- "IODEX" ou "Platts" (se aplicavel)
- "US$/tonelada" ou "dolar por tonelada"

Para posts CORPORATIVOS:
- Nome da empresa
- "producao" ou "resultados"
- "minerio de ferro"
- Localizacao (Carajas, Pilbara, etc)
```

---

## 4. E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)

### 4.1 Demonstrar Expertise

**Implementacoes Recomendadas:**

1. **Pagina "Sobre Nos":**
   - Descrever experiencia da equipe no setor
   - Mencionar fontes de dados (Platts, Reuters)
   - Explicar metodologia de analise

2. **Bylines nos Artigos:**
   - Atualmente: `author: 'Minerals Trading Daily'`
   - Melhoria: Criar perfis de "analistas virtuais" com bio

```json
{
  "author": {
    "@type": "Person",
    "name": "Equipe Editorial MTD",
    "url": "https://mineralstradingdaily.com.br/equipe/",
    "description": "Equipe de analistas especializados em commodities minerais com mais de 10 anos de experiencia no setor de mineracao e siderurgia."
  }
}
```

3. **Citacoes de Fontes:**
   - Sempre citar fonte original (Platts, Bloomberg, Reuters)
   - Adicionar links para relatorios oficiais quando disponiveis
   - Usar `rel="nofollow"` para fontes externas

### 4.2 Demonstrar Autoridade

1. **Backlinks:**
   - Buscar mencoes em portais do setor (InfoMoney, Valor)
   - Guest posts em blogs de economia
   - Presenca em agregadores de noticias

2. **Presenca Social Consistente:**
   - Twitter ativo (@MineralsTNews)
   - LinkedIn com conteudo profissional
   - Engajamento com comunidade do setor

3. **Dados Originais:**
   - Criar graficos e visualizacoes proprias
   - Publicar resumos semanais/mensais exclusivos
   - Dashboard publico de precos (diferencial)

### 4.3 Demonstrar Confiabilidade

1. **HTTPS:** Verificar certificado SSL ativo e configurado
2. **Politica de Privacidade:** Pagina obrigatoria
3. **Termos de Uso:** Disclaimer sobre nao ser recomendacao de investimento
4. **Contato:** Email e formulario de contato visiveis
5. **Correcoes:** Politica de correcao de erros publicada

### 4.4 Checklist E-E-A-T para WordPress

```
[ ] Pagina "Sobre Nos" com historia e expertise
[ ] Pagina "Metodologia" explicando fontes de dados
[ ] Pagina "Politica de Privacidade" LGPD-compliant
[ ] Pagina "Termos de Uso" com disclaimer financeiro
[ ] Pagina "Contato" com formulario funcional
[ ] Schema Organization no header
[ ] Schema Author em cada artigo
[ ] Datas de publicacao visiveis
[ ] Datas de atualizacao quando aplicavel
[ ] Links para fontes originais
[ ] Perfis sociais linkados
```

---

## 5. Schema Markup Completo (JSON-LD)

### 5.1 Template para Artigos de Noticia

**Arquivo: `/wp-content/themes/seu-tema/template-parts/schema-newsarticle.php`**

```php
<?php
/**
 * Schema NewsArticle para posts do Minerals Trading Daily
 * Gerar automaticamente via WF2 ou injetar via plugin
 */
function mtd_generate_newsarticle_schema($post_id) {
    $post = get_post($post_id);
    $meta = get_post_meta($post_id);
    $featured_image = get_the_post_thumbnail_url($post_id, 'full');
    $categories = wp_get_post_categories($post_id, ['fields' => 'names']);
    $tags = wp_get_post_tags($post_id, ['fields' => 'names']);

    $schema = [
        '@context' => 'https://schema.org',
        '@type' => 'NewsArticle',
        'mainEntityOfPage' => [
            '@type' => 'WebPage',
            '@id' => get_permalink($post_id)
        ],
        'headline' => $post->post_title,
        'description' => get_the_excerpt($post_id) ?: wp_trim_words($post->post_content, 30),
        'image' => $featured_image ? [
            $featured_image,
            // Adicionar versoes alternativas se disponiveis
        ] : 'https://mineralstradingdaily.com.br/wp-content/uploads/default-og-image.jpg',
        'datePublished' => get_the_date('c', $post_id),
        'dateModified' => get_the_modified_date('c', $post_id),
        'author' => [
            '@type' => 'Organization',
            'name' => 'Minerals Trading Daily',
            'url' => 'https://mineralstradingdaily.com.br/sobre/'
        ],
        'publisher' => [
            '@type' => 'Organization',
            'name' => 'Minerals Trading Daily',
            'logo' => [
                '@type' => 'ImageObject',
                'url' => 'https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png',
                'width' => 600,
                'height' => 60
            ]
        ],
        'articleSection' => implode(', ', $categories),
        'keywords' => implode(', ', $tags),
        'wordCount' => str_word_count(strip_tags($post->post_content)),
        'inLanguage' => 'pt-BR',
        'isAccessibleForFree' => true
    ];

    return json_encode($schema, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
}
```

### 5.2 Template para Homepage

```json
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": "https://mineralstradingdaily.com.br/#website",
      "url": "https://mineralstradingdaily.com.br/",
      "name": "Minerals Trading Daily",
      "description": "Noticias e inteligencia de mercado para commodities minerais",
      "inLanguage": "pt-BR",
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": "https://mineralstradingdaily.com.br/?s={search_term_string}"
        },
        "query-input": "required name=search_term_string"
      },
      "publisher": {
        "@id": "https://mineralstradingdaily.com.br/#organization"
      }
    },
    {
      "@type": "Organization",
      "@id": "https://mineralstradingdaily.com.br/#organization",
      "name": "Minerals Trading Daily",
      "url": "https://mineralstradingdaily.com.br/",
      "logo": {
        "@type": "ImageObject",
        "url": "https://mineralstradingdaily.com.br/wp-content/uploads/logo-mtd-600x60.png",
        "@id": "https://mineralstradingdaily.com.br/#logo"
      },
      "sameAs": [
        "https://twitter.com/MineralsTNews",
        "https://www.linkedin.com/company/minerals-trading-daily"
      ],
      "contactPoint": {
        "@type": "ContactPoint",
        "contactType": "editorial",
        "email": "contato@mineralstradingdaily.com.br"
      }
    },
    {
      "@type": "WebPage",
      "@id": "https://mineralstradingdaily.com.br/#webpage",
      "url": "https://mineralstradingdaily.com.br/",
      "name": "Minerals Trading Daily - Noticias de Minerio de Ferro e Commodities",
      "isPartOf": {
        "@id": "https://mineralstradingdaily.com.br/#website"
      },
      "about": {
        "@id": "https://mineralstradingdaily.com.br/#organization"
      },
      "description": "Portal de noticias diarias sobre o mercado de minerio de ferro, precos Platts IODEX, producao global e comercio de commodities minerais.",
      "inLanguage": "pt-BR"
    }
  ]
}
```

### 5.3 Template para Pagina de Categoria

```json
{
  "@context": "https://schema.org",
  "@type": "CollectionPage",
  "mainEntity": {
    "@type": "ItemList",
    "itemListElement": [
      {
        "@type": "ListItem",
        "position": 1,
        "url": "https://mineralstradingdaily.com.br/minerio-ferro-alta-iodex/"
      },
      {
        "@type": "ListItem",
        "position": 2,
        "url": "https://mineralstradingdaily.com.br/vale-producao-recorde/"
      }
    ]
  },
  "name": "Noticias sobre Precos de Minerio de Ferro",
  "description": "Acompanhe as ultimas noticias sobre precos de minerio de ferro, indices Platts IODEX e cotacoes do mercado global.",
  "url": "https://mineralstradingdaily.com.br/categoria/precos/",
  "isPartOf": {
    "@id": "https://mineralstradingdaily.com.br/#website"
  }
}
```

---

## 6. Social SEO (Open Graph e Twitter Cards)

### 6.1 Open Graph Tags

**Adicionar ao header de cada post:**

```html
<!-- Open Graph / Facebook -->
<meta property="og:type" content="article" />
<meta property="og:url" content="https://mineralstradingdaily.com.br/minerio-ferro-iodex-alta/" />
<meta property="og:title" content="IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada" />
<meta property="og:description" content="O indice Platts IODEX 62% Fe fechou em alta de 0,19% nesta quinta-feira. Analise completa do mercado de minerio de ferro." />
<meta property="og:image" content="https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/iodex-alta-1200x630.jpg" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:alt" content="Grafico mostrando alta do IODEX 62% Fe" />
<meta property="og:site_name" content="Minerals Trading Daily" />
<meta property="og:locale" content="pt_BR" />

<!-- Dados do artigo -->
<meta property="article:published_time" content="2026-01-04T10:30:00-03:00" />
<meta property="article:modified_time" content="2026-01-04T10:30:00-03:00" />
<meta property="article:author" content="https://mineralstradingdaily.com.br/sobre/" />
<meta property="article:section" content="Mercado" />
<meta property="article:tag" content="minerio de ferro" />
<meta property="article:tag" content="IODEX" />
<meta property="article:tag" content="commodities" />
```

### 6.2 Twitter Cards

```html
<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:site" content="@MineralsTNews" />
<meta name="twitter:creator" content="@MineralsTNews" />
<meta name="twitter:title" content="IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada" />
<meta name="twitter:description" content="O indice Platts IODEX 62% Fe fechou em alta de 0,19% nesta quinta-feira. Analise do mercado de minerio." />
<meta name="twitter:image" content="https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/iodex-alta-1200x630.jpg" />
<meta name="twitter:image:alt" content="Grafico mostrando alta do IODEX 62% Fe" />
```

### 6.3 LinkedIn

O LinkedIn usa Open Graph, mas com algumas particularidades:

```html
<!-- LinkedIn especificos (usar OG) -->
<meta property="og:type" content="article" />
<meta property="og:title" content="IODEX 62% Fe Sobe e Atinge US$105,20 por Tonelada" />
<!-- LinkedIn prefere imagens 1200x627 -->
<meta property="og:image" content="https://mineralstradingdaily.com.br/wp-content/uploads/2026/01/iodex-alta-1200x627.jpg" />
```

### 6.4 Implementacao no WF2

Adicionar ao output do Archiver:

```json
{
  "social_meta": {
    "og_title": "IODEX 62% Fe Sobe e Atinge US$105,20 | Minerals Trading",
    "og_description": "Analise: IODEX 62% Fe fecha em alta de 0,19%. Entenda os fatores e impactos no mercado de minerio.",
    "og_image_alt": "Grafico de precos do minerio de ferro IODEX",
    "twitter_title": "IODEX 62% Fe +0,19% | US$105,20/t",
    "twitter_description": "IODEX fecha em alta. China e estimulos no radar."
  }
}
```

**Regras para Social Meta:**
```
OG_TITLE:
- Maximo 60 caracteres
- Pode ser diferente do title do post
- Foco em engajamento/clique

OG_DESCRIPTION:
- Maximo 200 caracteres (Facebook trunca em ~155)
- Inclua dado numerico principal
- Termine com frase completa

TWITTER_TITLE:
- Maximo 70 caracteres
- Pode usar abreviacoes (US$, %)
- Mais direto que OG

TWITTER_DESCRIPTION:
- Maximo 200 caracteres
- Estilo mais informal
- Pode usar emojis (opcional)
```

---

## 7. Checklist de Implementacao

### 7.1 Prioridade P0 (Critico) - Fazer Imediatamente

| # | Tarefa | Workflow | Esforco |
|---|--------|----------|---------|
| 1 | Atualizar schema NewsArticle no prompt WF2 | WF2 | 1h |
| 2 | Adicionar campos social_meta ao output JSON | WF2 | 30min |
| 3 | Verificar se WordPress esta inserindo schema no head | WordPress | 30min |
| 4 | Verificar HTTPS e redirecionamento www | WordPress/Hosting | 15min |

### 7.2 Prioridade P1 (Alto) - Esta Semana

| # | Tarefa | Workflow | Esforco |
|---|--------|----------|---------|
| 5 | Adicionar schema Organization no header | WordPress | 1h |
| 6 | Adicionar schema WebSite no header | WordPress | 30min |
| 7 | Configurar Open Graph no tema/plugin | WordPress | 1h |
| 8 | Configurar Twitter Cards no tema/plugin | WordPress | 30min |
| 9 | Criar pagina "Sobre Nos" com E-E-A-T | WordPress | 2h |
| 10 | Revisar meta descriptions no prompt WF2 | WF2 | 1h |

### 7.3 Prioridade P2 (Medio) - Este Mes

| # | Tarefa | Workflow | Esforco |
|---|--------|----------|---------|
| 11 | Gerar alt text automatico para imagens | WF6/WF6.5 | 2h |
| 12 | Otimizar slugs com keyword prefix | WF2 | 1h |
| 13 | Configurar News Sitemap | WordPress | 1h |
| 14 | Criar paginas de categoria otimizadas | WordPress | 3h |
| 15 | Implementar breadcrumbs com schema | WordPress | 1h |
| 16 | Criar estrategia de internal linking | WF2 | 2h |

### 7.4 Prioridade P3 (Baixo) - Backlog

| # | Tarefa | Workflow | Esforco |
|---|--------|----------|---------|
| 17 | Dashboard publico de precos (SEO) | Novo | 8h |
| 18 | Pagina de glossario de termos | WordPress | 4h |
| 19 | Aplicar para Google News | - | 2h |
| 20 | Otimizar Core Web Vitals | WordPress | 4h |
| 21 | Criar hub de topical clusters | WordPress | 8h |

---

## 8. Metricas e KPIs

### 8.1 KPIs de SEO

| Metrica | Baseline | Meta 3 Meses | Meta 6 Meses |
|---------|----------|--------------|--------------|
| Trafego Organico (sessoes/mes) | - | +50% | +150% |
| Keywords no Top 10 | - | 20 | 50 |
| Keywords no Top 3 | - | 5 | 15 |
| CTR medio (Search Console) | - | 3% | 5% |
| Impressoes/dia | - | 500 | 2000 |
| Domain Rating (Ahrefs) | - | 20 | 35 |

### 8.2 Ferramentas de Monitoramento

| Ferramenta | Uso | Custo |
|------------|-----|-------|
| Google Search Console | Obrigatorio | Gratis |
| Google Analytics 4 | Obrigatorio | Gratis |
| Bing Webmaster Tools | Recomendado | Gratis |
| Ahrefs | Backlinks + Keywords | Pago |
| Screaming Frog | Auditoria tecnica | Gratis ate 500 URLs |
| PageSpeed Insights | Core Web Vitals | Gratis |
| Schema Validator | Validar JSON-LD | Gratis |

---

## 9. Proximos Passos Recomendados

### Semana 1

1. **Atualizar WF2 Archiver:**
   - Adicionar schema NewsArticle completo ao prompt
   - Adicionar campos social_meta ao JSON output
   - Validar meta descriptions (150-160 chars)

2. **Configurar WordPress:**
   - Instalar/configurar Yoast SEO ou Rank Math
   - Adicionar schema Organization no header
   - Verificar sitemap.xml funcional

### Semana 2

1. **Criar Paginas Essenciais:**
   - Sobre Nos (com E-E-A-T)
   - Politica de Privacidade
   - Termos de Uso

2. **Configurar Social Meta:**
   - Open Graph no tema
   - Twitter Cards no tema
   - Testar com Facebook Debugger e Twitter Card Validator

### Semana 3-4

1. **Otimizar Conteudo Existente:**
   - Revisar posts antigos
   - Adicionar internal links
   - Corrigir meta descriptions

2. **Monitoramento:**
   - Configurar Search Console
   - Criar dashboard de metricas
   - Baseline de posicoes atuais

---

## 10. Referencias

- [Google SEO Starter Guide](https://developers.google.com/search/docs/fundamentals/seo-starter-guide)
- [Schema.org NewsArticle](https://schema.org/NewsArticle)
- [Google Search Central - Structured Data](https://developers.google.com/search/docs/appearance/structured-data)
- [Twitter Cards Documentation](https://developer.twitter.com/en/docs/twitter-for-websites/cards)
- [Open Graph Protocol](https://ogp.me/)
- [Core Web Vitals](https://web.dev/vitals/)
- [E-E-A-T Guidelines](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)

---

*Documento gerado em: 2026-01-04*
*Versao: 1.0*
*Autor: Claude SEO Expert Agent*
*Projeto: Minerals Trading Daily - Blog System Automation*

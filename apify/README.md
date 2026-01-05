# Apify Integration - Platts Twitter Publisher

## Visao Geral

Este modulo integra o scraper do Platts Connect (Apify) com o sistema de publicacao no Twitter.

**Fluxo:**
```
Apify (Platts) -> n8n -> AI Tweet -> CloudConvert (SVG->PNG) -> Twitter
```

## Dataset de Teste

- **ID:** `IaG2QwoWQpQWu13M9`
- **Data:** 29/12/2025
- **Artigos:** 3 (2 Top News + 1 Market Commentary)

## Estrutura dos Dados

```javascript
{
  "allArticles": [
    {
      "title": "News Title",
      "fullText": "Full article content...",
      "source": "Top News - Ferrous Metals",
      "metadata": {
        "highlights": ["Highlight 1", "Highlight 2", "Highlight 3"],
        "wordCount": 964,
        "prices": ["$108.85", "$193"],
        "companies": ["Vale", "BHP"]
      },
      "images": {
        "total": 7,
        "thumbnail": {
          "storeKey": "xxx_thumbnail_0.jpg",
          "mimeType": "image/jpeg"
        },
        "charts": [
          {
            "storeKey": "xxx_chart_1.svg",
            "mimeType": "image/svg+xml",
            "caption": "Chart caption..."
          }
        ]
      }
    }
  ],
  "summary": {
    "totalArticles": 3,
    "totalWords": 2394,
    "totalImages": 12
  }
}
```

## Workflow n8n

**Nome:** `[APIFY] Platts Twitter Publisher`

### Nodes

| Node | Tipo | Funcao |
|------|------|--------|
| TRIGGER MANUAL | manualTrigger | Inicio para testes |
| BUSCAR DATASET | httpRequest | Fetch Apify dataset |
| SPLIT ARTIGOS | splitOut | Separa array em items |
| PREPARAR ARTIGO | code | Extrai campos relevantes |
| AI GERAR TWEET | agent | Gera texto do tweet |
| IF TEM SVG | if | Verifica se tem chart SVG |
| BAIXAR SVG | httpRequest | Download do SVG |
| CONVERTER PNG | httpRequest | CloudConvert API |
| BAIXAR PNG | httpRequest | Download PNG convertido |
| IF TEM IMAGEM | if | Verifica se tem imagem |
| UPLOAD MEDIA | httpRequest | Upload para Twitter |
| EXTRAIR MEDIA ID | code | Extrai media_id |
| TWEET COM IMG | httpRequest | Post com imagem |
| TWEET SEM IMG | twitter | Post sem imagem |

### Credenciais Necessarias

| Credencial | Uso | Status |
|------------|-----|--------|
| Apify API Token | Autenticar na API Apify | Configurar |
| CloudConvert API Key | Converter SVG para PNG | Configurar |
| X API Media Upload | Upload de midia e tweets | Existente |
| X account | Tweet node nativo | Existente |

## Conversao SVG -> PNG

Os charts do Platts sao em SVG. O Twitter nao aceita SVG, entao usamos CloudConvert:

1. **Criar conta:** https://cloudconvert.com/register
2. **Obter API Key:** Dashboard > API > Create API Key
3. **Free tier:** 25 conversoes/dia

### API Call

```http
POST https://api.cloudconvert.com/v2/convert
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "tasks": {
    "import": {
      "operation": "import/base64",
      "file": "BASE64_SVG_DATA",
      "filename": "chart.svg"
    },
    "convert": {
      "operation": "convert",
      "input": "import",
      "output_format": "png"
    },
    "export": {
      "operation": "export/url",
      "input": "convert"
    }
  }
}
```

## Prompt Twitter

Ver `prompts/twitter_platts.md` para o prompt especializado.

## Execucao

1. Garantir que CloudConvert API key esta configurada
2. Executar workflow manualmente
3. Verificar tweets publicados em @MineralsTNews

## Troubleshooting

### Erro: "SVG conversion failed"
- Verificar se API key do CloudConvert esta correta
- Verificar se nao excedeu limite diario (25/dia)

### Erro: "Media upload failed"
- Verificar se imagem e < 5MB
- Verificar formato (PNG, JPG aceitos)

### Erro: "Tweet rate limit"
- Twitter limita posts por hora
- Aguardar e tentar novamente

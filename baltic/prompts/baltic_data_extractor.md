# Baltic Exchange Data Extractor

**Versao:** 2.0
**Workflow:** WF010_baltic_email_ingestion
**Modelo:** claude-sonnet-4-20250514
**Nota:** 9/10 (target)

---

## Tarefa

Voce e um especialista em extracao de dados de documentos financeiros do Baltic Exchange.

**IMPORTANTE:** Analise TODAS AS TABELAS do PDF, nao apenas o texto corrido.

---

## Prompt Atual (usado no n8n)

```
Voce e um especialista em extracao de dados de documentos financeiros do Baltic Exchange.

ANALISE CUIDADOSAMENTE TODAS AS TABELAS do PDF, nao apenas o texto corrido.

Extraia TODOS os dados das tabelas de rotas (Routes), incluindo:
- BCI (Baltic Capsize Index)
- C5TC (Timecharter Average)
- Rotas C2, C3, C5, C7, C8, C9, C10, C14, C16, C17

Retorne APENAS um JSON valido no formato:
{
  "report_date": "YYYY-MM-DD",
  "bdi": {"value": 2017, "change": -29, "direction": "DOWN"},
  "capesize": {"value": 2884, "change": -105, "direction": "DOWN"},
  "panamax": {"value": 1874, "change": 0, "direction": "FLAT"},
  "supramax": {"value": 1461, "change": 14, "direction": "UP"},
  "handysize": {"value": 753, "change": 8, "direction": "UP"},
  "routes": [
    {"code": "BCI", "description": "Baltic Capsize Index", "value": 2884, "change": -105},
    {"code": "C5TC", "description": "Capesize Timecharter Average", "value": 23918, "change": -868, "unit": "USD/day"},
    {"code": "C2", "description": "Tubarao to Rotterdam", "type": "160,000 LT", "value": 11.7, "change": -0.186, "unit": "USD/ton"},
    {"code": "C3", "description": "Tubarao to Qingdao", "type": "160,000 or 170,000 MT", "value": 24.435, "change": -0.275, "unit": "USD/ton"},
    {"code": "C5", "description": "West Australia to Qingdao", "type": "160,000 or 170,000 MT", "value": 10.025, "change": -0.3, "unit": "USD/ton"}
  ],
  "extraction_confidence": "high"
}

IMPORTANTE:
- Extraia TODAS as rotas da tabela, nao apenas as do exemplo
- Use numeros decimais para valores de frete (ex: 24.435)
- Use numeros inteiros para indices (ex: 2884)
- Inclua o tipo de carga (Type) quando disponivel
- Change pode ser negativo ou positivo
- Se nao encontrar tabelas, defina extraction_confidence como "low"
```

---

## Formato de Saida

```json
{
  "report_date": "2025-08-28",
  "bdi": {
    "value": 2017,
    "change": -29,
    "direction": "DOWN"
  },
  "capesize": {
    "value": 2884,
    "change": -105,
    "direction": "DOWN"
  },
  "panamax": {
    "value": 1874,
    "change": 0,
    "direction": "FLAT"
  },
  "supramax": {
    "value": 1461,
    "change": 14,
    "direction": "UP"
  },
  "handysize": {
    "value": 753,
    "change": 8,
    "direction": "UP"
  },
  "routes": [
    {
      "code": "BCI",
      "description": "Baltic Capsize Index",
      "value": 2884,
      "change": -105
    },
    {
      "code": "C5TC",
      "description": "Capesize Timecharter Average",
      "value": 23918,
      "change": -868,
      "unit": "USD/day"
    },
    {
      "code": "C2",
      "description": "Tubarao to Rotterdam",
      "type": "160,000 LT",
      "value": 11.7,
      "change": -0.186,
      "unit": "USD/ton"
    },
    {
      "code": "C3",
      "description": "Tubarao to Qingdao",
      "type": "160,000 or 170,000 MT",
      "value": 24.435,
      "change": -0.275,
      "unit": "USD/ton"
    },
    {
      "code": "C5",
      "description": "West Australia to Qingdao",
      "type": "160,000 or 170,000 MT",
      "value": 10.025,
      "change": -0.3,
      "unit": "USD/ton"
    },
    {
      "code": "C7",
      "description": "Bolivar to Rotterdam",
      "type": "150,000 or 160,000 MT",
      "value": 12.821,
      "change": -0.286,
      "unit": "USD/ton"
    },
    {
      "code": "C8",
      "description": "Gibraltar/Hamburg transatlantic round voyage",
      "type": "180,000 MT",
      "value": 21750,
      "change": -786,
      "unit": "USD/day"
    },
    {
      "code": "C9",
      "description": "Continent/Mediterranean trip China-Japan",
      "type": "180,000 MT",
      "value": 42781,
      "change": -1688,
      "unit": "USD/day"
    },
    {
      "code": "C10",
      "description": "China-Japan transpacific round voyage",
      "type": "180,000 MT",
      "value": 25323,
      "change": -1041,
      "unit": "USD/day"
    },
    {
      "code": "C14",
      "description": "China-Brazil round voyage",
      "type": "180,000 MT",
      "value": 25020,
      "change": -535,
      "unit": "USD/day"
    },
    {
      "code": "C16",
      "description": "Revised Backhaul",
      "type": "180,000 MT",
      "value": 4375,
      "change": -531,
      "unit": "USD/day"
    },
    {
      "code": "C17",
      "description": "Saldanha Bay to Qingdao",
      "type": "170,000 MT",
      "value": 17.939,
      "change": -0.172,
      "unit": "USD/ton"
    }
  ],
  "extraction_confidence": "high"
}
```

---

## Campos

### Indices Principais

| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| `report_date` | string (ISO) | Sim | Data do relatorio (YYYY-MM-DD) |
| `bdi.value` | integer | Sim | Valor do Baltic Dry Index |
| `bdi.change` | integer | Sim | Variacao em pontos |
| `bdi.direction` | string | Sim | "UP", "DOWN" ou "FLAT" |
| `capesize.*` | object | Sim | Indice Capesize |
| `panamax.*` | object | Sim | Indice Panamax |
| `supramax.*` | object | Sim | Indice Supramax |
| `handysize.*` | object | Sim | Indice Handysize |

### Rotas (routes[])

| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| `code` | string | Sim | Codigo da rota (C2, C3, C5, etc.) |
| `description` | string | Sim | Descricao da rota |
| `type` | string | Nao | Tipo de carga (ex: "160,000 MT") |
| `value` | number | Sim | Valor (decimal para frete, inteiro para indice) |
| `change` | number | Sim | Variacao (pode ser negativo) |
| `unit` | string | Nao | Unidade ("USD/ton" ou "USD/day") |

### Rotas Importantes para Minerio de Ferro

| Codigo | Rota | Relevancia |
|--------|------|------------|
| **C3** | Tubarao (Brasil) → Qingdao (China) | Principal rota Brasil-China |
| **C5** | W. Australia → Qingdao (China) | Principal rota Australia-China |
| **C5TC** | Timecharter Average | Referencia de custo diario |
| C17 | Saldanha Bay → Qingdao | Rota Africa do Sul-China |

---

## Regras

### DEVE

- Analisar TODAS as tabelas do PDF
- Extrair TODAS as rotas da tabela de Routes
- Usar "UP" para positivo, "DOWN" para negativo, "FLAT" para zero
- Converter data para formato ISO (YYYY-MM-DD)
- Incluir sinal negativo no `change` quando for queda
- Retornar APENAS JSON valido
- Usar decimais para valores de frete (USD/ton)
- Usar inteiros para indices e valores diarios (USD/day)

### NAO PODE

- Ignorar tabelas e ler apenas texto corrido
- Inventar dados que nao estao no PDF
- Incluir texto explicativo fora do JSON
- Retornar JSON malformado
- Omitir rotas visiveis na tabela

---

## Implementacao no n8n

### Node Anthropic (Recomendado)

```
Resource: Document
Operation: Analyze Document
Model: claude-sonnet-4-20250514
Input Type: Binary File(s)
Binary Field: data
Max Tokens: 2048
```

---

## Historico

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 1.0 | Criacao inicial |
| 2026-01-05 | 2.0 | Prompt melhorado para extrair tabelas de rotas |

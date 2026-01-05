# Baltic Exchange - Modulo de Coleta de Indices

## Visao Geral

Modulo para coleta automatizada de indices de frete maritimo do Baltic Exchange, incluindo o famoso **Baltic Dry Index (BDI)** e indices segmentados por tipo de navio.

## Indices Coletados

| Indice | Codigo | Descricao |
|--------|--------|-----------|
| **Baltic Dry Index** | BDI | Indice composto de frete para graneis secos |
| **Capesize Index** | BCI | Navios 100.000+ DWT (minerio de ferro, carvao) |
| **Panamax Index** | BPI | Navios 60.000-80.000 DWT |
| **Supramax Index** | BSI | Navios 45.000-60.000 DWT |
| **Handysize Index** | BHSI | Navios 15.000-35.000 DWT |

## Fonte de Dados

- **Provedor:** MID-SHIP Group
- **Email:** `DailyReports@midship.com`
- **Frequencia:** Diario (dias uteis)
- **Formato:** PDF via links no email

## Pipeline

```
Email Outlook
    |
    v
Extrair Links PDFs (BDI, Capesize, Panamax, Supramax, Handysize)
    |
    v
Download PDFs
    |
    v
Claude Vision (claude-3.5-sonnet)
    |
    v
JSON Estruturado
    |
    v
Supabase (tabela: baltic_indices)
```

## Workflow n8n

| Nome | ID | Status |
|------|-----|--------|
| WF010_baltic_email_ingestion | 4kThouFXX7FP9XnX | Em desenvolvimento |

## Banco de Dados

### Tabela: `baltic_indices`

```sql
- id (UUID)
- report_date (DATE, UNIQUE)
- bdi_value, bdi_change, bdi_direction
- capesize_value, capesize_change, capesize_direction
- panamax_value, panamax_change, panamax_direction
- supramax_value, supramax_change, supramax_direction
- handysize_value, handysize_change, handysize_direction
- email_id, pdf_urls, raw_response
- created_at
```

## Estrutura de Pastas

```
baltic/
├── README.md                    # Este arquivo
├── prompts/
│   └── baltic_data_extractor.md # Prompt para Claude Vision
├── docs/
│   └── INTEGRATION.md           # Detalhes tecnicos
└── samples/                     # PDFs de exemplo para testes
```

## Uso

### Testar com PDF de exemplo

1. Adicione um PDF do Baltic Exchange em `samples/`
2. Execute o workflow manualmente no n8n
3. Verifique os dados no Supabase

### Verificar dados coletados

```sql
SELECT
  report_date,
  bdi_value,
  capesize_value,
  panamax_value
FROM baltic_indices
ORDER BY report_date DESC
LIMIT 10;
```

## Relevancia para Minerio de Ferro

O Baltic Dry Index (BDI) e especialmente o **Capesize Index (BCI)** sao indicadores cruciais para o mercado de minerio de ferro:

- **Capesize** e a classe de navio mais usada para transportar minerio de ferro
- Rotas principais: Brasil (Tubarao) -> China (Qingdao)
- Custo de frete impacta diretamente o preco FOB vs CFR
- Correlacao historica entre BDI e precos de commodities

## Historico

| Data | Versao | Mudanca |
|------|--------|---------|
| 2026-01-05 | 1.0 | Criacao inicial do modulo |

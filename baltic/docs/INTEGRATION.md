# Baltic Exchange - Detalhes de Integracao

## Visao Geral da Arquitetura

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Microsoft      │────>│  n8n         │────>│  Claude Vision  │
│  Outlook        │     │  Workflow    │     │  (Anthropic)    │
│  (Email Trigger)│     │  WF010       │     │                 │
└─────────────────┘     └──────────────┘     └────────┬────────┘
                                                       │
                                                       v
                        ┌──────────────┐     ┌─────────────────┐
                        │  Telegram    │<────│   Supabase      │
                        │  (Alertas)   │     │   PostgreSQL    │
                        └──────────────┘     └─────────────────┘
```

---

## Fonte de Dados

### MID-SHIP Group

- **Email de origem:** `DailyReports@midship.com`
- **Formato:** HTML com links para PDFs
- **Frequencia:** Diario, dias uteis (segunda a sexta)
- **Horario tipico:** ~08:00 UTC

### Estrutura do Email

O email contem links para PDFs individuais:

```html
<a href="https://...">CAPESIZE INDEX</a> is at <span>1234</span> UP 12
<a href="https://...">PANAMAX INDEX</a> is at <span>987</span> DOWN 8
<a href="https://...">SUPRAMAX INDEX</a> is at <span>876</span> UP 5
<a href="https://...">HANDYSIZE INDEX</a> is at <span>543</span> DOWN 3
<a href="https://...">BDI</a> is at <span>1089</span> DOWN 15
```

---

## Credenciais Necessarias

### Microsoft Outlook (OAuth2)

| Campo | Valor |
|-------|-------|
| Credential ID | `tkL7Q9IsKfYhlPae` |
| Nome | Microsoft Outlook account |
| Tipo | OAuth2 |

### Anthropic Claude

| Campo | Valor |
|-------|-------|
| API | `https://api.anthropic.com/v1/messages` |
| Modelo | `claude-3-5-sonnet-20241022` |
| Max Tokens | 1024 |

### Supabase

| Campo | Valor |
|-------|-------|
| Credential ID | `04rdCJqTixOtwak5` |
| Nome | blogging |
| Projeto | `pbhvhfahcvgmgjvuhwuk` |
| Regiao | us-east-2 |

---

## Fluxo de Dados Detalhado

### 1. Trigger (Microsoft Outlook)

```json
{
  "pollTimes": { "item": [{ "mode": "everyX", "value": 10, "unit": "minutes" }] },
  "filters": {
    "sender": "DailyReports@midship.com"
  }
}
```

### 2. Extrair Links (Code Node)

Regex para extrair links dos PDFs:

```javascript
const capesizeMatch = htmlBody.match(
  /<a[^>]+href=["']([^"']+)["'][^>]*>CAPESIZE INDEX<\/a>\s*is at\s*<span[^>]*>(\d+)\s*(UP|DOWN)\s*(\d+)/i
);
```

### 3. Download PDF (HTTP Request)

```json
{
  "url": "{{ $json.tracking_link }}",
  "options": {
    "response": {
      "responseFormat": "file",
      "outputPropertyName": "pdf_data"
    }
  }
}
```

### 4. Converter para Base64 (Code Node)

```javascript
const binaryData = $input.first().binary.pdf_data;
const base64 = binaryData.data; // ja vem em base64 do n8n
return { json: { pdf_base64: base64 } };
```

### 5. Claude Vision (HTTP Request)

```json
{
  "method": "POST",
  "url": "https://api.anthropic.com/v1/messages",
  "headers": {
    "x-api-key": "{{ $credentials.anthropicApi.apiKey }}",
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
  },
  "body": {
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": [
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "application/pdf",
            "data": "{{ $json.pdf_base64 }}"
          }
        },
        {
          "type": "text",
          "text": "{{ PROMPT_BALTIC_EXTRACTOR }}"
        }
      ]
    }]
  }
}
```

### 6. Salvar Supabase (Insert)

```json
{
  "operation": "insert",
  "table": "baltic_indices",
  "columns": {
    "report_date": "={{ $json.report_date }}",
    "bdi_value": "={{ $json.bdi?.value }}",
    "bdi_change": "={{ $json.bdi?.change }}",
    "bdi_direction": "={{ $json.bdi?.direction }}",
    ...
  }
}
```

---

## Tratamento de Erros

### Erros Comuns

| Erro | Causa | Solucao |
|------|-------|---------|
| 401 Unauthorized | Token Outlook expirado | Renovar OAuth2 |
| PDF Download Failed | Link expirado | Processar email mais rapido |
| Claude Parse Error | PDF malformado | Verificar PDF manualmente |
| Duplicate Key | Dados do dia ja existem | Usar UPSERT |

### Notificacao de Erros

Enviar para Telegram em caso de falha:

```javascript
if (!data.success) {
  // Notificar via WF000_error_handler
  $workflow.execute('dxVlQYOyMQ4xxaHt', {
    error: 'Baltic extraction failed',
    workflow: 'WF010_baltic_email_ingestion',
    details: data
  });
}
```

---

## Limites e Custos

### Claude Vision

- **Custo:** ~$0.003 por imagem (PDF de 1 pagina)
- **Rate limit:** 4000 requests/minute (tier 1)
- **Max file size:** 20MB

### Supabase

- **Storage:** Incluido no plano
- **Rows:** Sem limite pratico para dados diarios

---

## Monitoramento

### Queries Uteis

```sql
-- Ultimos 7 dias de dados
SELECT report_date, bdi_value, capesize_value
FROM baltic_indices
WHERE report_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY report_date DESC;

-- Verificar dias faltando
SELECT d::date AS missing_date
FROM generate_series(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  '1 day'
) d
WHERE d::date NOT IN (SELECT report_date FROM baltic_indices)
  AND EXTRACT(dow FROM d) NOT IN (0, 6); -- Excluir fins de semana
```

---

## Historico de Mudancas

| Data | Mudanca |
|------|---------|
| 2026-01-05 | Criacao da documentacao |
| 2026-01-05 | Migracao de Mistral OCR para Claude Vision |

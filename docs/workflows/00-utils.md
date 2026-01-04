# 00 - Utilitarios

Workflows de suporte ao sistema principal.

## Workflows

### WF0 - Error Handler (10 nodes)
**ID:** `dxVlQYOyMQ4xxaHt`
**Status:** Inativo

Tratamento centralizado de erros do sistema.

```
TRIGGER ERROR → PROCESSAR ERRO → VERIFICAR DUPLICADO → EH DUPLICADO?
                                                            │
                                    ┌───────────────────────┴───────────────────────┐
                                    ▼                                               ▼
                            INCREMENTAR CONTADOR                              INSERIR ERRO
                                    │                                               │
                                    ▼                                               ▼
                              LOG DUPLICADO                               PREPARAR TELEGRAM
                                                                                    │
                                                                                    ▼
                                                                            ENVIAR TELEGRAM
                                                                                    │
                                                                                    ▼
                                                                            CONFIRMAR ENVIO
```

**Nodes:**
- Error Trigger: Captura erros de outros workflows
- Supabase: Log de erros com deduplicacao
- Telegram: Alerta para o administrador

---

### ALERTS PROACTIVE (7 nodes)
**ID:** `OLgG9Y2iHQVujYXB`
**Status:** Ativo

Monitoramento proativo de atividade do sistema.

```
A CADA 2 HORAS → QUERY ATIVIDADE → VERIFICAR ATIVIDADE → DEVE ALERTAR?
                                                              │
                                          ┌───────────────────┴───────────────────┐
                                          ▼                                       ▼
                                    FORMATAR ALERTA                          SEM ALERTA
                                          │
                                          ▼
                                    ENVIAR ALERTA
```

**Trigger:** Cron a cada 2 horas
**Funcao:** Verifica se o pipeline esta parado e alerta via Telegram

---

### CMD TELEGRAM COMMANDS (12 nodes)
**ID:** `qOtYC2eCKW7VHK9M`
**Status:** Ativo

Comandos administrativos via Telegram.

```
TRIGGER COMANDOS → QUAL COMANDO?
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
  QUERY STATUS    QUERY FILA      QUERY STATS
        │               │               │
        ▼               ▼               ▼
  QUERY PUBLICADOS FORMATAR FILA  FORMATAR STATS
        │               │               │
        ▼               ▼               ▼
  FORMATAR STATUS  ENVIAR FILA    ENVIAR STATS
        │
        ▼
  ENVIAR STATUS
```

**Comandos Disponiveis:**
- `/status` - Status atual do sistema (drafts, aprovados, publicados)
- `/queue` - Fila de posts pendentes
- `/stats` - Estatisticas gerais

## Dependencias

- Supabase: Queries de status
- Telegram Bot: BlogDraftsBot

# Prompts de AI

Prompts utilizados pelos AI Agents nos workflows n8n do Blog System Automation.

## Estrutura

| Arquivo | Workflow | Node | Nota |
|---------|----------|------|------|
| `archiver.md` | WF2 | Archiver | 4/10 |
| `rewriter.md` | WF2 | Rewriter | 3/10 |
| `editor.md` | WF5 | AI AGENT EDITOR | **9/10** |
| `twitter.md` | WF7 | AI TWITTER | 7/10 |
| `linkedin.md` | WF7 | AI LINKEDIN | 2/10 |
| `instagram.md` | WF7 | AI INSTAGRAM | 2/10 |
| `newsletter.md` | WF8 | AI Agent | 3/10 |

## Modelo a Seguir

O prompt do **WF5 Editor** (`editor.md`) e o melhor do sistema, com nota 9/10.

**Caracteristicas:**
- Exemplos de interpretacao de feedback (few-shot conceitual)
- Regras DEVE/NAO PODE bem definidas
- Campo `changes_made[]` obrigatorio
- Constraints especificos (max chars)
- Output JSON estruturado

**Recomendacao:** Usar WF5 como template para melhorar os outros prompts.

## Prioridade de Melhoria

1. **CRITICO (Nota 2/10):** LinkedIn, Instagram
2. **ALTO (Nota 3/10):** Newsletter, Rewriter
3. **MEDIO (Nota 4/10):** Archiver

## Como Atualizar

Os prompts estao embedados nos nodes AI Agent de cada workflow.
Para atualizar:

1. Edite o arquivo `.md` correspondente
2. Copie o System Message para o node AI Agent no n8n
3. Teste o workflow
4. Documente mudancas aqui

## Formato dos Arquivos

Cada arquivo de prompt contem:

- **Metadata:** Workflow, Node, Modelo
- **System Message:** Prompt atual extraido do workflow
- **User Prompt:** Template com variaveis (quando aplicavel)
- **Output JSON:** Estrutura esperada
- **Nota de Qualidade:** Avaliacao e problemas
- **Sugestao de Melhoria:** Prompt recomendado (quando aplicavel)

## Changelog

| Data | Prompt | Mudanca |
|------|--------|---------|
| 04/01/2026 | Todos | Extracao inicial dos workflows |
| 19/12/2025 | newsletter | Criado para WF8 |
| 17/12/2025 | revision | Ajustado para Quick Edit |
| 12/12/2025 | * | Versao inicial |

# Contributing to Blog System Automation

Thank you for your interest in contributing to the Minerals Trading Daily blog automation system.

## Getting Started

### Prerequisites

- n8n instance (self-hosted or cloud)
- Supabase account
- API keys for: Anthropic, OpenAI, Google Gemini, Perplexity
- Telegram Bot tokens

### Setup

1. Clone the repository:
```bash
git clone https://github.com/bigodinhc/n8n-blog-automation.git
cd n8n-blog-automation
```

2. Import workflows to n8n:
```bash
./scripts/import_workflows.sh
```

3. Configure credentials in n8n (see `CLAUDE.md` for IDs)

4. Activate workflows in order: WF0 -> WF1 -> WF2 -> ...

## How to Contribute

### Reporting Bugs

1. Check if the issue already exists
2. Use the Bug Report template
3. Include workflow ID and execution logs
4. Provide steps to reproduce

### Suggesting Features

1. Use the Feature Request template
2. Explain the problem it solves
3. Consider impact on existing workflows

### Improving Prompts

Our AI prompts need improvement. Priority:

| Prompt | Current | Target |
|--------|---------|--------|
| LinkedIn | 2/10 | 8/10 |
| Instagram | 2/10 | 8/10 |
| Newsletter | 3/10 | 8/10 |
| Archiver | 4/10 | 7/10 |

Use the Prompt Improvement template and follow the pattern in `prompts/editor.md` (our 9/10 example).

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test in n8n
5. Update documentation if needed
6. Submit a Pull Request

## Code Standards

### Workflow JSONs

- Use descriptive node names (e.g., `BUSCAR POSTS DO DIA`, not `Supabase1`)
- Add comments in Code nodes
- Keep callback_data under 64 bytes (Telegram limit)
- Use consistent naming: `WF{N}_{description}.json`

### Prompts

Follow the structure in `prompts/`:
- Include metadata (Workflow, Node, Model)
- Document current vs suggested prompts
- Add quality rating with explanation
- Provide input/output examples

### Documentation

- Update `docs/BACKLOG.md` for new tasks
- Update `CLAUDE.md` for structural changes
- Use Portuguese for user-facing docs
- Use English for code comments

## Testing

Before submitting:

1. **Validate workflow structure:**
```bash
# Use n8n-mcp
mcp__n8n-mcp__n8n_validate_workflow id="WORKFLOW_ID"
```

2. **Test with real data** - Don't just check structure, run the workflow

3. **Verify Telegram callbacks** - Especially for approval flows

4. **Check database operations** - Ensure no orphan records

## Project Structure

```
n8n-blog-automation/
├── .github/          # GitHub templates
├── docs/             # Documentation
├── workflows/        # n8n workflow JSONs
├── prompts/          # AI prompt documentation
├── database/         # SQL schemas
├── scripts/          # Utility scripts
└── CLAUDE.md         # AI assistant instructions
```

## Getting Help

- Read `docs/ARCHITECTURE.md` for system overview
- Check `docs/BACKLOG.md` for known issues
- Review `prompts/README.md` for AI quality analysis

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

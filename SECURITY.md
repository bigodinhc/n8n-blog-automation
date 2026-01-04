# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main    | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability, please:

1. **Do NOT** open a public issue
2. Email the maintainers directly or use GitHub's private vulnerability reporting
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Considerations

### API Keys & Credentials

This project uses multiple API services. **Never commit:**
- Telegram Bot tokens
- Supabase service role keys
- Anthropic/OpenAI API keys
- Google API credentials

All credentials should be stored in:
- n8n credential store (recommended)
- Environment variables
- `.env` files (gitignored)

### Known Security Notes

1. **Telegram Callbacks**: Callback data is limited to 64 bytes. Current format uses short prefixes to avoid information leakage.

2. **Supabase RLS**: Ensure Row Level Security is properly configured for all tables.

3. **Webhook URLs**: n8n webhook URLs are semi-public. Use authentication where possible.

4. **AI Prompts**: Prompts may contain business logic. The `prompts/` directory is intentionally public in this repo for educational purposes.

## Best Practices

- Rotate API keys periodically
- Use n8n's credential encryption
- Enable 2FA on all service accounts
- Review workflow permissions before activation
- Monitor execution logs for anomalies

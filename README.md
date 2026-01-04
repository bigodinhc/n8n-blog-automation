<h1 align="center">
  <img src="https://n8n.io/favicon.ico" width="28" height="28" alt="n8n" />
  Blog System Automation
</h1>

<p align="center">
  <strong>Automated blog system for iron ore market intelligence</strong>
</p>

<p align="center">
  <a href="https://mineralstradingdaily.com.br">
    <img src="https://img.shields.io/badge/Live%20Site-mineralstradingdaily.com.br-blue?style=flat-square" alt="Live Site" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/n8n-1.70+-orange?style=flat-square&logo=n8n" alt="n8n" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=flat-square&logo=supabase" alt="Supabase" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude-Anthropic-000000?style=flat-square" alt="Claude" />
  <img src="https://img.shields.io/badge/GPT--4-OpenAI-412991?style=flat-square&logo=openai" alt="GPT-4" />
  <img src="https://img.shields.io/badge/Gemini-Google-4285F4?style=flat-square&logo=google" alt="Gemini" />
  <img src="https://img.shields.io/badge/WordPress-Publishing-21759B?style=flat-square&logo=wordpress" alt="WordPress" />
</p>

---

## Overview

End-to-end automated blog system for the iron ore commodities market, powering [Minerals Trading Daily](https://mineralstradingdaily.com.br).

**Features:**
- Automated news ingestion (RSS, Telegram, Apify scraping)
- AI-powered content generation (Anthropic Claude)
- Image generation (Google Gemini)
- Human-in-the-loop review via Telegram bots
- Multi-platform publishing (WordPress, Twitter/X)
- Daily newsletter with Platts IODEX pricing data

## Architecture

```
INGESTION              PROCESSING                    PUBLISHING

  RSS ──────┐                                        WordPress
  Telegram ─┼──► WF1 ──► WF2 ──► WF3 ──► WF4 ──► WF6 ──► WF6.5 ─┬──► Blog
  Apify ────┘    Feed   Content  Draft  Approve  Image  Publish │
                         │         │                            │
                         │         ▼                            ├──► Twitter
                         │     Feedback                         │
                         │      WF4.5                           ├──► LinkedIn*
                         │         │                            │
                         ▼         ▼                            └──► Instagram*
                      WF5 ◄── Revision
                                   │
  Schedule 17h ──────► WF8 ──► WF8.1 ──────────────────────────────► Email*
                    Newsletter

  * = pending integration
```

## Project Structure

```
n8n-blog-automation/
├── .github/                    # GitHub templates & workflows
│   ├── ISSUE_TEMPLATE/         # Bug, feature, prompt templates
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md         # Technical architecture
│   ├── BACKLOG.md              # Tasks & roadmap
│   ├── SEO_ANALYSIS.md         # SEO audit
│   └── workflows/              # Pipeline documentation
├── workflows/                  # n8n workflow JSONs
│   ├── 00-utils/               # Error handler, alerts
│   ├── 01-content-pipeline/    # WF1-WF5
│   ├── 02-image-pipeline/      # WF6, WF6.5
│   ├── 03-social-pipeline/     # WF7, WF7.1, WF7.2
│   └── 04-newsletter-pipeline/ # WF8, WF8.1
├── prompts/                    # AI prompt documentation
│   ├── archiver.md             # Content generation (4/10)
│   ├── editor.md               # Revision (9/10) ★ BEST
│   ├── twitter.md              # Social threads (7/10)
│   ├── linkedin.md             # Professional posts (2/10)
│   ├── instagram.md            # Visual captions (2/10)
│   └── newsletter.md           # Daily digest (3/10)
├── database/
│   └── schema.sql              # Supabase schema
├── scripts/
│   ├── export_workflows.sh
│   └── import_workflows.sh
├── CLAUDE.md                   # AI assistant context
├── CONTRIBUTING.md             # Contribution guide
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── LICENSE                     # MIT
```

## Workflows (18 active)

### Content Pipeline
| ID | Name | Function |
|----|------|----------|
| WF1 | Feed Supabase | Data ingestion (RSS, Telegram, Apify) |
| WF2 | Content Archiver | AI generates structured article |
| WF3 | Draft Review | Telegram preview with buttons |
| WF4 | Callback Drafts | Process approval/rejection |
| WF4.5 | Feedback Capture | Capture text feedback |
| WF4.6 | Quick Edit Capture | Capture inline edits |
| WF4.7 | Quick Edit Callbacks | Process quick edits |
| WF5 | Revision Processor | AI applies revisions |

### Image Pipeline
| ID | Name | Function |
|----|------|----------|
| WF6 | Image Generator | GPT-4 prompt → Gemini image |
| WF6.5 | Image Approval | Approve & publish to WordPress |

### Social Media Pipeline
| ID | Name | Function |
|----|------|----------|
| WF7 | Social Media Factory | AI generates content for 3 platforms |
| WF7.1 | Social Callback | Publish to networks |
| WF7.2 | Image Callback | Approve social images |

### Newsletter Pipeline
| ID | Name | Function |
|----|------|----------|
| WF8 | Newsletter Generator | Daily newsletter (5pm) |
| WF8.1 | Newsletter Callback | Process approval & send |

### Utilities
| ID | Name | Function |
|----|------|----------|
| WF0 | Error Handler | Centralized error handling |
| Alerts | Proactive Alerts | System monitoring (2h intervals) |
| CMD | Telegram Commands | Admin commands (/status, /queue) |

## Integrations

| Service | Purpose | Status |
|---------|---------|--------|
| **Supabase** | PostgreSQL database | Active |
| **Telegram** | Review interface (3 bots) | Active |
| **Anthropic Claude** | Content AI | Active |
| **OpenAI GPT-4** | Image prompts | Active |
| **Google Gemini** | Image generation | Active |
| **Perplexity** | Market research | Active |
| **WordPress** | Blog publishing | Active |
| **Twitter/X** | Thread publishing | Active |
| **LinkedIn** | Professional posts | Pending |
| **Instagram** | Visual posts | Pending |
| **SendGrid** | Newsletter delivery | Pending |

## Quick Start

### Prerequisites
- n8n instance (self-hosted or cloud)
- Supabase project
- API credentials (see [CLAUDE.md](CLAUDE.md))

### Installation

```bash
# Clone repository
git clone https://github.com/bigodinhc/n8n-blog-automation.git
cd n8n-blog-automation

# Import workflows to n8n
./scripts/import_workflows.sh
```

### Configuration

1. Create credentials in n8n for each service
2. Update credential IDs in workflows (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md))
3. Activate workflows in order: WF0 → WF1 → WF2 → ...

## AI Prompt Quality

| Prompt | Score | Priority |
|--------|-------|----------|
| Editor (WF5) | **9/10** | Reference model |
| Twitter (WF7) | 7/10 | Good |
| Archiver (WF2) | 4/10 | Needs improvement |
| Newsletter (WF8) | 3/10 | Needs improvement |
| LinkedIn (WF7) | **2/10** | Critical |
| Instagram (WF7) | **2/10** | Critical |

See [prompts/README.md](prompts/README.md) for detailed analysis and improvement suggestions.

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Complete technical architecture |
| [BACKLOG.md](docs/BACKLOG.md) | Tasks, priorities, and roadmap |
| [SEO_ANALYSIS.md](docs/SEO_ANALYSIS.md) | Website SEO audit |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

**Priority areas:**
1. Improve LinkedIn/Instagram prompts (2/10 → 8/10)
2. Add few-shot examples to prompts
3. Activate and test Error Handler (WF0)
4. LinkedIn/Instagram API integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with n8n, Supabase, and AI</sub>
</p>

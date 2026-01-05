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
INGESTION              PROCESSING                           PUBLISHING

  RSS ──────┐                                               WordPress
  Telegram ─┼──► WF001 ──► WF002 ──► WF003 ──► WF004 ──► WF006 ──► WF006a ─┬──► Blog
  Apify ────┘    Feed     Content   Draft    Approve   Image    Publish  │
                            │         │                                   │
                            │         ▼                                   ├──► Twitter
                            │     Feedback                                │
                            │      WF004a                                 ├──► LinkedIn*
                            │         │                                   │
                            ▼         ▼                                   └──► Instagram*
                         WF005 ◄── Revision
                                      │
  Schedule 17h ──────► WF008 ──► WF008a ──────────────────────────────────► Email*
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

> Naming convention: `WF[XXX]_[type]_[description]` - See [NAMING_CONVENTIONS.md](NAMING_CONVENTIONS.md)

### Content Pipeline
| Workflow | Function |
|----------|----------|
| WF001_content_feed_ingestion | Data ingestion (RSS, Telegram, Apify) |
| WF002_content_ai_generator | AI generates structured article |
| WF003_content_draft_preview | Telegram preview with buttons |
| WF004_content_approval_callback | Process approval/rejection |
| WF004a_content_feedback_capture | Capture text feedback |
| WF004b_content_quick_edit_capture | Capture inline edits |
| WF004c_content_quick_edit_callback | Process quick edits |
| WF005_content_revision_processor | AI applies revisions |
| WF005a_seo_enrichment | SEO optimization with Perplexity+AI |
| WF005b_seo_approval_callback | Process SEO approval |

### Image Pipeline
| Workflow | Function |
|----------|----------|
| WF006_image_generator | GPT-4 prompt → Gemini image |
| WF006a_image_approval_publish | Approve & publish to WordPress |

### Social Media Pipeline
| Workflow | Function |
|----------|----------|
| WF007_social_content_factory | AI generates content for 3 platforms |
| WF007a_social_publish_callback | Publish to networks |
| WF007b_social_image_callback | Approve social images |

### Newsletter Pipeline
| Workflow | Function |
|----------|----------|
| WF008_newsletter_generator | Daily newsletter (5pm) |
| WF008a_newsletter_send_callback | Process approval & send |

### Utilities
| Workflow | Function |
|----------|----------|
| WF000_error_handler | Centralized error handling (active) |

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
3. Activate workflows in order: WF000 → WF001 → WF002 → ...

## AI Prompt Quality

| Prompt | Workflow | Score | Priority |
|--------|----------|-------|----------|
| Editor | WF005 | **9/10** | Reference model |
| Twitter | WF007 | 7/10 | Good |
| Archiver | WF002 | 7/10 | Updated 2026-01 |
| Newsletter | WF008 | 3/10 | Needs improvement |
| LinkedIn | WF007 | **2/10** | Critical |
| Instagram | WF007 | **2/10** | Critical |

See [prompts/README.md](prompts/README.md) for detailed analysis and improvement suggestions.

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Complete technical architecture |
| [BACKLOG.md](docs/BACKLOG.md) | Tasks, priorities, and roadmap |
| [ROADMAP_FINAL.md](improvements/ROADMAP_FINAL.md) | Unified improvement roadmap |
| [NAMING_CONVENTIONS.md](NAMING_CONVENTIONS.md) | Naming guidelines |
| [SEO_ANALYSIS.md](docs/SEO_ANALYSIS.md) | Website SEO audit |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

**Priority areas:**
1. Improve LinkedIn/Instagram prompts (2/10 → 8/10)
2. Add few-shot examples to prompts
3. Implement retry + idempotency (avoid duplicates)
4. LinkedIn/Instagram API integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with n8n, Supabase, and AI</sub>
</p>

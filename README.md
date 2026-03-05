# M365 Copilot Governance Dashboard

> **The world reference tool for Microsoft 365 Copilot AI governance.**

An open-source, static web application that enables Azure tenant administrators to **map, configure, and export** all Microsoft 365 Copilot AI admin settings across multi-tenant environments.

[![License: MIT](https://img.shields.io/badge/License-MIT-7B2FF7.svg)](LICENSE)
[![Built with Vite](https://img.shields.io/badge/Built%20with-Vite-646CFF.svg)](https://vitejs.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6.svg)](https://typescriptlang.org/)

---

## ✨ Features

### 🎛️ Settings Management

- **60+ admin settings** across 10 categories (User Access, Data Privacy, Copilot Actions, Teams, SharePoint, Exchange, Purview, Agent Governance, Power Platform, Security)
- Toggle, select, and configure each setting with visual feedback
- Admin path references for each setting (click-to-navigate)

### 🏢 Multi-Tenant Profiles

- Create, switch, and manage multiple tenant configurations
- Import/export profiles as JSON for team sharing
- All data stored locally in `localStorage` — no backend required

### 📤 Export & Reporting

- **JSON Export**: Full configuration with metadata for admin sharing
- **HTML Report**: Print-ready, styled governance report for stakeholders
- **Profile Export**: Portable profile backup for cross-device sync

### 🎨 Customizable Themes

| Theme | Description |
|-------|-------------|
| 🌙 **Dark** | Default — Copilot purple gradients with glassmorphism |
| ☀️ **Light** | Clean white with purple accents |
| ⬛ **AMOLED** | Pure black (`#000000`) for OLED energy savings |
| 🔴 **Webuild** | Corporate brand — Cardinal red `#DC2B33` |

### 🗺️ Roadmap Tracking (50+ Features)

- Full historical tracking since **January 2024**
- Categories: Now Available, Coming Soon, Frontier, Released 2025, Released 2024
- Inspired by the official [Microsoft 365 Roadmap](https://www.microsoft.com/en-us/microsoft-365/roadmap)

### 🌍 Regional Impact Analysis

Each roadmap feature includes regulatory analysis for:

- 🇪🇺 **Europe** — GDPR, EU AI Act, EU Data Boundary, Works Council
- 🇺🇸 **Americas** — CCPA, SOX, state privacy laws
- 🇸🇦 **Middle East** — UAE PDPL, Saudi PDPL, data sovereignty

### 📈 Analytics Dashboard

- 🛡️ **Governance Readiness Score** with actionable recommendations
- 📊 **Category Coverage** progress bars per tenant profile
- 📅 **Feature Timeline** bar chart across years
- 🌍 **Regional Availability** overview

### 📋 Settings Changelog

- Versioned history of Microsoft's setting changes
- Track additions, modifications, and removals over time

### 🔍 Gap Analysis (HQ vs Tenant)

- **Import tenant snapshots** extracted via PowerShell/bash scripts
- **Side-by-side comparison**: HQ golden config vs live tenant settings
- **Compliance Score**: weighted percentage based on setting impact
- **Status breakdown**: ✅ Compliant / ⚠️ Divergent / ❌ Missing / 🔶 Partial
- **Export gap reports** as HTML (print-ready) or JSON (machine-readable)
- **Demo mode**: try the gap analysis with built-in sample data

### 📸 Tenant Snapshot Scripts

Extract live settings from any tenant for gap analysis:

```powershell
# PowerShell (full extraction via Graph API + admin modules)
.\scripts\tenant-snapshot.ps1 -TenantName "contoso"

# Bash (lightweight extraction via Microsoft Graph CLI)
./scripts/tenant-snapshot.sh
```

Supports: Teams, SharePoint, Purview/DLP, Entra ID (Conditional Access), licensing, and more.

### 🔄 Automated Roadmap Sync

GitHub Action (`.github/workflows/sync-roadmap.yml`) that runs weekly to:

1. Authenticate with Microsoft Graph API
2. Fetch Message Center announcements filtered for Copilot
3. Compare against existing `roadmap.json`
4. Open a Pull Request with new items if any found

---

## 🚀 Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) 18+
- npm 9+

### Development

```bash
git clone https://github.com/sev7enITA/AzGovernanceAI.git
cd copilot-governance-dashboard
npm install
npm run dev
```

Open **<http://localhost:5173>** in your browser.

### Production Build

```bash
npm run build
```

The `dist/` folder contains static files ready for deployment.

---

## 🌐 Deploy to Hostinger

1. Run `npm run build`
2. Upload the contents of the `dist/` folder to your Hostinger `public_html` directory
3. Done! No server configuration needed — it's a static site.

> **Tip:** You can also zip the `dist/` contents and use Hostinger's File Manager to upload and extract.

---

## 📁 Project Structure

```
copilot-governance-dashboard/
├── index.html              # App shell with SEO meta tags
├── vite.config.ts          # Vite config (relative base path)
├── tsconfig.json           # TypeScript configuration
├── package.json            # Dependencies & scripts
├── src/
│   ├── main.ts             # Application orchestrator
│   ├── style.css           # Design system (themes, components)
│   ├── data/
│   │   ├── settings.json   # 60+ settings registry
│   │   ├── changelog.json  # Settings change history
│   │   └── roadmap.json    # 50+ roadmap features (2024–2026)
│   └── utils/
│       ├── storage.ts      # LocalStorage profile management
│       ├── export.ts       # JSON & HTML export generators
│       └── filter.ts       # Search & filter utilities
├── scripts/
│   ├── tenant-snapshot.ps1 # PowerShell tenant extraction
│   ├── tenant-snapshot.sh  # Bash wrapper via mgc CLI
│   └── sync-roadmap.ts     # Graph API roadmap sync
├── .github/workflows/
│   └── sync-roadmap.yml    # Weekly roadmap sync automation
├── public/favicon.svg
├── README.md
├── LICENSE                 # MIT License
└── CONTRIBUTING.md
```

---

## 🛠️ Tech Stack

- **Vite** — Lightning-fast build tool
- **TypeScript** — Type-safe application code
- **Vanilla CSS** — Custom design system with CSS custom properties
- **Zero backend** — Pure client-side, all data in `localStorage`

---

## 📊 Data Sources

Settings and roadmap data are sourced from official Microsoft documentation:

- [Microsoft 365 Admin Center](https://admin.microsoft.com/)
- [Microsoft 365 Roadmap](https://www.microsoft.com/en-us/microsoft-365/roadmap)
- [Microsoft Purview Compliance](https://compliance.microsoft.com/)
- [Microsoft Learn — Copilot](https://learn.microsoft.com/microsoft-365-copilot/)

> ⚠️ **Disclaimer**: This tool is for informational and planning purposes. Always verify settings in your actual admin centers. This is an independent open-source project and is not affiliated with Microsoft.

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ideas for Contribution

- Add new Copilot settings as Microsoft releases them
- Expand roadmap data with new features
- Add translations (i18n)
- Improve analytics visualizations
- Add PowerShell script generation from configurations

---

## 📬 Contact

**Fabrizio Degni** — Chief AI Officer, Ethics & AI Governance

- 📧 [io@fabriziodegni.com](mailto:io@fabriziodegni.com)
- 💼 [LinkedIn](https://www.linkedin.com/in/fdegni/)
- 🐙 [GitHub](https://github.com/sev7enITA)

For bug reports and feature requests, please use [GitHub Issues](https://github.com/sev7enITA/AzGovernanceAI/issues).

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for full text.

Built with ❤️ by **Fabrizio Degni** — [ETIKAI](https://github.com/sev7enITA) · Ethics & AI Governance

---

## 🔗 Links

- 🐛 [Report Issues](https://github.com/sev7enITA/AzGovernanceAI/issues)
- 💬 [Discussions](https://github.com/sev7enITA/AzGovernanceAI/discussions)
- 💼 [LinkedIn](https://www.linkedin.com/in/fdegni/)

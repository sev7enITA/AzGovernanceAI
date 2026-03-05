# Contributing to M365 Copilot Governance Dashboard

Thank you for your interest in contributing! This project aims to be the world reference tool for Microsoft 365 Copilot governance.

## How to Contribute

### 📝 Updating Settings Data

As Microsoft adds, removes, or modifies Copilot admin settings, the data files need updating:

1. **Settings** — Edit `src/data/settings.json` to add/modify entries
2. **Changelog** — Add a new entry to `src/data/changelog.json` with the date and changes
3. **Roadmap** — Update `src/data/roadmap.json` with new feature announcements

### 🌍 Adding Regional Impact Data

Each roadmap item can include regional impact analysis. When adding items, include:

- **Europe**: GDPR, EU AI Act, EU Data Boundary implications
- **Americas**: CCPA, SOX, state privacy law considerations
- **Middle East**: UAE PDPL, Saudi PDPL, data sovereignty requirements

### 🎨 Themes

To add a new theme:

1. Add a new `[data-theme="your-theme"]` block in `src/style.css`
2. Override the CSS custom properties defined in `:root`
3. Add the theme entry in the `THEMES` array in `src/main.ts`

### 🔧 Development Setup

```bash
git clone https://github.com/sev7enITA/AzGovernanceAI.git
cd copilot-governance-dashboard
npm install
npm run dev       # Start dev server at localhost:5173
npm run build     # Production build to dist/
```

### 📋 Pull Request Guidelines

1. Fork the repository and create a feature branch
2. Make your changes with clear commit messages
3. Ensure `npm run build` passes without errors
4. Submit a pull request with a descriptive title and summary
5. Reference any related issues

### 🐛 Reporting Issues

When reporting issues, please include:

- Browser and OS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

### 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Built with ❤️ by the ETIKAI community

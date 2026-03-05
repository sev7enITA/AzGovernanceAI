/**
 * export.ts — Configuration export utilities (JSON & HTML)
 *
 * Generates enriched JSON exports with full setting metadata and
 * styled, print-ready HTML governance reports for stakeholders.
 *
 * @license MIT
 * @copyright 2026 ETIKAI
 */
// Export utilities for JSON and HTML export

import settingsData from '../data/settings.json';

interface ExportConfig {
  profileName: string;
  settings: Record<string, any>;
  exportDate: string;
  version: string;
}

export function generateJsonExport(profileName: string, settings: Record<string, any>): string {
  const config: ExportConfig = {
    profileName,
    settings,
    exportDate: new Date().toISOString(),
    version: settingsData.version,
  };

  // Enrich with setting metadata
  const enrichedSettings: any[] = [];
  for (const category of settingsData.categories) {
    const catSettings: any[] = [];
    for (const setting of category.settings) {
      const value = settings[setting.id] ?? setting.defaultValue;
      catSettings.push({
        id: setting.id,
        name: setting.name,
        category: category.name,
        adminPath: setting.adminPath,
        configuredValue: value,
        defaultValue: setting.defaultValue,
        recommendedValue: setting.recommendedValue,
        isModified: value !== setting.defaultValue,
        impact: setting.impact,
        status: setting.status,
      });
    }
    enrichedSettings.push({
      category: category.name,
      adminCenter: category.adminCenter,
      settings: catSettings,
    });
  }

  return JSON.stringify({ ...config, categories: enrichedSettings }, null, 2);
}

export function generateHtmlExport(profileName: string, settings: Record<string, any>): string {
  const date = new Date().toLocaleDateString('en-US', {
    year: 'numeric', month: 'long', day: 'numeric',
  });

  let html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>M365 Copilot Governance Report — ${profileName}</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { font-family: 'Segoe UI', Inter, -apple-system, sans-serif; background:#f8fafc; color:#1e293b; line-height:1.6; }
    .container { max-width:900px; margin:0 auto; padding:40px 24px; }
    .header { text-align:center; margin-bottom:40px; padding-bottom:24px; border-bottom:2px solid #e2e8f0; }
    .header h1 { font-size:28px; color:#1e293b; margin-bottom:8px; }
    .header p { color:#64748b; font-size:14px; }
    .header .badge { display:inline-block; background:linear-gradient(135deg,#7B2FF7,#2196F3); color:white; padding:4px 16px; border-radius:20px; font-size:12px; font-weight:600; margin-top:8px; }
    .category { margin-bottom:32px; }
    .category h2 { font-size:20px; color:#1e293b; margin-bottom:4px; padding-bottom:8px; border-bottom:1px solid #e2e8f0; }
    .category .admin-center { font-size:12px; color:#64748b; margin-bottom:16px; }
    table { width:100%; border-collapse:collapse; margin-bottom:16px; }
    th { text-align:left; padding:10px 12px; background:#f1f5f9; color:#475569; font-size:12px; text-transform:uppercase; letter-spacing:0.05em; border-bottom:2px solid #e2e8f0; }
    td { padding:10px 12px; border-bottom:1px solid #f1f5f9; font-size:13px; vertical-align:top; }
    tr:hover td { background:#f8fafc; }
    .value { font-weight:600; }
    .value.modified { color:#7B2FF7; }
    .value.default { color:#64748b; }
    .impact { display:inline-block; padding:2px 8px; border-radius:10px; font-size:11px; font-weight:600; }
    .impact.high { background:#fef2f2; color:#ef4444; }
    .impact.medium { background:#fffbeb; color:#f59e0b; }
    .impact.low { background:#f0fdf4; color:#10b981; }
    .status { display:inline-block; padding:2px 8px; border-radius:10px; font-size:11px; }
    .status.active { background:#f0fdf4; color:#10b981; }
    .status.preview { background:#f5f3ff; color:#8b5cf6; }
    .footer { text-align:center; color:#94a3b8; font-size:12px; margin-top:40px; padding-top:24px; border-top:1px solid #e2e8f0; }
    .summary { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:16px; margin-bottom:32px; }
    .summary-card { background:white; border:1px solid #e2e8f0; border-radius:12px; padding:20px; text-align:center; }
    .summary-card .number { font-size:32px; font-weight:800; background:linear-gradient(135deg,#7B2FF7,#2196F3); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
    .summary-card .label { font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.05em; }
    @media print { body { background:white; } .container { max-width:100%; padding:20px; } }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>M365 Copilot Governance Report</h1>
      <p>Profile: <strong>${profileName}</strong> — Generated: ${date}</p>
      <div class="badge">Copilot Governance Dashboard v${settingsData.version}</div>
    </div>`;

  // Summary stats
  let totalSettings = 0;
  let modifiedSettings = 0;
  let highImpactModified = 0;

  for (const category of settingsData.categories) {
    for (const setting of category.settings) {
      totalSettings++;
      const value = settings[setting.id] ?? setting.defaultValue;
      if (value !== setting.defaultValue) {
        modifiedSettings++;
        if (setting.impact === 'high') highImpactModified++;
      }
    }
  }

  html += `
    <div class="summary">
      <div class="summary-card"><div class="number">${totalSettings}</div><div class="label">Total Settings</div></div>
      <div class="summary-card"><div class="number">${modifiedSettings}</div><div class="label">Modified</div></div>
      <div class="summary-card"><div class="number">${highImpactModified}</div><div class="label">High Impact Modified</div></div>
      <div class="summary-card"><div class="number">${settingsData.categories.length}</div><div class="label">Categories</div></div>
    </div>`;

  for (const category of settingsData.categories) {
    html += `
    <div class="category">
      <h2>${category.icon} ${category.name}</h2>
      <div class="admin-center">Admin Center: ${category.adminCenter}</div>
      <table>
        <thead>
          <tr><th>Setting</th><th>Configured Value</th><th>Default</th><th>Impact</th><th>Status</th></tr>
        </thead>
        <tbody>`;

    for (const setting of category.settings) {
      const value = settings[setting.id] ?? setting.defaultValue;
      const isModified = value !== setting.defaultValue;
      const displayValue = typeof value === 'boolean' ? (value ? 'Enabled' : 'Disabled') : String(value);
      const displayDefault = typeof setting.defaultValue === 'boolean'
        ? (setting.defaultValue ? 'Enabled' : 'Disabled') : String(setting.defaultValue);

      html += `
          <tr>
            <td><strong>${setting.name}</strong><br><span style="color:#94a3b8;font-size:11px;">${setting.adminPath}</span></td>
            <td><span class="value ${isModified ? 'modified' : 'default'}">${displayValue}</span></td>
            <td style="color:#94a3b8">${displayDefault}</td>
            <td><span class="impact ${setting.impact}">${setting.impact}</span></td>
            <td><span class="status ${setting.status}">${setting.status}</span></td>
          </tr>`;
    }

    html += `
        </tbody>
      </table>
    </div>`;
  }

  html += `
    <div class="footer">
      <p>Generated by M365 Copilot Governance Dashboard &mdash; Open Source at github.com/sev7enITA/AzGovernanceAI</p>
      <p>This report is for informational purposes. Always verify settings in your actual admin centers.</p>
    </div>
  </div>
</body>
</html>`;

  return html;
}

export function downloadFile(content: string, filename: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function copyToClipboard(text: string): Promise<void> {
  return navigator.clipboard.writeText(text);
}

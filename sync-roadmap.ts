/**
 * sync-roadmap.ts — Automated Roadmap Sync via Microsoft Graph API
 *
 * Fetches Microsoft 365 Message Center announcements related to Copilot,
 * compares them against the existing roadmap.json, and outputs new items.
 *
 * Can be run:
 *  - Manually: npx tsx scripts/sync-roadmap.ts
 *  - Via GitHub Action: .github/workflows/sync-roadmap.yml
 *
 * Requires environment variables:
 *  - AZURE_TENANT_ID: Azure AD tenant ID
 *  - AZURE_CLIENT_ID: App registration client ID
 *  - AZURE_CLIENT_SECRET: App registration client secret
 *
 * The app registration needs:
 *  - API Permission: ServiceMessage.Read.All (Application)
 *
 * @license MIT
 * @copyright 2026 ETIKAI
 */

import * as fs from 'fs';
import * as path from 'path';

// ============================================================
// CONFIGURATION
// ============================================================

const GRAPH_TOKEN_URL = `https://login.microsoftonline.com/${process.env.AZURE_TENANT_ID}/oauth2/v2.0/token`;
const GRAPH_MC_URL = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages';
const ROADMAP_PATH = path.resolve(__dirname, '../src/data/roadmap.json');

// Keywords to filter Copilot-related announcements
const COPILOT_KEYWORDS = [
    'copilot', 'microsoft 365 copilot', 'copilot for', 'copilot in',
    'ai in', 'agent', 'copilot studio', 'copilot chat',
];

// ============================================================
// AUTH
// ============================================================

async function getAccessToken(): Promise<string> {
    const params = new URLSearchParams({
        client_id: process.env.AZURE_CLIENT_ID || '',
        client_secret: process.env.AZURE_CLIENT_SECRET || '',
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials',
    });

    const response = await fetch(GRAPH_TOKEN_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params.toString(),
    });

    if (!response.ok) {
        throw new Error(`Token request failed: ${response.status} ${await response.text()}`);
    }

    const data = await response.json() as { access_token: string };
    return data.access_token;
}

// ============================================================
// FETCH MESSAGE CENTER
// ============================================================

interface MCMessage {
    id: string;
    title: string;
    body: { content: string };
    startDateTime: string;
    lastModifiedDateTime: string;
    services: string[];
    tags: string[];
    category: string;
    severity: string;
    actionRequiredByDateTime?: string;
}

async function fetchCopilotMessages(token: string): Promise<MCMessage[]> {
    const allMessages: MCMessage[] = [];
    let url: string | null = `${GRAPH_MC_URL}?$top=100&$orderby=startDateTime desc`;

    while (url) {
        const response = await fetch(url, {
            headers: { Authorization: `Bearer ${token}` },
        });

        if (!response.ok) {
            throw new Error(`Graph API request failed: ${response.status} ${await response.text()}`);
        }

        const data = await response.json() as { value: MCMessage[]; '@odata.nextLink'?: string };
        allMessages.push(...data.value);
        url = data['@odata.nextLink'] || null;

        // Safety limit
        if (allMessages.length > 500) break;
    }

    // Filter for Copilot-related messages
    return allMessages.filter(msg => {
        const searchText = `${msg.title} ${msg.body?.content || ''}`.toLowerCase();
        return COPILOT_KEYWORDS.some(kw => searchText.includes(kw));
    });
}

// ============================================================
// PROCESS & DIFF
// ============================================================

interface RoadmapItem {
    id: string;
    title: string;
    description: string;
    date: string;
    category: string;
    tags: string[];
    impact: string;
}

function messageToRoadmapItem(msg: MCMessage): RoadmapItem {
    // Determine impact from severity
    const impact = msg.severity === 'critical' ? 'high'
        : msg.severity === 'major' ? 'medium'
            : 'low';

    // Extract date
    const date = msg.startDateTime
        ? new Date(msg.startDateTime).toISOString().substring(0, 10)
        : new Date().toISOString().substring(0, 10);

    // Clean description (strip HTML)
    const description = (msg.body?.content || msg.title)
        .replace(/<[^>]+>/g, ' ')
        .replace(/\s+/g, ' ')
        .trim()
        .substring(0, 300);

    // Derive category
    let category = 'Copilot Actions';
    const titleLower = msg.title.toLowerCase();
    if (titleLower.includes('teams')) category = 'Teams';
    else if (titleLower.includes('sharepoint') || titleLower.includes('onedrive')) category = 'SharePoint';
    else if (titleLower.includes('outlook') || titleLower.includes('exchange')) category = 'Exchange';
    else if (titleLower.includes('purview') || titleLower.includes('dlp') || titleLower.includes('compliance')) category = 'Purview';
    else if (titleLower.includes('security') || titleLower.includes('entra') || titleLower.includes('conditional')) category = 'Security';
    else if (titleLower.includes('agent') || titleLower.includes('copilot studio')) category = 'Agent Governance';
    else if (titleLower.includes('admin') || titleLower.includes('license')) category = 'Admin';

    // Build tags from services
    const tags = [...new Set([
        ...msg.services,
        ...msg.tags,
        category,
    ])].filter(Boolean).slice(0, 5);

    return {
        id: `mc-${msg.id}`,
        title: msg.title,
        description,
        date,
        category,
        tags,
        impact,
    };
}

function diffRoadmap(existing: any, newItems: RoadmapItem[]): RoadmapItem[] {
    // Get all existing IDs
    const existingIds = new Set<string>();
    for (const section of existing.sections) {
        for (const item of section.items) {
            existingIds.add(item.id);
            existingIds.add(item.title.toLowerCase()); // Also match by title
        }
    }

    // Filter truly new items
    return newItems.filter(item =>
        !existingIds.has(item.id) &&
        !existingIds.has(item.title.toLowerCase())
    );
}

// ============================================================
// MAIN
// ============================================================

async function main(): Promise<void> {
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log('║  M365 Copilot Governance — Roadmap Sync                ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    console.log('');

    // Validate env vars
    if (!process.env.AZURE_TENANT_ID || !process.env.AZURE_CLIENT_ID || !process.env.AZURE_CLIENT_SECRET) {
        console.error('❌ Missing environment variables: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET');
        console.error('');
        console.error('To set up:');
        console.error('  1. Create an App Registration in Azure AD');
        console.error('  2. Add API permission: ServiceMessage.Read.All (Application)');
        console.error('  3. Create a client secret');
        console.error('  4. Set the env vars and re-run');
        process.exit(1);
    }

    // 1. Authenticate
    console.log('[ℹ] Authenticating with Microsoft Graph...');
    const token = await getAccessToken();
    console.log('[✅] Authenticated successfully');

    // 2. Fetch Message Center
    console.log('[ℹ] Fetching Message Center announcements...');
    const messages = await fetchCopilotMessages(token);
    console.log(`[✅] Found ${messages.length} Copilot-related announcements`);

    // 3. Convert to roadmap items
    const newItems = messages.map(messageToRoadmapItem);

    // 4. Load existing roadmap
    console.log('[ℹ] Loading existing roadmap.json...');
    const existing = JSON.parse(fs.readFileSync(ROADMAP_PATH, 'utf-8'));

    // 5. Diff
    const trulyNew = diffRoadmap(existing, newItems);
    console.log(`[📊] ${trulyNew.length} new items not in roadmap.json`);

    if (trulyNew.length === 0) {
        console.log('[✅] Roadmap is up to date! No new items found.');
        process.exit(0);
    }

    // 6. Add new items to "Coming Soon" section
    const comingSoon = existing.sections.find((s: any) => s.id === 'coming-soon');
    if (comingSoon) {
        comingSoon.items.push(...trulyNew);
    }

    // 7. Update lastUpdated
    existing.lastUpdated = new Date().toISOString().substring(0, 10);

    // 8. Write back
    fs.writeFileSync(ROADMAP_PATH, JSON.stringify(existing, null, 2), 'utf-8');

    console.log('');
    console.log('╔══════════════════════════════════════════════════════════╗');
    console.log(`║  ✅ Added ${trulyNew.length} new items to roadmap.json              ║`);
    console.log('╠══════════════════════════════════════════════════════════╣');
    for (const item of trulyNew.slice(0, 10)) {
        console.log(`║  • ${item.title.substring(0, 52).padEnd(52)} ║`);
    }
    if (trulyNew.length > 10) {
        console.log(`║  ... and ${trulyNew.length - 10} more                                    ║`);
    }
    console.log('╚══════════════════════════════════════════════════════════╝');

    // Output for GitHub Actions
    if (process.env.GITHUB_OUTPUT) {
        fs.appendFileSync(process.env.GITHUB_OUTPUT,
            `new_items=${trulyNew.length}\n` +
            `summary=${trulyNew.map(i => i.title).join('; ')}\n`
        );
    }
}

main().catch(err => {
    console.error('❌ Sync failed:', err.message);
    process.exit(1);
});

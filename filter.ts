/**
 * filter.ts — Search and filter utilities for settings catalog
 *
 * Provides text search across names, descriptions, admin paths, and tags,
 * plus faceted filtering by impact level, status, and tag matching.
 *
 * @license MIT
 * @copyright 2026 ETIKAI
 */
// Search and filter utilities

export interface FilterState {
    query: string;
    impact: string | null;
    status: string | null;
    tags: string[];
}

export function createFilterState(): FilterState {
    return {
        query: '',
        impact: null,
        status: null,
        tags: [],
    };
}

export function matchesFilter(setting: any, filter: FilterState): boolean {
    // Text search
    if (filter.query) {
        const q = filter.query.toLowerCase();
        const searchable = [
            setting.name,
            setting.description,
            setting.adminPath,
            ...(setting.tags || []),
        ].join(' ').toLowerCase();
        if (!searchable.includes(q)) return false;
    }

    // Impact filter
    if (filter.impact && setting.impact !== filter.impact) return false;

    // Status filter
    if (filter.status && setting.status !== filter.status) return false;

    // Tags filter
    if (filter.tags.length > 0) {
        if (!filter.tags.some(t => setting.tags?.includes(t))) return false;
    }

    return true;
}

export function getAllTags(categories: any[]): string[] {
    const tags = new Set<string>();
    for (const cat of categories) {
        for (const s of cat.settings) {
            for (const t of (s.tags || [])) {
                tags.add(t);
            }
        }
    }
    return Array.from(tags).sort();
}

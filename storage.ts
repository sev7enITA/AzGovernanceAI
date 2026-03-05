/**
 * storage.ts — LocalStorage persistence for tenant profiles and settings
 *
 * Manages multi-tenant profile CRUD operations, setting values,
 * and import/export of profile configurations. No backend required.
 *
 * @license MIT
 * @copyright 2026 ETIKAI
 */
// Local Storage persistence for settings and profiles

const STORAGE_KEYS = {
    PROFILES: 'cgd_profiles',
    ACTIVE_PROFILE: 'cgd_active_profile',
    SETTINGS: 'cgd_settings',
};

export interface ProfileData {
    id: string;
    name: string;
    created: string;
    lastModified: string;
    settings: Record<string, any>;
}

export function getProfiles(): ProfileData[] {
    try {
        const data = localStorage.getItem(STORAGE_KEYS.PROFILES);
        return data ? JSON.parse(data) : [];
    } catch {
        return [];
    }
}

export function saveProfiles(profiles: ProfileData[]): void {
    localStorage.setItem(STORAGE_KEYS.PROFILES, JSON.stringify(profiles));
}

export function getActiveProfileId(): string | null {
    return localStorage.getItem(STORAGE_KEYS.ACTIVE_PROFILE);
}

export function setActiveProfileId(id: string): void {
    localStorage.setItem(STORAGE_KEYS.ACTIVE_PROFILE, id);
}

export function createProfile(name: string): ProfileData {
    const profile: ProfileData = {
        id: 'profile_' + Date.now().toString(36),
        name,
        created: new Date().toISOString(),
        lastModified: new Date().toISOString(),
        settings: {},
    };
    const profiles = getProfiles();
    profiles.push(profile);
    saveProfiles(profiles);
    return profile;
}

export function deleteProfile(id: string): void {
    const profiles = getProfiles().filter(p => p.id !== id);
    saveProfiles(profiles);
    if (getActiveProfileId() === id) {
        localStorage.removeItem(STORAGE_KEYS.ACTIVE_PROFILE);
    }
}

export function updateProfileSettings(profileId: string, settingId: string, value: any): void {
    const profiles = getProfiles();
    const profile = profiles.find(p => p.id === profileId);
    if (profile) {
        profile.settings[settingId] = value;
        profile.lastModified = new Date().toISOString();
        saveProfiles(profiles);
    }
}

export function getProfileSettings(profileId: string): Record<string, any> {
    const profiles = getProfiles();
    const profile = profiles.find(p => p.id === profileId);
    return profile?.settings || {};
}

export function exportProfileData(profileId: string): string {
    const profiles = getProfiles();
    const profile = profiles.find(p => p.id === profileId);
    return JSON.stringify(profile, null, 2);
}

export function importProfileData(json: string): ProfileData | null {
    try {
        const profile = JSON.parse(json) as ProfileData;
        profile.id = 'profile_' + Date.now().toString(36);
        const profiles = getProfiles();
        profiles.push(profile);
        saveProfiles(profiles);
        return profile;
    } catch {
        return null;
    }
}

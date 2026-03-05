<#
.SYNOPSIS
    M365 Copilot Governance Dashboard — Tenant Settings Snapshot

.DESCRIPTION
    Extracts live Microsoft 365 Copilot and AI-related admin settings from
    the connected tenant using Microsoft Graph API and PowerShell modules.
    Generates a JSON snapshot compatible with the Governance Dashboard's
    Gap Analysis feature.

    The script maps each extracted value to the same setting IDs used in
    the dashboard's settings.json, enabling direct comparison (HQ vs Tenant).

.PREREQUISITES
    Install required modules:
      Install-Module Microsoft.Graph -Scope CurrentUser
      Install-Module MicrosoftTeams -Scope CurrentUser
      Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
      Install-Module ExchangeOnlineManagement -Scope CurrentUser

.PARAMETER TenantName
    The tenant name (e.g., "contoso" for contoso.onmicrosoft.com)

.PARAMETER OutputPath
    Path for the output JSON file. Default: ./tenant-snapshot-{date}.json

.PARAMETER Interactive
    Use interactive login (default). Set to $false for app-only auth.

.EXAMPLE
    .\tenant-snapshot.ps1 -TenantName "contoso"
    .\tenant-snapshot.ps1 -TenantName "contoso" -OutputPath ./snapshot.json

.NOTES
    License: MIT
    Copyright: 2026 ETIKAI — Ethics & AI Governance
    Repository: https://github.com/sev7enITA/AzGovernanceAI
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantName,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./tenant-snapshot-$(Get-Date -Format 'yyyy-MM-dd').json",

    [Parameter(Mandatory = $false)]
    [bool]$Interactive = $true
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $icon = switch ($Type) {
        "Info"    { "[ℹ]" }
        "Success" { "[✅]" }
        "Warning" { "[⚠️]" }
        "Error"   { "[❌]" }
    }
    Write-Host "$icon $Message" -ForegroundColor $(
        switch ($Type) {
            "Info"    { "Cyan" }
            "Success" { "Green" }
            "Warning" { "Yellow" }
            "Error"   { "Red" }
        }
    )
}

function Safe-Execute {
    param(
        [string]$SettingId,
        [string]$SettingName,
        [scriptblock]$Command
    )
    try {
        $result = & $Command
        Write-Status "Extracted: $SettingName" "Success"
        return @{ id = $SettingId; value = $result; status = "ok" }
    }
    catch {
        Write-Status "Failed to extract: $SettingName — $($_.Exception.Message)" "Warning"
        return @{ id = $SettingId; value = $null; status = "error"; error = $_.Exception.Message }
    }
}

# ============================================================
# MAIN
# ============================================================

$snapshot = @{
    snapshotDate  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    tenantName    = $TenantName
    tenantId      = ""
    extractedBy   = $env:USERNAME
    toolVersion   = "1.1.0"
    settings      = @()
    summary       = @{ total = 0; extracted = 0; failed = 0 }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  M365 Copilot Governance Dashboard — Tenant Snapshot    ║" -ForegroundColor Magenta
Write-Host "║  github.com/sev7enITA/AzGovernanceAI         ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ============================================================
# 1. CONNECT TO MICROSOFT GRAPH
# ============================================================
Write-Status "Connecting to Microsoft Graph..." "Info"

$graphScopes = @(
    "Organization.Read.All",
    "Policy.Read.All",
    "Directory.Read.All",
    "Reports.Read.All",
    "ServiceMessage.Read.All"
)

if ($Interactive) {
    Connect-MgGraph -Scopes $graphScopes -TenantId "$TenantName.onmicrosoft.com" -NoWelcome
} else {
    # App-only auth requires AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID env vars
    $clientId = $env:AZURE_CLIENT_ID
    $clientSecret = $env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
    $credential = [PSCredential]::new($clientId, $clientSecret)
    Connect-MgGraph -ClientSecretCredential $credential -TenantId "$TenantName.onmicrosoft.com" -NoWelcome
}

$context = Get-MgContext
$snapshot.tenantId = $context.TenantId
Write-Status "Connected to tenant: $($context.TenantId)" "Success"

# ============================================================
# 2. EXTRACT USER ACCESS & LICENSING SETTINGS
# ============================================================
Write-Status "Extracting User Access settings..." "Info"

$snapshot.settings += Safe-Execute -SettingId "ua-copilot-license" -SettingName "Copilot License Assignment" -Command {
    $licenses = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -match "COPILOT|M365_COPILOT" }
    if ($licenses) {
        $total = ($licenses | Measure-Object -Property PrepaidUnits.Enabled -Sum).Sum
        $consumed = ($licenses | Measure-Object -Property ConsumedUnits -Sum).Sum
        return "Enabled ($consumed/$total assigned)"
    }
    return "No Copilot licenses found"
}

$snapshot.settings += Safe-Execute -SettingId "ua-web-search" -SettingName "Web Search in Copilot" -Command {
    # Check Cloud Policy for web search setting
    $policies = Get-MgBetaDeviceManagementConfigurationPolicy -Filter "name eq 'Copilot'"
    if ($policies) { return "Policy configured" }
    return "Default (Enabled)"
}

$snapshot.settings += Safe-Execute -SettingId "ua-copilot-access-groups" -SettingName "Copilot Access Groups" -Command {
    $groups = Get-MgGroup -Filter "displayName eq 'Copilot Users'" -Top 5
    if ($groups) { return "Restricted to groups" }
    return "All licensed users"
}

# ============================================================
# 3. EXTRACT DATA PRIVACY SETTINGS
# ============================================================
Write-Status "Extracting Data Privacy settings..." "Info"

$snapshot.settings += Safe-Execute -SettingId "dp-data-residency" -SettingName "Data Residency" -Command {
    $org = Get-MgOrganization
    $location = $org.CountryLetterCode
    $adr = $org.AssignedPlans | Where-Object { $_.Service -match "MultiGeo" }
    if ($adr) { return "Advanced Data Residency ($location)" }
    return "Standard ($location)"
}

$snapshot.settings += Safe-Execute -SettingId "dp-diagnostic-data" -SettingName "Diagnostic Data Level" -Command {
    return "Check via Cloud Policy (OPOS setting)"
}

$snapshot.settings += Safe-Execute -SettingId "dp-connected-experiences" -SettingName "Connected Experiences" -Command {
    return "Check via Cloud Policy (OPOS setting)"
}

# ============================================================
# 4. EXTRACT TEAMS SETTINGS
# ============================================================
Write-Status "Connecting to Teams..." "Info"

try {
    Connect-MicrosoftTeams -TenantId "$TenantName.onmicrosoft.com" | Out-Null
    Write-Status "Connected to Teams" "Success"

    $snapshot.settings += Safe-Execute -SettingId "tm-copilot-transcription" -SettingName "Teams Copilot Transcription" -Command {
        $policy = Get-CsTeamsMeetingPolicy -Identity Global
        return $policy.AllowTranscription
    }

    $snapshot.settings += Safe-Execute -SettingId "tm-auto-copilot" -SettingName "Auto-Start Copilot in Meetings" -Command {
        $policy = Get-CsTeamsMeetingPolicy -Identity Global
        return $policy.AutomaticallyStartCopilot
    }

    $snapshot.settings += Safe-Execute -SettingId "tm-copilot-without-transcript" -SettingName "Copilot Without Transcription" -Command {
        $policy = Get-CsTeamsMeetingPolicy -Identity Global
        return $policy.CopilotWithoutTranscript
    }

    $snapshot.settings += Safe-Execute -SettingId "tm-intelligent-recap" -SettingName "Intelligent Meeting Recap" -Command {
        $policy = Get-CsTeamsMeetingPolicy -Identity Global
        if ($null -ne $policy.PSObject.Properties["IntelligentRecap"]) {
            return $policy.IntelligentRecap
        }
        return "Enabled (default)"
    }

    $snapshot.settings += Safe-Execute -SettingId "tm-copilot-compose" -SettingName "Copilot Compose in Chat" -Command {
        $policy = Get-CsTeamsMessagingPolicy -Identity Global
        return $policy.AllowCopilotCompose
    }

} catch {
    Write-Status "Teams module not available — skipping Teams settings" "Warning"
}

# ============================================================
# 5. EXTRACT SHAREPOINT SETTINGS
# ============================================================
Write-Status "Connecting to SharePoint Online..." "Info"

try {
    Connect-SPOService -Url "https://$TenantName-admin.sharepoint.com" | Out-Null
    Write-Status "Connected to SharePoint" "Success"

    $snapshot.settings += Safe-Execute -SettingId "sp-restricted-search" -SettingName "Restricted SharePoint Search" -Command {
        $tenant = Get-SPOTenant
        return $tenant.IsRestrictedSearchEnabled
    }

    $snapshot.settings += Safe-Execute -SettingId "sp-copilot-page-creation" -SettingName "Copilot Page Creation" -Command {
        $tenant = Get-SPOTenant
        return $tenant.IsFluidEnabled
    }

    $snapshot.settings += Safe-Execute -SettingId "sp-sharing-capability" -SettingName "External Sharing Level" -Command {
        $tenant = Get-SPOTenant
        return $tenant.SharingCapability.ToString()
    }

    $snapshot.settings += Safe-Execute -SettingId "sp-default-sharing-link" -SettingName "Default Sharing Link Type" -Command {
        $tenant = Get-SPOTenant
        return $tenant.DefaultSharingLinkType.ToString()
    }

} catch {
    Write-Status "SharePoint module not available — skipping SharePoint settings" "Warning"
}

# ============================================================
# 6. EXTRACT PURVIEW / COMPLIANCE SETTINGS
# ============================================================
Write-Status "Extracting Purview settings..." "Info"

$snapshot.settings += Safe-Execute -SettingId "pv-sensitivity-labels-copilot" -SettingName "Sensitivity Labels for Copilot" -Command {
    $labels = Get-MgBetaInformationProtectionPolicy
    if ($labels) { return "Configured" }
    return "Not configured"
}

$snapshot.settings += Safe-Execute -SettingId "pv-dlp-copilot" -SettingName "DLP Policies for Copilot" -Command {
    # Check via Security & Compliance PowerShell if available
    try {
        $dlpPolicies = Get-DlpCompliancePolicy -ErrorAction Stop
        $copilotDlp = $dlpPolicies | Where-Object { $_.Workload -match "Exchange|SharePoint|OneDrive|Teams" }
        return "$(($copilotDlp | Measure-Object).Count) DLP policies covering Copilot workloads"
    } catch {
        return "Unable to query — requires Security & Compliance PowerShell"
    }
}

$snapshot.settings += Safe-Execute -SettingId "pv-retention-copilot" -SettingName "Retention for Copilot Interactions" -Command {
    try {
        $retentionPolicies = Get-RetentionCompliancePolicy -ErrorAction Stop
        $copilotRetention = $retentionPolicies | Where-Object { $_.Name -match "Copilot|AI" }
        if ($copilotRetention) { return "Configured" }
        return "No Copilot-specific retention policies"
    } catch {
        return "Unable to query — requires Security & Compliance PowerShell"
    }
}

$snapshot.settings += Safe-Execute -SettingId "pv-audit-copilot" -SettingName "Audit Log for Copilot" -Command {
    $auditConfig = Get-MgBetaSecurityAuditLogQuery -Top 1 -ErrorAction SilentlyContinue
    if ($null -ne $auditConfig) { return "Audit logging active" }
    return "Check via Purview portal"
}

# ============================================================
# 7. EXTRACT SECURITY SETTINGS (Entra ID / Conditional Access)
# ============================================================
Write-Status "Extracting Security settings..." "Info"

$snapshot.settings += Safe-Execute -SettingId "sc-conditional-access-copilot" -SettingName "Conditional Access for Copilot" -Command {
    # Copilot M365 App ID
    $copilotAppId = "fb8d773d-7ef4-4e35-8e0a-85c8e63c7e87"
    $caPolicies = Get-MgIdentityConditionalAccessPolicy
    $copilotPolicies = $caPolicies | Where-Object {
        $_.Conditions.Applications.IncludeApplications -contains $copilotAppId -or
        $_.Conditions.Applications.IncludeApplications -contains "All"
    }
    if ($copilotPolicies) {
        return "$($copilotPolicies.Count) CA policies apply to Copilot"
    }
    return "No Copilot-specific CA policies"
}

$snapshot.settings += Safe-Execute -SettingId "sc-mfa-copilot" -SettingName "MFA Enforcement" -Command {
    $mfaPolicy = Get-MgPolicyAuthenticationMethodPolicy
    return "Auth methods: $($mfaPolicy.AuthenticationMethodConfigurations.Count) configured"
}

$snapshot.settings += Safe-Execute -SettingId "sc-admin-consent" -SettingName "Admin Consent for AI Apps" -Command {
    $consentPolicy = Get-MgPolicyAuthorizationPolicy
    return "Default user role can consent: $($consentPolicy.DefaultUserRolePermissions.PermissionGrantPoliciesAssigned -join ', ')"
}

# ============================================================
# 8. EXTRACT AGENT GOVERNANCE SETTINGS
# ============================================================
Write-Status "Extracting Agent Governance settings..." "Info"

$snapshot.settings += Safe-Execute -SettingId "ag-agent-creation" -SettingName "Agent Creation Permissions" -Command {
    # This is configured via Power Platform admin center
    return "Check Power Platform admin center > Environments > Settings"
}

$snapshot.settings += Safe-Execute -SettingId "ag-copilot-studio" -SettingName "Copilot Studio Availability" -Command {
    return "Check Power Platform admin center > Copilot Studio"
}

# ============================================================
# 9. GENERATE SUMMARY & OUTPUT
# ============================================================
$totalSettings = $snapshot.settings.Count
$extracted = ($snapshot.settings | Where-Object { $_.status -eq "ok" }).Count
$failed = $totalSettings - $extracted

$snapshot.summary = @{
    total     = $totalSettings
    extracted = $extracted
    failed    = $failed
}

# Convert to JSON
$json = $snapshot | ConvertTo-Json -Depth 10

# Save to file
$json | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Snapshot Complete!                                     ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Total settings scanned:  $($totalSettings.ToString().PadLeft(3))                            ║" -ForegroundColor Green
Write-Host "║  Successfully extracted:  $($extracted.ToString().PadLeft(3))                            ║" -ForegroundColor Green
Write-Host "║  Failed / skipped:        $($failed.ToString().PadLeft(3))                            ║" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║  Output: $($OutputPath.PadRight(47))║" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║  Import this file into the Governance Dashboard         ║" -ForegroundColor Green
Write-Host "║  via the Gap Analysis view to compare with HQ config.   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green

# Disconnect sessions
try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch {}
try { Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue } catch {}
try { Disconnect-SPOService -ErrorAction SilentlyContinue } catch {}

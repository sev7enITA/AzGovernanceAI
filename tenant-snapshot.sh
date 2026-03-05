#!/usr/bin/env bash
# ============================================================
# M365 Copilot Governance Dashboard — Tenant Snapshot (Bash)
#
# Lightweight bash wrapper that uses Microsoft Graph CLI (mgc)
# to extract tenant settings. For full extraction, use the
# PowerShell script (tenant-snapshot.ps1).
#
# Prerequisites:
#   - Install mgc: https://learn.microsoft.com/graph/cli/installation
#   - Login: mgc login --scopes "Organization.Read.All Policy.Read.All"
#
# Usage:
#   ./tenant-snapshot.sh [output-file]
#
# License: MIT
# Copyright: 2026 ETIKAI — Ethics & AI Governance
# ============================================================

set -euo pipefail

OUTPUT_FILE="${1:-tenant-snapshot-$(date +%Y-%m-%d).json}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  M365 Copilot Governance — Tenant Snapshot (Bash/mgc)   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check mgc is available
if ! command -v mgc &> /dev/null; then
    echo "❌ Microsoft Graph CLI (mgc) not found."
    echo "   Install: https://learn.microsoft.com/graph/cli/installation"
    exit 1
fi

echo "[ℹ] Checking Graph CLI authentication..."
mgc me get --output json > /dev/null 2>&1 || {
    echo "[⚠️] Not logged in. Running: mgc login"
    mgc login --scopes "Organization.Read.All Policy.Read.All Directory.Read.All ServiceMessage.Read.All"
}

echo "[ℹ] Extracting tenant organization info..."
ORG_INFO=$(mgc organization list --output json 2>/dev/null || echo '[]')
TENANT_ID=$(echo "$ORG_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['value'][0]['id'] if d.get('value') else 'unknown')" 2>/dev/null || echo "unknown")
COUNTRY=$(echo "$ORG_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['value'][0].get('countryLetterCode','??') if d.get('value') else '??')" 2>/dev/null || echo "??")

echo "[✅] Tenant ID: $TENANT_ID (Country: $COUNTRY)"

# Build settings array
SETTINGS="[]"

add_setting() {
    local id="$1"
    local name="$2"
    local value="$3"
    local status="${4:-ok}"
    SETTINGS=$(echo "$SETTINGS" | python3 -c "
import sys, json
arr = json.load(sys.stdin)
arr.append({'id': '$id', 'value': $(python3 -c "import json; print(json.dumps('$value'))"), 'status': '$status'})
json.dump(arr, sys.stdout)
")
    echo "[✅] Extracted: $name"
}

# Extract Conditional Access policies
echo "[ℹ] Extracting Conditional Access policies..."
CA_COUNT=$(mgc identity conditional-access policies list --output json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('value',[])))" 2>/dev/null || echo "0")
add_setting "sc-conditional-access-copilot" "Conditional Access Policies" "$CA_COUNT policies found"

# Extract subscribed SKUs (licenses)
echo "[ℹ] Extracting license information..."
COPILOT_LICENSES=$(mgc subscribed-skus list --output json 2>/dev/null | python3 -c "
import sys, json
skus = json.load(sys.stdin).get('value', [])
copilot = [s for s in skus if 'COPILOT' in s.get('skuPartNumber','').upper() or 'M365_COPILOT' in s.get('skuPartNumber','').upper()]
if copilot:
    total = sum(s.get('prepaidUnits',{}).get('enabled',0) for s in copilot)
    consumed = sum(s.get('consumedUnits',0) for s in copilot)
    print(f'Enabled ({consumed}/{total} assigned)')
else:
    print('No Copilot licenses found')
" 2>/dev/null || echo "Unable to query")
add_setting "ua-copilot-license" "Copilot License Assignment" "$COPILOT_LICENSES"

# Extract authentication methods
echo "[ℹ] Extracting authentication methods..."
AUTH_METHODS=$(mgc policies authentication-methods-policy get --output json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
configs = d.get('authenticationMethodConfigurations', [])
print(f'{len(configs)} methods configured')
" 2>/dev/null || echo "Unable to query")
add_setting "sc-mfa-copilot" "Authentication Methods" "$AUTH_METHODS"

# Extract Message Center announcements (Copilot-related)
echo "[ℹ] Checking Message Center for Copilot announcements..."
MC_COUNT=$(mgc admin service-announcement messages list --output json --filter "contains(title,'Copilot')" --top 100 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(len(d.get('value', [])))
" 2>/dev/null || echo "0")
add_setting "mc-copilot-announcements" "Message Center Copilot Entries" "$MC_COUNT announcements found"

# Data residency
add_setting "dp-data-residency" "Data Residency" "Country: $COUNTRY"

# Generate final JSON
echo "[ℹ] Generating snapshot JSON..."
python3 -c "
import json, sys
snapshot = {
    'snapshotDate': '$TIMESTAMP',
    'tenantId': '$TENANT_ID',
    'tenantName': 'Extracted via mgc',
    'extractedBy': '$(whoami)',
    'toolVersion': '1.1.0',
    'settings': json.loads('''$SETTINGS'''),
    'summary': {
        'total': len(json.loads('''$SETTINGS''')),
        'extracted': len([s for s in json.loads('''$SETTINGS''') if s['status'] == 'ok']),
        'failed': len([s for s in json.loads('''$SETTINGS''') if s['status'] != 'ok'])
    }
}
with open('$OUTPUT_FILE', 'w') as f:
    json.dump(snapshot, f, indent=2)
print(f'[✅] Snapshot saved to: $OUTPUT_FILE')
"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Snapshot Complete!                                     ║"
echo "║  Import into the Dashboard via Gap Analysis view.       ║"
echo "╚══════════════════════════════════════════════════════════╝"

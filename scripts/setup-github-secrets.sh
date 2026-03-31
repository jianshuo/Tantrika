#!/usr/bin/env bash
# Setup GitHub Actions secrets for Tantrika (unsigned video version).
# Requires: gh CLI authenticated with repo access.
# Run: bash scripts/setup-github-secrets.sh

set -euo pipefail

REPO="jianshuo/Tantrika"

echo "Setting GitHub Actions secrets for $REPO"
echo ""

# 1. Supabase personal access token (for CLI — different from service role key)
#    Get it from: https://supabase.com/dashboard/account/tokens
#    Format: sbp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo -n "SUPABASE_ACCESS_TOKEN (from supabase.com/dashboard/account/tokens, format sbp_...): "
read -rs SUPABASE_ACCESS_TOKEN && echo
gh secret set SUPABASE_ACCESS_TOKEN --body "$SUPABASE_ACCESS_TOKEN" --repo "$REPO"

# 2. Service role key (for the Edge Function at runtime)
echo -n "SUPABASE_SERVICE_ROLE_KEY: "
read -rs SUPABASE_SERVICE_ROLE_KEY && echo
gh secret set SUPABASE_SERVICE_ROLE_KEY --body "$SUPABASE_SERVICE_ROLE_KEY" --repo "$REPO"

echo ""
echo "Done. Trigger the deploy with:"
echo "  gh workflow run deploy-supabase.yml --repo $REPO --field run_seed=true"

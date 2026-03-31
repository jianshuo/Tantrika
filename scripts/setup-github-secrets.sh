#!/usr/bin/env bash
# Setup GitHub Actions secrets for Tantrika.
# Requires: gh CLI authenticated with repo access.
# Run: bash scripts/setup-github-secrets.sh

set -euo pipefail

REPO="jianshuo/Tantrika"

echo "Setting GitHub Actions secrets for $REPO"
echo "You will be prompted for each value."
echo ""

# Supabase
echo -n "SUPABASE_ACCESS_TOKEN (from supabase.com/dashboard/account/tokens, format: sbp_...): "
read -rs SUPABASE_ACCESS_TOKEN && echo
gh secret set SUPABASE_ACCESS_TOKEN --body "$SUPABASE_ACCESS_TOKEN" --repo "$REPO"

echo -n "SUPABASE_DB_PASSWORD (Postgres password set when creating the project): "
read -rs SUPABASE_DB_PASSWORD && echo
gh secret set SUPABASE_DB_PASSWORD --body "$SUPABASE_DB_PASSWORD" --repo "$REPO"

echo -n "SUPABASE_SERVICE_ROLE_KEY: "
read -rs SUPABASE_SERVICE_ROLE_KEY && echo
gh secret set SUPABASE_SERVICE_ROLE_KEY --body "$SUPABASE_SERVICE_ROLE_KEY" --repo "$REPO"

# Cloudflare Stream
echo -n "CF_ACCOUNT_ID (2f33014654e1b826e27ab00d4e7242fd — press enter to use default): "
read -r CF_ACCOUNT_ID
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-2f33014654e1b826e27ab00d4e7242fd}"
gh secret set CF_ACCOUNT_ID --body "$CF_ACCOUNT_ID" --repo "$REPO"

echo -n "CF_STREAM_SIGNING_KEY_ID (from Cloudflare Stream → Security → Signing Keys): "
read -rs CF_STREAM_SIGNING_KEY_ID && echo
gh secret set CF_STREAM_SIGNING_KEY_ID --body "$CF_STREAM_SIGNING_KEY_ID" --repo "$REPO"

echo -n "CF_STREAM_SIGNING_SECRET (PEM private key — paste and press Ctrl+D when done): "
CF_STREAM_SIGNING_SECRET=$(cat)
echo
gh secret set CF_STREAM_SIGNING_SECRET --body "$CF_STREAM_SIGNING_SECRET" --repo "$REPO"

echo ""
echo "All secrets set. Trigger the deploy workflow with:"
echo "  gh workflow run deploy-supabase.yml --repo $REPO"

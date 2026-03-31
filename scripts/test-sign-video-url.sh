#!/usr/bin/env bash
# Test the get-video-url Edge Function end-to-end.
# Usage: bash scripts/test-sign-video-url.sh <user_jwt> [lesson_id]
#
# Free-preview lesson IDs (no subscription required):
#   b1000000-0000-0000-0000-000000000001  — The Ground of Being (Course 1)
#   b2000000-0000-0000-0000-000000000001  — The Sacred Container (Course 2)
#
# Paid lesson IDs (requires is_subscribed=true in profiles):
#   b1000000-0000-0000-0000-000000000002  — Breath as the Bridge

set -euo pipefail

SUPABASE_URL="https://oxjqrdjywuxkmnsvvsuh.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94anFyZGp5d3V4a21uc3Z2c3VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1ODI1MjcsImV4cCI6MjA5MDE1ODUyN30.J61REb7LkcWUjijYMGtGFkZzipEy6sGWgSgt9sDpu-o"

JWT="${1:-}"
LESSON_ID="${2:-b1000000-0000-0000-0000-000000000001}"

if [[ -z "$JWT" ]]; then
  echo "Usage: $0 <user_jwt> [lesson_id]"
  exit 1
fi

RESPONSE=$(curl -s -w "\n%{http_code}" \
  "$SUPABASE_URL/functions/v1/sign-video-url" \
  -H "Authorization: Bearer $JWT" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"lessonId\": \"$LESSON_ID\"}")

HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

echo "HTTP $HTTP_STATUS: $BODY"

if [[ "$HTTP_STATUS" == "200" ]]; then
  VIDEO_URL=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])" 2>/dev/null || echo "$BODY")
  echo ""
  echo "Video URL: $VIDEO_URL"
fi

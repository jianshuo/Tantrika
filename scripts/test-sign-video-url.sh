#!/usr/bin/env bash
# Test the sign-video-url Edge Function end-to-end.
# Usage: bash scripts/test-sign-video-url.sh <user_jwt> <lesson_id>
# Example:
#   JWT=$(curl -s -X POST "https://oxjqrdjywuxkmnsvvsuh.supabase.co/auth/v1/token?grant_type=password" \
#     -H "apikey: $ANON_KEY" -H "Content-Type: application/json" \
#     -d '{"email":"test@example.com","password":"test"}' | jq -r '.access_token')
#   bash scripts/test-sign-video-url.sh "$JWT" "b1000000-0000-0000-0000-000000000001"

set -euo pipefail

SUPABASE_URL="https://oxjqrdjywuxkmnsvvsuh.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94anFyZGp5d3V4a21uc3Z2c3VoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1ODI1MjcsImV4cCI6MjA5MDE1ODUyN30.J61REb7LkcWUjijYMGtGFkZzipEy6sGWgSgt9sDpu-o"

JWT="${1:-}"
LESSON_ID="${2:-b1000000-0000-0000-0000-000000000001}"

if [[ -z "$JWT" ]]; then
  echo "Usage: $0 <user_jwt> [lesson_id]"
  echo ""
  echo "Free-preview lesson IDs (no subscription required):"
  echo "  b1000000-0000-0000-0000-000000000001  — The Ground of Being (Course 1)"
  echo "  b2000000-0000-0000-0000-000000000001  — The Sacred Container (Course 2)"
  echo ""
  echo "Paid lesson IDs (requires is_subscribed=true):"
  echo "  b1000000-0000-0000-0000-000000000002  — Breath as the Bridge"
  echo "  b1000000-0000-0000-0000-000000000003  — The Witness and the Felt Sense"
  exit 1
fi

echo "Calling sign-video-url for lesson: $LESSON_ID"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" \
  "$SUPABASE_URL/functions/v1/sign-video-url" \
  -H "Authorization: Bearer $JWT" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"lessonId\": \"$LESSON_ID\"}")

HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -1)

echo "HTTP Status: $HTTP_STATUS"
echo "Response: $BODY"

if [[ "$HTTP_STATUS" == "200" ]]; then
  VIDEO_URL=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])" 2>/dev/null || echo "$BODY")
  echo ""
  echo "Video URL: $VIDEO_URL"
  echo ""
  echo "To verify the stream is playable, open in VLC or ffprobe:"
  echo "  ffprobe -v quiet -print_format json -show_streams \"$VIDEO_URL\""
fi

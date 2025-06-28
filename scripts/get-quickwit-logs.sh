#!/bin/bash

# Script to retrieve latest 10 log entries from Quickwit
# Uses Quickwit's search API to fetch recent logs

# Load cluster configuration
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/load-config.sh"

QUICKWIT_SEARCH_URL="${QUICKWIT_ENDPOINT}/api/v1/otel-logs-v0_7/search"

echo "Retrieving latest 10 logs from Quickwit central search service..."
echo "Endpoint: $QUICKWIT_SEARCH_URL"
echo "----------------------------------------"

# Query Quickwit for latest logs
# Using wildcard query (*) to get all logs, sorted by timestamp descending
RESPONSE=$(curl -s -X POST "$QUICKWIT_SEARCH_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "*",
    "max_hits": 10
  }')

echo "$RESPONSE" | jq -r '
if .hits and (.hits | length > 0) then
    .hits[] | 
    "Time: " + (.["@timestamp"] // .timestamp // "N/A") + 
    " | Level: " + (.severity_text // .level // .severity // "INFO") + 
    " | Service: " + (.service_name // .["service.name"] // "unknown") +
    " | Type: " + (.log_type // "security") +
    " | Message: " + (.body // .message // "No message")
elif .num_hits == 0 then
    "No logs found in Quickwit. This could mean:
- No security logs have been sent to the cluster yet  
- Quickwit index is empty
- Try sending test logs first: ./scripts/test-security-logs.sh"
else
    "Error querying Quickwit: " + (. | tostring)
end'

echo "----------------------------------------"
echo "Total logs retrieved: $(curl -s -X POST "$QUICKWIT_SEARCH_URL" -H "Content-Type: application/json" -d '{"query":"*","max_hits":0}' | jq -r '.num_hits // 0')"
echo ""
echo "To query specific log types:"
echo "  Security logs: curl -X POST '$QUICKWIT_SEARCH_URL' -H 'Content-Type: application/json' -d '{\"query\":\"log_type:security\",\"max_hits\":10}'"
echo "  Auth logs: curl -X POST '$QUICKWIT_SEARCH_URL' -H 'Content-Type: application/json' -d '{\"query\":\"category:auth\",\"max_hits\":10}'"
#!/bin/bash

# Script to retrieve latest 10 log entries from Loki
# Uses Loki's query API to fetch recent logs

# Load cluster configuration
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/load-config.sh"

# Loki external query endpoint (cluster provides central log collection)
LOKI_QUERY_URL="http://${CLUSTER_IP}:3100/loki/api/v1/query_range"

echo "Retrieving latest 10 logs from Loki central log collection service..."
echo "Endpoint: $LOKI_QUERY_URL"
echo "----------------------------------------"

# Calculate time range (last 24 hours for better results)
END_TIME=$(date +%s)000000000  # nanoseconds
START_TIME=$((END_TIME - 86400000000000))  # 24 hours ago in nanoseconds

# Query Loki for all recent logs
curl -s -G "$LOKI_QUERY_URL" \
    --data-urlencode "query={job=~\".+\"}" \
    --data-urlencode "start=$START_TIME" \
    --data-urlencode "end=$END_TIME" \
    --data-urlencode "limit=10" \
    --data-urlencode "direction=backward" | \
jq -r '
if .data and .data.result and (.data.result | length > 0) then
    .data.result[] | 
    .values[]? | 
    try (
        .[0] as $timestamp |
        .[1] as $log |
        ($timestamp | tonumber / 1000000000 | strftime("%Y-%m-%d %H:%M:%S")) as $formatted_time |
        try ($log | fromjson) as $parsed |
        if $parsed then
            "Time: " + $formatted_time + 
            " | Level: " + ($parsed.level // $parsed.severity // $parsed.severity_text // "INFO") + 
            " | Service: " + ($parsed.service_name // $parsed["service.name"] // "unknown") +
            " | Type: " + ($parsed.log_type // "operational") +
            " | Message: " + ($parsed.message // $parsed.body // "No message")
        else
            "Time: " + $formatted_time + " | Raw: " + $log
        end
    ) catch (
        .[0] as $timestamp |
        .[1] as $log |
        ($timestamp | tonumber / 1000000000 | strftime("%Y-%m-%d %H:%M:%S")) as $formatted_time |
        "Time: " + $formatted_time + " | Raw: " + $log
    )
else
    "No logs found in Loki. This could mean:
- No logs have been sent to the cluster yet
- Loki service is not accessible
- Try sending test logs first: ./scripts/test-operational-logs.sh"
end'

echo "----------------------------------------"
echo ""
echo "To query specific log types:"
echo "  Operational logs: curl -G 'http://${CLUSTER_IP}:3100/loki/api/v1/query_range' --data-urlencode 'query={log_type=\"operational\"}' --data-urlencode 'limit=10'"
echo "  Application logs: curl -G 'http://${CLUSTER_IP}:3100/loki/api/v1/query_range' --data-urlencode 'query={service_name=~\".+\"}' --data-urlencode 'limit=10'"
echo ""
echo "For real-time logs (tail): curl -G 'http://${CLUSTER_IP}:3100/loki/api/v1/tail' --data-urlencode 'query={job=~\".+\"}'"
#!/bin/bash

# Test script to send operational logs to Loki via OpenTelemetry Collector
# These logs should be classified as operational and routed to Loki

# Load cluster configuration
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/load-config.sh"

OTEL_ENDPOINT="${OTEL_HTTP_ENDPOINT}/v1/logs"

echo "Sending operational test logs to OTEL Collector -> Loki..."

# Test operational log with 15+ fields
curl -X POST "$OTEL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {"key": "service.name", "value": {"stringValue": "web-server"}},
            {"key": "service.version", "value": {"stringValue": "1.2.3"}},
            {"key": "deployment.environment", "value": {"stringValue": "production"}}
          ]
        },
        "scopeLogs": [
          {
            "logRecords": [
              {
                "timeUnixNano": "'$(date +%s%N)'",
                "severityNumber": 9,
                "severityText": "INFO",
                "body": {"stringValue": "Successfully processed HTTP request GET /api/users"},
                "attributes": [
                  {"key": "log_type", "value": {"stringValue": "operational"}},
                  {"key": "category", "value": {"stringValue": "application"}},
                  {"key": "http.method", "value": {"stringValue": "GET"}},
                  {"key": "http.url", "value": {"stringValue": "/api/users"}},
                  {"key": "http.status_code", "value": {"intValue": 200}},
                  {"key": "response_time_ms", "value": {"doubleValue": 45.2}},
                  {"key": "user_id", "value": {"stringValue": "user123"}},
                  {"key": "request_id", "value": {"stringValue": "req-abc-123"}},
                  {"key": "source_ip", "value": {"stringValue": "192.168.1.100"}},
                  {"key": "user_agent", "value": {"stringValue": "Mozilla/5.0"}},
                  {"key": "session_id", "value": {"stringValue": "sess-xyz-789"}},
                  {"key": "datacenter", "value": {"stringValue": "dc-west-1"}},
                  {"key": "container_id", "value": {"stringValue": "cont-def-456"}},
                  {"key": "pod_name", "value": {"stringValue": "web-server-7d9f8b-xz2q4"}},
                  {"key": "namespace", "value": {"stringValue": "production"}},
                  {"key": "cluster", "value": {"stringValue": "k3s-main"}}
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n\nSending application error log..."

# Test application error log
curl -X POST "$OTEL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {"key": "service.name", "value": {"stringValue": "database-service"}},
            {"key": "service.version", "value": {"stringValue": "2.1.0"}},
            {"key": "deployment.environment", "value": {"stringValue": "production"}}
          ]
        },
        "scopeLogs": [
          {
            "logRecords": [
              {
                "timeUnixNano": "'$(date +%s%N)'",
                "severityNumber": 17,
                "severityText": "ERROR",
                "body": {"stringValue": "Database connection timeout after 30 seconds"},
                "attributes": [
                  {"key": "log_type", "value": {"stringValue": "operational"}},
                  {"key": "category", "value": {"stringValue": "database"}},
                  {"key": "error.type", "value": {"stringValue": "ConnectionTimeout"}},
                  {"key": "error.message", "value": {"stringValue": "Connection timeout"}},
                  {"key": "database.name", "value": {"stringValue": "userdb"}},
                  {"key": "database.host", "value": {"stringValue": "db.internal"}},
                  {"key": "database.port", "value": {"intValue": 5432}},
                  {"key": "connection_pool_size", "value": {"intValue": 10}},
                  {"key": "active_connections", "value": {"intValue": 8}},
                  {"key": "query_duration_ms", "value": {"doubleValue": 30000.0}},
                  {"key": "retry_count", "value": {"intValue": 3}},
                  {"key": "transaction_id", "value": {"stringValue": "txn-abc-999"}},
                  {"key": "thread_id", "value": {"stringValue": "thread-42"}},
                  {"key": "memory_usage_mb", "value": {"doubleValue": 512.8}},
                  {"key": "cpu_usage_percent", "value": {"doubleValue": 85.5}},
                  {"key": "instance_id", "value": {"stringValue": "db-inst-123"}}
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n\nOperational test logs sent successfully!"
echo "Check Loki at http://loki.k3s.local for these logs"
echo "Or query Grafana with Loki datasource: {log_type=\"operational\"}"
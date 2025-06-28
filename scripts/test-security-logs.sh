#!/bin/bash

# Test script to send security logs to Quickwit via OpenTelemetry Collector
# These logs should be classified as security and routed to Quickwit

# Load cluster configuration
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/load-config.sh"

OTEL_ENDPOINT="${OTEL_HTTP_ENDPOINT}/v1/logs"

echo "Sending security test logs to OTEL Collector -> Quickwit..."

# Test authentication security log with 15+ fields
curl -X POST "$OTEL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {"key": "service.name", "value": {"stringValue": "ssh-server"}},
            {"key": "service.version", "value": {"stringValue": "8.9"}},
            {"key": "deployment.environment", "value": {"stringValue": "production"}}
          ]
        },
        "scopeLogs": [
          {
            "logRecords": [
              {
                "timeUnixNano": "'$(date +%s%N)'",
                "severityNumber": 13,
                "severityText": "WARN",
                "body": {"stringValue": "Failed SSH login attempt for user admin from 203.0.113.42"},
                "attributes": [
                  {"key": "log_type", "value": {"stringValue": "security"}},
                  {"key": "category", "value": {"stringValue": "auth"}},
                  {"key": "event_type", "value": {"stringValue": "authentication_failure"}},
                  {"key": "protocol", "value": {"stringValue": "SSH"}},
                  {"key": "username", "value": {"stringValue": "admin"}},
                  {"key": "source_ip", "value": {"stringValue": "203.0.113.42"}},
                  {"key": "source_port", "value": {"intValue": 54321}},
                  {"key": "destination_ip", "value": {"stringValue": "192.168.1.10"}},
                  {"key": "destination_port", "value": {"intValue": 22}},
                  {"key": "auth_method", "value": {"stringValue": "password"}},
                  {"key": "session_id", "value": {"stringValue": "ssh-sess-fail-123"}},
                  {"key": "geolocation", "value": {"stringValue": "Unknown"}},
                  {"key": "threat_level", "value": {"stringValue": "medium"}},
                  {"key": "failed_attempts_count", "value": {"intValue": 5}},
                  {"key": "time_window_minutes", "value": {"intValue": 10}},
                  {"key": "blocked_by_policy", "value": {"boolValue": false}},
                  {"key": "investigation_required", "value": {"boolValue": true}}
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n\nSending audit security log..."

# Test audit security log
curl -X POST "$OTEL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {"key": "service.name", "value": {"stringValue": "audit-daemon"}},
            {"key": "service.version", "value": {"stringValue": "3.0.7"}},
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
                "body": {"stringValue": "Privilege escalation: user john executed sudo command"},
                "attributes": [
                  {"key": "log_type", "value": {"stringValue": "security"}},
                  {"key": "category", "value": {"stringValue": "audit"}},
                  {"key": "event_type", "value": {"stringValue": "privilege_escalation"}},
                  {"key": "audit_id", "value": {"stringValue": "audit-12345"}},
                  {"key": "username", "value": {"stringValue": "john"}},
                  {"key": "command", "value": {"stringValue": "sudo systemctl restart nginx"}},
                  {"key": "working_directory", "value": {"stringValue": "/home/john"}},
                  {"key": "terminal", "value": {"stringValue": "pts/0"}},
                  {"key": "process_id", "value": {"intValue": 8765}},
                  {"key": "parent_process_id", "value": {"intValue": 1234}},
                  {"key": "effective_uid", "value": {"intValue": 0}},
                  {"key": "real_uid", "value": {"intValue": 1001}},
                  {"key": "session_id", "value": {"stringValue": "audit-sess-567"}},
                  {"key": "compliance_policy", "value": {"stringValue": "SOX-2024"}},
                  {"key": "risk_score", "value": {"intValue": 7}},
                  {"key": "requires_approval", "value": {"boolValue": false}},
                  {"key": "approved_by", "value": {"stringValue": "auto-approved"}}
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n\nSending firewall security log..."

# Test firewall security log
curl -X POST "$OTEL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [
      {
        "resource": {
          "attributes": [
            {"key": "service.name", "value": {"stringValue": "firewall"}},
            {"key": "service.version", "value": {"stringValue": "2.4.1"}},
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
                "body": {"stringValue": "Firewall blocked suspicious connection attempt - potential port scan detected"},
                "attributes": [
                  {"key": "log_type", "value": {"stringValue": "security"}},
                  {"key": "category", "value": {"stringValue": "security"}},
                  {"key": "event_type", "value": {"stringValue": "blocked_connection"}},
                  {"key": "attack_type", "value": {"stringValue": "port_scan"}},
                  {"key": "source_ip", "value": {"stringValue": "198.51.100.25"}},
                  {"key": "source_port", "value": {"intValue": 65432}},
                  {"key": "destination_ip", "value": {"stringValue": "192.168.1.100"}},
                  {"key": "destination_port", "value": {"intValue": 445}},
                  {"key": "protocol", "value": {"stringValue": "TCP"}},
                  {"key": "rule_id", "value": {"stringValue": "FW-RULE-1001"}},
                  {"key": "rule_action", "value": {"stringValue": "DENY"}},
                  {"key": "packet_count", "value": {"intValue": 50}},
                  {"key": "bytes_transferred", "value": {"intValue": 2048}},
                  {"key": "threat_intelligence", "value": {"stringValue": "Known bad actor"}},
                  {"key": "geographic_location", "value": {"stringValue": "RU"}},
                  {"key": "confidence_score", "value": {"doubleValue": 0.95}},
                  {"key": "mitigation_applied", "value": {"boolValue": true}}
                ]
              }
            ]
          }
        ]
      }
    ]
  }'

echo -e "\n\nSecurity test logs sent successfully!"
echo "Check Quickwit at http://quickwit.k3s.local for these logs"
echo "Or query via API: curl ${QUICKWIT_ENDPOINT}/api/v1/otel-logs-v0_7/search?query=log_type:security"
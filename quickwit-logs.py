#!/usr/bin/env python3
"""
Quickwit Data Loader for Observable Framework
Fetches security logs from Quickwit API and outputs JSON for dashboards
"""

import json
import urllib.request
from datetime import datetime, timedelta
import sys

def fetch_quickwit_logs():
    """Fetch security logs from Quickwit API"""
    quickwit_endpoint = "http://192.168.122.27:7280"
    
    # Search for all logs, focusing on security events
    search_url = f"{quickwit_endpoint}/api/v1/otel-logs-v0_7/search"
    
    # Query for all logs in the last 2 hours
    end_time = int(datetime.now().timestamp())
    start_time = int((datetime.now() - timedelta(hours=2)).timestamp())
    
    query_payload = {
        "query": "*",
        "max_hits": 100,
        "start_timestamp": start_time,
        "end_timestamp": end_time
    }
    
    try:
        req = urllib.request.Request(
            search_url,
            data=json.dumps(query_payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching from Quickwit: {e}", file=sys.stderr)
        return []
    
    # Process logs for Observable Framework
    logs = []
    if 'hits' in data:
        for hit in data['hits']:
            timestamp = datetime.fromtimestamp(hit['timestamp_nanos'] / 1e9)
            
            # Extract attributes safely
            attributes = hit.get('attributes', {})
            body = hit.get('body', {})
            message = body.get('message', '') if isinstance(body, dict) else str(body)
            
            log_entry = {
                'timestamp': timestamp.isoformat(),
                'time': timestamp.isoformat(),
                'message': message,
                'severity': hit.get('severity_text', 'INFO'),
                'service_name': hit.get('service_name', 'unknown'),
                'category': attributes.get('category', 'general'),
                'log_type': attributes.get('log_type', 'security'),
                'source_ip': attributes.get('source_ip', ''),
                'event_type': attributes.get('event_type', ''),
                'attack_type': attributes.get('attack_type', ''),
                'threat_level': attributes.get('threat_level', ''),
                'username': attributes.get('username', ''),
                'action': attributes.get('action', ''),
                'hour': timestamp.strftime('%H:00'),
                'date': timestamp.strftime('%Y-%m-%d'),
                'is_demo': '[DEMO]' in message or attributes.get('demo_data') == 'true'
            }
            
            # Security-specific categorization
            if 'auth' in log_entry['category'] or 'login' in message.lower() or 'ssh' in message.lower():
                log_entry['event_category'] = 'authentication'
            elif 'attack' in log_entry['category'] or 'injection' in message.lower() or 'scan' in message.lower():
                log_entry['event_category'] = 'attack'
            elif 'network' in log_entry['category'] or 'firewall' in message.lower():
                log_entry['event_category'] = 'network'
            else:
                log_entry['event_category'] = 'other'
            
            # Severity classification
            severity_map = {'CRITICAL': 4, 'ERROR': 3, 'WARN': 2, 'INFO': 1}
            log_entry['severity_level'] = severity_map.get(log_entry['severity'], 1)
            
            logs.append(log_entry)
    
    # Sort by timestamp (newest first)
    logs.sort(key=lambda x: x['timestamp'], reverse=True)
    
    # Create security analytics summary
    summary = {
        'total_events': len(logs),
        'demo_events': sum(1 for log in logs if log['is_demo']),
        'live_events': sum(1 for log in logs if not log['is_demo']),
        'by_severity': {},
        'by_category': {},
        'by_event_type': {},
        'by_hour': {},
        'threat_sources': {},
        'attack_types': {}
    }
    
    for log in logs:
        severity = log['severity']
        category = log['event_category']
        event_type = log['event_type']
        hour = log['hour']
        source_ip = log['source_ip']
        attack_type = log['attack_type']
        
        summary['by_severity'][severity] = summary['by_severity'].get(severity, 0) + 1
        summary['by_category'][category] = summary['by_category'].get(category, 0) + 1
        summary['by_hour'][hour] = summary['by_hour'].get(hour, 0) + 1
        
        if event_type:
            summary['by_event_type'][event_type] = summary['by_event_type'].get(event_type, 0) + 1
        
        if source_ip:
            summary['threat_sources'][source_ip] = summary['threat_sources'].get(source_ip, 0) + 1
        
        if attack_type:
            summary['attack_types'][attack_type] = summary['attack_types'].get(attack_type, 0) + 1
    
    # Security metrics
    critical_events = [log for log in logs if log['severity'] == 'CRITICAL']
    failed_logins = [log for log in logs if 'failed' in log['message'].lower() and 'login' in log['message'].lower()]
    attacks = [log for log in logs if log['event_category'] == 'attack']
    
    return {
        'logs': logs[:50],  # Limit to 50 most recent for display
        'summary': summary,
        'critical_events': critical_events[:10],
        'failed_logins': failed_logins[:10],
        'recent_attacks': attacks[:10],
        'last_updated': datetime.now().isoformat()
    }

if __name__ == "__main__":
    result = fetch_quickwit_logs()
    print(json.dumps(result, indent=2))
#!/usr/bin/env python3
"""
Loki Data Loader for Observable Framework
Fetches operational logs from Loki API and outputs JSON for dashboards
"""

import json
import urllib.request
import urllib.parse
from datetime import datetime, timedelta
import sys

def fetch_loki_logs():
    """Fetch operational logs from Loki API"""
    loki_endpoint = "http://192.168.122.27:3100"
    
    # Query last 2 hours of logs for better demo data
    end_time = datetime.now()
    start_time = end_time - timedelta(hours=2)
    
    params = {
        'query': '{job=~".+"}',
        'start': str(int(start_time.timestamp() * 1e9)),
        'end': str(int(end_time.timestamp() * 1e9)),
        'limit': '100'
    }
    
    url = f"{loki_endpoint}/loki/api/v1/query_range?{urllib.parse.urlencode(params)}"
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching from Loki: {e}", file=sys.stderr)
        return []
    
    # Process logs for Observable Framework
    logs = []
    if 'data' in data and 'result' in data['data']:
        for stream in data['data']['result']:
            stream_labels = stream.get('stream', {})
            service_name = stream_labels.get('service_name', 'unknown')
            
            for entry in stream.get('values', []):
                timestamp_ns, log_line = entry
                timestamp = datetime.fromtimestamp(int(timestamp_ns) / 1e9)
                
                # Parse JSON log if possible
                try:
                    log_data = json.loads(log_line)
                    if isinstance(log_data, dict):
                        log_entry = log_data.copy()
                    else:
                        log_entry = {'message': str(log_data)}
                except:
                    log_entry = {'message': log_line}
                
                # Add metadata
                log_entry.update({
                    'timestamp': timestamp.isoformat(),
                    'time': timestamp.isoformat(),
                    'service_name': service_name,
                    'hour': timestamp.strftime('%H:00'),
                    'date': timestamp.strftime('%Y-%m-%d'),
                    'level': log_entry.get('severity', 'INFO').upper(),
                    'category': log_entry.get('attributes', {}).get('category', 'general'),
                    'log_type': log_entry.get('attributes', {}).get('log_type', 'operational'),
                    'is_demo': '[DEMO]' in log_entry.get('message', '') or log_entry.get('attributes', {}).get('demo_data') == 'true'
                })
                
                logs.append(log_entry)
    
    # Sort by timestamp (newest first)
    logs.sort(key=lambda x: x['timestamp'], reverse=True)
    
    # Create summary metrics
    summary = {
        'total_logs': len(logs),
        'demo_logs': sum(1 for log in logs if log['is_demo']),
        'live_logs': sum(1 for log in logs if not log['is_demo']),
        'by_level': {},
        'by_service': {},
        'by_hour': {},
        'by_category': {}
    }
    
    for log in logs:
        level = log['level']
        service = log['service_name']
        hour = log['hour']
        category = log['category']
        
        summary['by_level'][level] = summary['by_level'].get(level, 0) + 1
        summary['by_service'][service] = summary['by_service'].get(service, 0) + 1
        summary['by_hour'][hour] = summary['by_hour'].get(hour, 0) + 1
        summary['by_category'][category] = summary['by_category'].get(category, 0) + 1
    
    return {
        'logs': logs[:50],  # Limit to 50 most recent for display
        'summary': summary,
        'last_updated': datetime.now().isoformat()
    }

if __name__ == "__main__":
    result = fetch_loki_logs()
    print(json.dumps(result, indent=2))
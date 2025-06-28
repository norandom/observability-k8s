#!/usr/bin/env python3
import os
import requests
import json
import sys
from datetime import datetime, timedelta

# Get cluster endpoints from environment
QUICKWIT_ENDPOINT = os.getenv('QUICKWIT_ENDPOINT', 'http://192.168.122.27:7280')

def fetch_quickwit_logs():
    """Fetch recent logs from Quickwit for Observable Framework"""
    try:
        url = f"{QUICKWIT_ENDPOINT}/api/v1/otel-logs-v0_7/search"
        
        # Query last hour of logs
        end_time = int(datetime.now().timestamp())
        start_time = int((datetime.now() - timedelta(hours=1)).timestamp())
        
        payload = {
            "query": "*",
            "max_hits": 100,
            "start_timestamp": start_time,
            "end_timestamp": end_time
        }
        
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            data = response.json()
            
            # Transform for Observable Framework
            logs = []
            if 'hits' in data:
                for hit in data['hits']:
                    doc = hit.get('document', {})
                    logs.append({
                        'timestamp': doc.get('timestamp_nanos', 0) // 1000000,  # Convert to milliseconds
                        'message': doc.get('body', ''),
                        'severity': doc.get('severity_text', ''),
                        'service': doc.get('service_name', ''),
                        'source': 'quickwit',
                        'attributes': doc.get('attributes', {})
                    })
            
            # Output as JSON for Observable
            print(json.dumps(logs, indent=2))
            
        else:
            print(json.dumps([]))
            
    except Exception as e:
        print(f"Error fetching Quickwit logs: {e}", file=sys.stderr)
        print(json.dumps([]))

if __name__ == "__main__":
    fetch_quickwit_logs()
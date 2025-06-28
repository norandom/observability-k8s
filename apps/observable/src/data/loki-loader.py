#!/usr/bin/env python3
import os
import requests
import json
import sys
from datetime import datetime, timedelta

# Get cluster endpoints from environment
LOKI_ENDPOINT = os.getenv('LOKI_ENDPOINT', 'http://192.168.122.27:3100')

def fetch_loki_logs():
    """Fetch recent logs from Loki for Observable Framework"""
    try:
        # Query last hour of logs
        end_time = datetime.now()
        start_time = end_time - timedelta(hours=1)
        
        url = f"{LOKI_ENDPOINT}/loki/api/v1/query_range"
        params = {
            'query': '{job=~".+"}',
            'start': int(start_time.timestamp() * 1000000000),
            'end': int(end_time.timestamp() * 1000000000),
            'limit': 100
        }
        
        response = requests.get(url, params=params, timeout=10)
        if response.status_code == 200:
            data = response.json()
            
            # Transform for Observable Framework
            logs = []
            if 'data' in data and 'result' in data['data']:
                for stream in data['data']['result']:
                    labels = stream.get('stream', {})
                    for value in stream.get('values', []):
                        timestamp = int(value[0]) // 1000000  # Convert to milliseconds
                        message = value[1]
                        logs.append({
                            'timestamp': timestamp,
                            'message': message,
                            'labels': labels,
                            'source': 'loki'
                        })
            
            # Output as JSON for Observable
            print(json.dumps(logs, indent=2))
            
        else:
            print(json.dumps([]))
            
    except Exception as e:
        print(f"Error fetching Loki logs: {e}", file=sys.stderr)
        print(json.dumps([]))

if __name__ == "__main__":
    fetch_loki_logs()
#!/usr/bin/env python3
"""
Observable Framework data loader for Loki logs
Fetches operational logs from Loki API and processes them with Polars for enhanced performance
"""

import os
import sys
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any
import requests
import polars as pl
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


class LokiDataLoader:
    def __init__(self):
        self.loki_endpoint = os.getenv('LOKI_ENDPOINT', 'http://192.168.122.27:3100')
        self.session = self._create_session()
    
    def _create_session(self) -> requests.Session:
        """Create a requests session with retry strategy"""
        session = requests.Session()
        retry_strategy = Retry(
            total=3,
            status_forcelist=[429, 500, 502, 503, 504],
            method_whitelist=["HEAD", "GET", "OPTIONS"]
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session
    
    def fetch_logs(self, hours_back: int = 1, limit: int = 500) -> List[Dict[str, Any]]:
        """Fetch logs from Loki API"""
        try:
            end_time = datetime.now()
            start_time = end_time - timedelta(hours=hours_back)
            
            url = f"{self.loki_endpoint}/loki/api/v1/query_range"
            params = {
                'query': '{job=~".+"}',
                'start': int(start_time.timestamp() * 1000000000),
                'end': int(end_time.timestamp() * 1000000000),
                'limit': limit,
                'direction': 'backward'
            }
            
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            return self._process_loki_response(response.json())
            
        except requests.exceptions.RequestException as e:
            print(f"Error fetching Loki logs: {e}", file=sys.stderr)
            return []
        except Exception as e:
            print(f"Unexpected error: {e}", file=sys.stderr)
            return []
    
    def _process_loki_response(self, data: Dict) -> List[Dict[str, Any]]:
        """Process Loki API response using Polars for efficient data manipulation"""
        logs = []
        
        if 'data' not in data or 'result' not in data['data']:
            return logs
        
        # Extract raw log entries
        raw_entries = []
        for stream in data['data']['result']:
            labels = stream.get('stream', {})
            for value in stream.get('values', []):
                timestamp_ns = int(value[0])
                message = value[1]
                
                raw_entries.append({
                    'timestamp_ns': timestamp_ns,
                    'timestamp': timestamp_ns // 1000000,  # Convert to milliseconds
                    'message': message,
                    'source': 'loki',
                    'job': labels.get('job', 'unknown'),
                    'instance': labels.get('instance', 'unknown'),
                    'level': self._extract_log_level(message),
                    'service_name': labels.get('service_name', labels.get('container', 'unknown')),
                    'labels': labels
                })
        
        if not raw_entries:
            return logs
        
        # Use Polars for efficient data processing
        df = pl.DataFrame(raw_entries)
        
        # Add derived columns
        df = df.with_columns([
            # Extract timestamp as datetime
            pl.from_epoch(pl.col('timestamp'), time_unit='ms').alias('datetime'),
            # Categorize log levels
            pl.col('level').map_elements(self._normalize_log_level, return_dtype=pl.String).alias('severity'),
            # Extract keywords from message
            pl.col('message').map_elements(self._extract_keywords, return_dtype=pl.List(pl.String)).alias('keywords'),
            # Message length for analysis
            pl.col('message').str.len_chars().alias('message_length')
        ])
        
        # Sort by timestamp (most recent first)
        df = df.sort('timestamp', descending=True)
        
        # Convert back to list of dictionaries for Observable Framework
        return df.to_dicts()
    
    def _extract_log_level(self, message: str) -> str:
        """Extract log level from message"""
        message_upper = message.upper()
        
        if any(level in message_upper for level in ['ERROR', 'ERR', 'FATAL']):
            return 'ERROR'
        elif any(level in message_upper for level in ['WARN', 'WARNING']):
            return 'WARNING'
        elif any(level in message_upper for level in ['INFO', 'INFORMATION']):
            return 'INFO'
        elif any(level in message_upper for level in ['DEBUG', 'DBG']):
            return 'DEBUG'
        else:
            return 'UNKNOWN'
    
    def _normalize_log_level(self, level: str) -> str:
        """Normalize log level for consistent display"""
        level_map = {
            'ERROR': 'error',
            'WARNING': 'warning',
            'INFO': 'info',
            'DEBUG': 'debug',
            'UNKNOWN': 'unknown'
        }
        return level_map.get(level, 'unknown')
    
    def _extract_keywords(self, message: str) -> List[str]:
        """Extract relevant keywords from log message"""
        keywords = []
        message_lower = message.lower()
        
        # Common patterns to extract
        patterns = [
            'http', 'https', 'api', 'error', 'warning', 'failed', 'success',
            'database', 'db', 'sql', 'query', 'connection', 'timeout',
            'auth', 'login', 'logout', 'user', 'permission', 'security',
            'kubernetes', 'k8s', 'pod', 'service', 'deployment',
            'nginx', 'apache', 'tcp', 'udp', 'port', 'network'
        ]
        
        for pattern in patterns:
            if pattern in message_lower:
                keywords.append(pattern)
        
        return keywords[:5]  # Limit to top 5 keywords


def main():
    """Main function to run the data loader"""
    loader = LokiDataLoader()
    
    # Fetch logs from last 2 hours with higher limit for better analysis
    logs = loader.fetch_logs(hours_back=2, limit=1000)
    
    # Output as JSON for Observable Framework
    print(json.dumps(logs, indent=2, default=str))


if __name__ == "__main__":
    main()
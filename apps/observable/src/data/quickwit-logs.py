#!/usr/bin/env python3
"""
Observable Framework data loader for Quickwit security logs
Fetches security logs from Quickwit API and processes them with Pandas for analysis
"""

import os
import sys
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import requests
import pandas as pd
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


class QuickwitDataLoader:
    def __init__(self):
        self.quickwit_endpoint = os.getenv('QUICKWIT_ENDPOINT', 'http://192.168.122.27:7280')
        self.session = self._create_session()
        
    def _create_session(self) -> requests.Session:
        """Create a requests session with retry strategy"""
        session = requests.Session()
        retry_strategy = Retry(
            total=3,
            status_forcelist=[429, 500, 502, 503, 504],
            method_whitelist=["HEAD", "GET", "POST", "OPTIONS"]
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session
    
    def fetch_logs(self, hours_back: int = 1, max_hits: int = 500) -> List[Dict[str, Any]]:
        """Fetch security logs from Quickwit API"""
        try:
            url = f"{self.quickwit_endpoint}/api/v1/otel-logs-v0_7/search"
            
            end_time = int(datetime.now().timestamp())
            start_time = int((datetime.now() - timedelta(hours=hours_back)).timestamp())
            
            # Build comprehensive query for security-relevant logs
            queries = [
                "*",  # All logs
                "log_type:security",  # Security-specific logs
                "severity_text:ERROR OR severity_text:WARNING",  # Error and warning logs
                "body:(auth OR login OR failed OR unauthorized OR denied OR firewall)"  # Security keywords
            ]
            
            all_logs = []
            for query in queries:
                payload = {
                    "query": query,
                    "max_hits": max_hits // len(queries),
                    "start_timestamp": start_time,
                    "end_timestamp": end_time,
                    "sort": [{"timestamp_nanos": {"order": "desc"}}]
                }
                
                try:
                    response = self.session.post(url, json=payload, timeout=30)
                    response.raise_for_status()
                    
                    query_logs = self._process_quickwit_response(response.json())
                    all_logs.extend(query_logs)
                    
                except requests.exceptions.RequestException as e:
                    print(f"Error with query '{query}': {e}", file=sys.stderr)
                    continue
            
            # Remove duplicates and process with pandas
            return self._deduplicate_and_enhance(all_logs)
            
        except Exception as e:
            print(f"Unexpected error in fetch_logs: {e}", file=sys.stderr)
            return []
    
    def _process_quickwit_response(self, data: Dict) -> List[Dict[str, Any]]:
        """Process Quickwit API response"""
        logs = []
        
        if 'hits' not in data:
            return logs
        
        for hit in data['hits']:
            doc = hit.get('document', {})
            
            # Extract timestamp
            timestamp_nanos = doc.get('timestamp_nanos', 0)
            timestamp_ms = timestamp_nanos // 1000000 if timestamp_nanos else 0
            
            # Build structured log entry
            log_entry = {
                'timestamp': timestamp_ms,
                'timestamp_nanos': timestamp_nanos,
                'message': doc.get('body', ''),
                'severity': doc.get('severity_text', 'unknown'),
                'service': doc.get('service_name', 'unknown'),
                'source': 'quickwit',
                'log_type': doc.get('attributes', {}).get('log_type', 'unknown'),
                'resource_attributes': doc.get('resource_attributes', {}),
                'attributes': doc.get('attributes', {}),
                'trace_id': doc.get('trace_id', ''),
                'span_id': doc.get('span_id', ''),
                'scope_name': doc.get('scope_name', ''),
                'raw_document': doc
            }
            
            # Extract additional security-relevant fields
            log_entry.update(self._extract_security_fields(doc))
            
            logs.append(log_entry)
        
        return logs
    
    def _extract_security_fields(self, doc: Dict) -> Dict[str, Any]:
        """Extract security-relevant fields from log document"""
        security_fields = {}
        
        # Extract from attributes
        attrs = doc.get('attributes', {})
        
        # Common security fields
        security_fields.update({
            'user_id': attrs.get('user_id', attrs.get('user', '')),
            'source_ip': attrs.get('source_ip', attrs.get('client_ip', attrs.get('remote_addr', ''))),
            'user_agent': attrs.get('user_agent', attrs.get('http_user_agent', '')),
            'http_method': attrs.get('http_method', attrs.get('method', '')),
            'http_status': attrs.get('http_status', attrs.get('status_code', '')),
            'url': attrs.get('url', attrs.get('request_uri', '')),
            'session_id': attrs.get('session_id', ''),
            'category': self._categorize_log(doc.get('body', '')),
            'risk_score': self._calculate_risk_score(doc)
        })
        
        return security_fields
    
    def _categorize_log(self, message: str) -> str:
        """Categorize log entry based on content"""
        message_lower = message.lower()
        
        categories = {
            'auth': ['login', 'logout', 'authentication', 'authorize', 'auth', 'signin', 'signout'],
            'access': ['denied', 'forbidden', 'unauthorized', 'permission', 'access'],
            'security': ['firewall', 'intrusion', 'malware', 'virus', 'attack', 'exploit'],
            'network': ['connection', 'tcp', 'udp', 'port', 'network', 'socket'],
            'system': ['system', 'kernel', 'process', 'service', 'daemon'],
            'application': ['application', 'app', 'web', 'api', 'endpoint']
        }
        
        for category, keywords in categories.items():
            if any(keyword in message_lower for keyword in keywords):
                return category
        
        return 'general'
    
    def _calculate_risk_score(self, doc: Dict) -> int:
        """Calculate a simple risk score for the log entry"""
        score = 0
        message = doc.get('body', '').lower()
        severity = doc.get('severity_text', '').lower()
        
        # Severity-based scoring
        severity_scores = {
            'error': 3,
            'warning': 2,
            'info': 1,
            'debug': 0
        }
        score += severity_scores.get(severity, 0)
        
        # Content-based scoring
        high_risk_keywords = ['failed', 'denied', 'unauthorized', 'error', 'attack', 'intrusion']
        medium_risk_keywords = ['warning', 'timeout', 'retry', 'slow']
        
        for keyword in high_risk_keywords:
            if keyword in message:
                score += 2
        
        for keyword in medium_risk_keywords:
            if keyword in message:
                score += 1
        
        return min(score, 10)  # Cap at 10
    
    def _deduplicate_and_enhance(self, logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Remove duplicates and enhance data using pandas"""
        if not logs:
            return []
        
        # Convert to DataFrame for advanced processing
        df = pd.DataFrame(logs)
        
        # Remove duplicates based on timestamp and message
        df = df.drop_duplicates(subset=['timestamp_nanos', 'message'], keep='first')
        
        # Sort by timestamp (most recent first)
        df = df.sort_values('timestamp', ascending=False)
        
        # Add time-based analysis
        df['datetime'] = pd.to_datetime(df['timestamp'], unit='ms')
        df['hour'] = df['datetime'].dt.hour
        df['day_of_week'] = df['datetime'].dt.dayofweek
        
        # Enhance with statistical analysis
        df['message_length'] = df['message'].str.len()
        df['word_count'] = df['message'].str.split().str.len()
        
        # Security analysis
        df['is_security_relevant'] = df.apply(self._is_security_relevant, axis=1)
        df['anomaly_score'] = df.apply(self._calculate_anomaly_score, axis=1)
        
        # Convert back to list of dictionaries
        return df.to_dict('records')
    
    def _is_security_relevant(self, row: pd.Series) -> bool:
        """Determine if log entry is security-relevant"""
        security_indicators = [
            row['category'] in ['auth', 'access', 'security'],
            row['risk_score'] >= 3,
            row['severity'].lower() in ['error', 'warning'],
            any(keyword in row['message'].lower() for keyword in 
                ['failed', 'denied', 'unauthorized', 'attack', 'intrusion', 'malware'])
        ]
        
        return any(security_indicators)
    
    def _calculate_anomaly_score(self, row: pd.Series) -> float:
        """Calculate anomaly score based on various factors"""
        score = 0.0
        
        # Time-based anomalies (unusual hours)
        if row['hour'] < 6 or row['hour'] > 22:
            score += 0.2
        
        # Message length anomalies
        if row['message_length'] > 500 or row['message_length'] < 10:
            score += 0.1
        
        # High risk score
        if row['risk_score'] >= 5:
            score += 0.3
        
        # Security relevance
        if row['is_security_relevant']:
            score += 0.2
        
        return min(score, 1.0)  # Cap at 1.0


def main():
    """Main function to run the data loader"""
    loader = QuickwitDataLoader()
    
    # Fetch logs from last 2 hours with higher limit for security analysis
    logs = loader.fetch_logs(hours_back=2, max_hits=1000)
    
    # Output as JSON for Observable Framework
    print(json.dumps(logs, indent=2, default=str))


if __name__ == "__main__":
    main()
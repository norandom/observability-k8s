#!/usr/bin/env python3
"""
Observable Framework data loader for Prometheus metrics
Fetches system metrics from Prometheus API and processes them for dashboard display
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


class PrometheusDataLoader:
    def __init__(self):
        self.prometheus_endpoint = os.getenv('PROMETHEUS_ENDPOINT', 'http://192.168.122.27:9090')
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
    
    def fetch_metrics(self, hours_back: int = 1) -> Dict[str, Any]:
        """Fetch various metrics from Prometheus"""
        try:
            metrics_data = {
                'timestamp': int(datetime.now().timestamp() * 1000),
                'system_metrics': self._fetch_system_metrics(),
                'application_metrics': self._fetch_application_metrics(),
                'observability_stack_metrics': self._fetch_observability_metrics(),
                'summary': {}
            }
            
            # Generate summary statistics
            metrics_data['summary'] = self._generate_summary(metrics_data)
            
            return metrics_data
            
        except Exception as e:
            print(f"Error fetching metrics: {e}", file=sys.stderr)
            return {'timestamp': int(datetime.now().timestamp() * 1000), 'error': str(e)}
    
    def _fetch_system_metrics(self) -> Dict[str, Any]:
        """Fetch system-level metrics"""
        metrics = {}
        
        # Define queries for system metrics
        queries = {
            'cpu_usage': 'avg(1 - rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100',
            'memory_usage': 'avg((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100)',
            'disk_usage': 'avg((1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100)',
            'network_in': 'avg(rate(node_network_receive_bytes_total[5m])) * 8',
            'network_out': 'avg(rate(node_network_transmit_bytes_total[5m])) * 8',
            'load_average': 'avg(node_load1)',
            'uptime': 'avg(node_time_seconds - node_boot_time_seconds)'
        }
        
        for metric_name, query in queries.items():
            try:
                result = self._execute_query(query)
                metrics[metric_name] = self._extract_metric_value(result)
            except Exception as e:
                print(f"Error fetching {metric_name}: {e}", file=sys.stderr)
                metrics[metric_name] = None
        
        return metrics
    
    def _fetch_application_metrics(self) -> Dict[str, Any]:
        """Fetch application-specific metrics"""
        metrics = {}
        
        queries = {
            'http_requests_total': 'sum(rate(http_requests_total[5m]))',
            'http_request_duration': 'avg(http_request_duration_seconds)',
            'active_connections': 'sum(nginx_connections_active)',
            'error_rate': 'sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100',
            'response_time_p95': 'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))',
            'database_connections': 'sum(mysql_global_status_threads_connected)',
            'cache_hit_rate': 'rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m])) * 100'
        }
        
        for metric_name, query in queries.items():
            try:
                result = self._execute_query(query)
                metrics[metric_name] = self._extract_metric_value(result)
            except Exception as e:
                # Many of these metrics may not exist in all environments
                metrics[metric_name] = None
        
        return metrics
    
    def _fetch_observability_metrics(self) -> Dict[str, Any]:
        """Fetch metrics specific to our observability stack"""
        metrics = {}
        
        queries = {
            # Kubernetes metrics
            'pod_count': 'count(kube_pod_info)',
            'namespace_count': 'count(count by (namespace)(kube_pod_info))',
            'service_count': 'count(kube_service_info)',
            'deployment_count': 'count(kube_deployment_labels)',
            
            # Container metrics
            'container_cpu_usage': 'avg(rate(container_cpu_usage_seconds_total[5m])) * 100',
            'container_memory_usage': 'avg(container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100',
            'container_restart_count': 'sum(increase(kube_pod_container_status_restarts_total[1h]))',
            
            # Observability stack specific
            'grafana_active_users': 'grafana_stat_active_users',
            'loki_ingester_chunks': 'sum(loki_ingester_chunks_stored_total)',
            'prometheus_targets': 'prometheus_config_last_reload_success_timestamp_seconds',
            'alertmanager_alerts': 'sum(alertmanager_alerts)'
        }
        
        for metric_name, query in queries.items():
            try:
                result = self._execute_query(query)
                metrics[metric_name] = self._extract_metric_value(result)
            except Exception as e:
                metrics[metric_name] = None
        
        return metrics
    
    def _execute_query(self, query: str) -> Dict:
        """Execute a Prometheus query"""
        url = f"{self.prometheus_endpoint}/api/v1/query"
        params = {
            'query': query,
            'time': datetime.now().isoformat()
        }
        
        response = self.session.get(url, params=params, timeout=10)
        response.raise_for_status()
        
        return response.json()
    
    def _extract_metric_value(self, result: Dict) -> Optional[float]:
        """Extract numeric value from Prometheus query result"""
        try:
            if result.get('status') != 'success':
                return None
            
            data = result.get('data', {})
            result_type = data.get('resultType')
            result_data = data.get('result', [])
            
            if not result_data:
                return None
            
            if result_type == 'vector':
                # Single value
                value = result_data[0].get('value', [None, None])[1]
                return float(value) if value is not None else None
            elif result_type == 'matrix':
                # Time series - get the latest value
                if result_data[0].get('values'):
                    value = result_data[0]['values'][-1][1]
                    return float(value) if value is not None else None
            
            return None
            
        except (KeyError, IndexError, ValueError, TypeError):
            return None
    
    def _generate_summary(self, metrics_data: Dict) -> Dict[str, Any]:
        """Generate summary statistics and health indicators"""
        summary = {
            'overall_health': 'unknown',
            'critical_alerts': 0,
            'performance_score': 0,
            'availability_score': 0,
            'recommendations': []
        }
        
        try:
            system_metrics = metrics_data.get('system_metrics', {})
            app_metrics = metrics_data.get('application_metrics', {})
            obs_metrics = metrics_data.get('observability_stack_metrics', {})
            
            # Calculate performance score
            performance_factors = []
            
            cpu_usage = system_metrics.get('cpu_usage')
            if cpu_usage is not None:
                performance_factors.append(max(0, 100 - cpu_usage))
                if cpu_usage > 80:
                    summary['recommendations'].append("High CPU usage detected")
            
            memory_usage = system_metrics.get('memory_usage')
            if memory_usage is not None:
                performance_factors.append(max(0, 100 - memory_usage))
                if memory_usage > 85:
                    summary['recommendations'].append("High memory usage detected")
            
            disk_usage = system_metrics.get('disk_usage')
            if disk_usage is not None:
                performance_factors.append(max(0, 100 - disk_usage))
                if disk_usage > 90:
                    summary['recommendations'].append("Disk space running low")
            
            if performance_factors:
                summary['performance_score'] = sum(performance_factors) / len(performance_factors)
            
            # Calculate availability score based on error rates and restarts
            availability_factors = [100]  # Start with perfect score
            
            error_rate = app_metrics.get('error_rate')
            if error_rate is not None and error_rate > 5:
                availability_factors.append(max(0, 100 - error_rate * 10))
                summary['recommendations'].append(f"High error rate: {error_rate:.2f}%")
            
            restart_count = obs_metrics.get('container_restart_count')
            if restart_count is not None and restart_count > 5:
                availability_factors.append(max(0, 100 - restart_count * 2))
                summary['recommendations'].append("Multiple container restarts detected")
            
            summary['availability_score'] = sum(availability_factors) / len(availability_factors)
            
            # Determine overall health
            overall_score = (summary['performance_score'] + summary['availability_score']) / 2
            
            if overall_score >= 80:
                summary['overall_health'] = 'good'
            elif overall_score >= 60:
                summary['overall_health'] = 'warning'
            else:
                summary['overall_health'] = 'critical'
                summary['critical_alerts'] = len([r for r in summary['recommendations'] if any(word in r.lower() for word in ['high', 'low', 'critical'])])
            
        except Exception as e:
            print(f"Error generating summary: {e}", file=sys.stderr)
            summary['error'] = str(e)
        
        return summary


def main():
    """Main function to run the data loader"""
    loader = PrometheusDataLoader()
    
    # Fetch current metrics
    metrics = loader.fetch_metrics()
    
    # Output as JSON for Observable Framework
    print(json.dumps(metrics, indent=2, default=str))


if __name__ == "__main__":
    main()
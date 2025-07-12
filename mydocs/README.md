# Telepresence and Zscaler Zero Trust Network Architecture

This document explains how Telepresence works alongside Zscaler's Zero Trust Network Access (ZTNA) solution.

## Diagram

To render the network diagram:

```bash
# Install D2 if you haven't already
# macOS: brew install d2
# Linux: curl -fsSL https://d2lang.com/install.sh | sh -s --

# Generate the diagram
d2 telepresence-zscaler-network.d2 telepresence-zscaler-network.png

# Or generate as SVG
d2 telepresence-zscaler-network.d2 telepresence-zscaler-network.svg
```

## Overview

The diagram illustrates the interaction between:

1. **Telepresence** - Kubernetes development tool
2. **Zscaler ZPA** - Zero Trust Private Access
3. **Zscaler ZIA** - Zero Trust Internet Access
4. **Corporate DNS and Network Policies**

## Key Concepts

### DNS Resolution Split

**Telepresence DNS (127.0.0.1:53)**
- Handles: `*.cluster.local`, `*.svc`, Kubernetes service names
- Bypasses Zscaler for internal cluster resolution
- Runs locally on developer workstation

**Zscaler ZIA DNS**
- Handles: `*.com`, `*.io`, `*.net`, `*.org`, etc.
- Applies corporate DNS policies and filtering
- Routes through Zscaler cloud

### Network Segregation

**Direct Access (Bypass Zscaler)**
- Kubernetes API Server: `192.168.122.27:6443`
- Service Network: `10.43.0.0/16`
- Pod Network: `10.42.0.0/24`

**Zero Trust Protected**
- All internet traffic
- Public cloud services
- External APIs

### Developer Access Control

**Entra ID Integration**
- Developer groups defined in Azure Entra ID
- Policies pushed to Zscaler ZPA
- Conditional access based on:
  - User identity
  - Device compliance
  - Location/network

### Traffic Flow

1. **kubectl commands** → Direct to API server (never proxied)
2. **Cluster services** → Through Telepresence (bypasses Zscaler)
3. **Internet traffic** → Through Zscaler ZIA (filtered/monitored)
4. **Corporate apps** → Through Zscaler ZPA (Zero Trust)

## Configuration Requirements

### For IT Administrators

```yaml
# Zscaler Bypass Configuration
DNS_Bypass:
  - 127.0.0.1:53  # Telepresence local DNS

Network_Bypass:
  - 10.43.0.0/16  # Kubernetes services
  - 10.42.0.0/24  # Kubernetes pods
  - <API_SERVER_IP>/32  # Direct kubectl access

Excluded_Domains:
  # These go through Zscaler
  - "*.com"
  - "*.io"
  - "*.net"
  - "*.org"
```

### For Developers

```bash
# Environment setup
export TELEPRESENCE_USE_DEPLOYMENT=1

# Connect to cluster (after Zscaler bypass is configured)
telepresence connect

# Verify DNS resolution
nslookup observable.observable.svc.cluster.local 127.0.0.1
```

## Security Benefits

1. **Zero Trust for Internet** - All external traffic goes through Zscaler
2. **Direct Development Access** - No proxy overhead for cluster resources
3. **Identity-Based Access** - Entra ID controls who gets developer permissions
4. **Audit Trail** - Zscaler logs all internet access, Kubernetes audit logs for cluster access

## Troubleshooting

### DNS Issues
```bash
# Check Telepresence DNS
dig @127.0.0.1 service-name.namespace.svc.cluster.local

# Check Zscaler DNS
nslookup google.com
```

### Connection Issues
```bash
# Verify bypasses are working
curl -v https://<API_SERVER_IP>:6443

# Check Telepresence status
telepresence status
```

## Best Practices

1. **Least Privilege** - Only add required subnets to bypass list
2. **Time-Based Access** - Use Entra ID conditional access for time windows
3. **Device Compliance** - Require compliant devices for developer access
4. **Regular Reviews** - Audit bypass rules quarterly
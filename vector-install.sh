#!/bin/bash
# Vector installation script for client machines

set -e

echo "Installing Vector..."

# Create vector user
sudo useradd --system --shell /bin/false --home-dir /var/lib/vector --create-home vector

# Add vector user to required groups for log access
sudo usermod -a -G systemd-journal,docker vector

# Create directories
sudo mkdir -p /etc/vector /var/log/vector
sudo chown vector:vector /var/log/vector

# Download and install Vector (adjust version as needed)
VECTOR_VERSION="0.34.0"
curl -L "https://github.com/vectordotdev/vector/releases/download/v${VECTOR_VERSION}/vector-${VECTOR_VERSION}-x86_64-unknown-linux-musl.tar.gz" | sudo tar -xzC /usr/local/bin --strip-components=2 vector-x86_64-unknown-linux-musl/bin/vector

# Copy configuration
sudo cp vector-client-config.toml /etc/vector/vector.toml
sudo chown vector:vector /etc/vector/vector.toml

# Install systemd service
sudo cp vector-systemd.service /etc/systemd/system/vector.service

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable vector
sudo systemctl start vector

echo "Vector installation complete!"
echo "Check status with: sudo systemctl status vector"
echo "View logs with: sudo journalctl -u vector -f"
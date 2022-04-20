#!/bin/bash
NODE_EXPORTER_VERSION="1.3.0"

curl -LO https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

tar -xzvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cd node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64

sudo cp node_exporter /usr/local/bin
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service <<'!'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
!

# enable node_exporter in systemctl
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter


echo "Setup complete.
Add the following lines to /etc/prometheus/prometheus.yml:

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
"

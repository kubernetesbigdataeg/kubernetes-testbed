#!/bin/bash
PROMETHEUS_VERSION="2.31.1"
curl -LO https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xzvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64/

sudo useradd --no-create-home --shell /bin/false prometheus 
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo cp -r consoles /etc/prometheus
sudo cp -r console_libraries /etc/prometheus
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

sudo tee /etc/systemd/system/prometheus.service <<'!'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
!

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

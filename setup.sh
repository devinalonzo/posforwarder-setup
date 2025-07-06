#!/bin/bash
set -e

echo "🔧 Installing dependencies..."
apt update
apt install -y dnsmasq hostapd python3-flask wireless-tools tailscale

echo "📁 Creating folders..."
mkdir -p /opt/posforwarder/apconfig
mkdir -p /opt/posforwarder/wifi-joiner
mkdir -p /opt/posforwarder/posportal

echo "📄 Copying files..."
cp apconfig/dnsmasq.conf /opt/posforwarder/apconfig/
cp apconfig/hostapd.conf /opt/posforwarder/apconfig/
cp wifi-joiner/joiner.py /opt/posforwarder/wifi-joiner/
cp posportal/posportal.py /opt/posforwarder/posportal/
cp wifimanager.service /etc/systemd/system/
cp posportal.service /etc/systemd/system/

echo "⚙️ Enabling systemd services..."
systemctl enable wifimanager.service
systemctl enable posportal.service

echo "✅ Setup complete. Rebooting..."
reboot

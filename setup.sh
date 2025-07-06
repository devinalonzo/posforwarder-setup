#!/bin/bash

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y \
    dnsmasq \
    hostapd \
    python3-flask \
    git \
    iptables-persistent \
    net-tools \
    network-manager \
    wget \
    curl \
    unzip \
    gpg

echo "📦 Adding Tailscale APT repo..."
curl -fsSL https://pkgs.tailscale.com/stable/raspbian/bookworm.gpg \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null

curl -fsSL https://pkgs.tailscale.com/stable/raspbian/bookworm.list \
  | sed 's/^deb /deb [signed-by=\/usr\/share\/keyrings\/tailscale-archive-keyring.gpg] /' \
  | sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null

sudo apt update

echo "🔐 Installing Tailscale..."
if ! sudo apt install -y tailscale; then
  echo "❌ Tailscale install failed. You can manually install it later with 'sudo apt install tailscale'"
fi

echo "🧩 Downloading VirtualHere..."
sudo wget -O /usr/local/bin/vhusbdarm https://www.virtualhere.com/sites/default/files/usbserver/vhusbdarm
sudo chmod +x /usr/local/bin/vhusbdarm

echo "📁 Creating Flask app directories..."
mkdir -p /home/devin/posforwarder/templates
mkdir -p /home/devin/posforwarder/static
sudo chown -R devin:devin /home/devin/posforwarder

echo "🛜 Setting up fallback AP..."

cat <<EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=POS_SETUP
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=connect123
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

sudo systemctl unmask hostapd
sudo systemctl enable hostapd

cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.5.10,192.168.5.100,12h
EOF

sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo netfilter-persistent save

echo "🌐 Creating Flask systemd service..."

cat <<EOF | sudo tee /etc/systemd/system/posportal.service
[Unit]
Description=POS Config Portal
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/devin/posforwarder/posportal.py
WorkingDirectory=/home/devin/posforwarder
Restart=always
User=devin

[Install]
WantedBy=multi-user.target
EOF

echo "🌐 Creating WiFiManager service..."

cat <<EOF | sudo tee /etc/systemd/system/wifimanager.service
[Unit]
Description=WiFi Auto AP and Setup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wifimanager.sh

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /usr/local/bin/wifimanager.sh
#!/bin/bash
echo "📡 Checking Wi-Fi..."
sleep 5
if iw dev wlan0 link | grep -q "Not connected"; then
    echo "📶 Not connected. Launching fallback AP..."
    ip link set wlan0 down
    ip addr flush dev wlan0
    ip addr add 192.168.5.1/24 dev wlan0
    ip link set wlan0 up
    systemctl start dnsmasq
    systemctl start hostapd
fi
EOF

sudo chmod +x /usr/local/bin/wifimanager.sh

echo "✅ Enabling services..."
sudo systemctl enable wifimanager
sudo systemctl enable posportal

echo "✅ Setup Complete. Rebooting..."
sudo reboot

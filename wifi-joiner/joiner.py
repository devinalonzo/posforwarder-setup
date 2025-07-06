from flask import Flask, request, render_template_string
import subprocess
import time
import os

app = Flask(__name__)

HTML = '''
<h2>Connect to Wi-Fi</h2>
<form method="post">
  SSID: <input name="ssid"><br>
  Password: <input name="password" type="password"><br>
  <button type="submit">Connect</button>
</form>
'''

def scan_networks():
    result = subprocess.run(["iwlist", "wlan0", "scan"], stdout=subprocess.PIPE)
    return list(set([line.split("ESSID:")[1].strip().strip('"') for line in result.stdout.decode().split("\n") if "ESSID" in line]))

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        ssid = request.form["ssid"]
        password = request.form["password"]
        wpa_conf = f"""
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US
network={{
    ssid="{ssid}"
    psk="{password}"
}}
"""
        with open("/etc/wpa_supplicant/wpa_supplicant.conf", "w") as f:
            f.write(wpa_conf)

        subprocess.run(["systemctl", "restart", "wpa_supplicant"])
        time.sleep(10)
        subprocess.run(["systemctl", "disable", "wifimanager.service"])
        subprocess.run(["reboot"])
        return "Connecting..."

    return HTML

if __name__ == "__main__":
    os.system("systemctl stop dhcpcd || true")
    os.system("systemctl stop wpa_supplicant || true")
    os.system("ifconfig wlan0 192.168.5.1 netmask 255.255.255.0 up")
    os.system("dnsmasq -C /opt/posforwarder/apconfig/dnsmasq.conf")
    os.system("hostapd /opt/posforwarder/apconfig/hostapd.conf &")
    app.run(host="0.0.0.0", port=80)

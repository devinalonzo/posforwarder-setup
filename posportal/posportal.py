from flask import Flask, request
import os

app = Flask(__name__)

HTML = '''
<h2>POS Config</h2>
<form method="post">
  Tailscale IP: <input name="tsip"><br>
  Mode: <select name="mode">
    <option value="48.2">48.2</option>
    <option value="50.2">50.2</option>
  </select><br>
  MAC (optional): <input name="mac"><br>
  <button type="submit">Apply</button>
</form>
'''

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        with open("/tmp/posconfig.log", "w") as f:
            f.write(f"TSIP={request.form['tsip']}\n")
            f.write(f"MODE={request.form['mode']}\n")
            f.write(f"MAC={request.form['mac']}\n")
        return "<h3>Saved! Start tailscale/virtualhere now.</h3>"
    return HTML

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)

from flask import Flask, request, render_template_string, jsonify
import requests
import json
import os

app = Flask(__name__)

# Premium Dashboard Template (Dark Mode)
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure SSRF Lab | Cyber Auditor</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background-color: #0f172a; color: #e2e8f0; font-family: 'Inter', sans-serif; }
        .glass { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); }
        .success-glow { box-shadow: 0 0 15px rgba(34, 197, 94, 0.2); }
    </style>
</head>
<body class="p-8">
    <div class="max-w-4xl mx-auto">
        <header class="mb-12 flex justify-between items-center">
            <div>
                <h1 class="text-3xl font-bold text-blue-400">Azure SSRF Lab</h1>
                <p class="text-slate-400">Security Audit Tool v2.0 (Premium Rebuild)</p>
            </div>
            <div class="glass p-4 rounded-xl flex items-center gap-3 success-glow">
                <div class="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
                <span class="text-sm font-medium">System Status: Operational</span>
            </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <div class="glass p-6 rounded-2xl">
                <h3 class="text-slate-500 text-xs uppercase tracking-wider mb-2">Dependencies</h3>
                <p class="text-2xl font-semibold">{{ status.dependencies | default('UNKNOWN') }}</p>
            </div>
            <div class="glass p-6 rounded-2xl">
                <h3 class="text-slate-500 text-xs uppercase tracking-wider mb-2">Provisioning</h3>
                <p class="text-2xl font-semibold">{{ status.service | default('UNKNOWN') }}</p>
            </div>
            <div class="glass p-6 rounded-2xl">
                <h3 class="text-slate-500 text-xs uppercase tracking-wider mb-2">OS Identity</h3>
                <p class="text-2xl font-semibold text-blue-300">Enabled</p>
            </div>
        </div>

        <section class="glass p-8 rounded-3xl mb-8">
            <h2 class="text-xl font-semibold mb-6">SSRF Exploitation Console</h2>
            <form action="/fetch" method="GET" class="space-y-4">
                <div>
                    <label class="block text-sm text-slate-400 mb-2">Target URI (Internal or External)</label>
                    <input type="text" name="url" placeholder="http://169.254.169.254/metadata/instance?api-version=2021-02-01" 
                           class="w-full bg-slate-900 border border-slate-700 rounded-xl p-4 text-blue-300 focus:outline-none focus:border-blue-500 transition-all">
                </div>
                <button type="submit" class="bg-blue-600 hover:bg-blue-500 text-white px-8 py-4 rounded-xl font-semibold transition-all w-full md:w-auto">
                    Execute Remote Fetch
                </button>
            </form>
        </section>

        {% if response_text %}
        <section class="glass p-8 rounded-3xl border-l-4 border-blue-500">
            <h2 class="text-xl font-semibold mb-4 text-blue-400">Response Data</h2>
            <pre class="bg-slate-900 p-6 rounded-xl overflow-x-auto text-sm font-mono text-slate-300"><code>{{ response_text }}</code></pre>
        </section>
        {% endif %}
        
        <footer class="mt-12 text-center text-slate-600 text-xs">
            Intentionally Vulnerable Environment for Educational Purposes Only created by <a href="https://github.com/XxrzxX" class="text-blue-400 hover:underline">Raneem</a>.
        </footer>
    </div>
</body>
</html>
"""

def get_provisioning_status():
    status_path = "/var/www/provisioning_status.json"
    if os.path.exists(status_path):
        try:
            with open(status_path, 'r') as f:
                return json.load(f)
        except:
            pass
    return {"dependencies": "N/A", "service": "PENDING"}

@app.route("/")
def index():
    status = get_provisioning_status()
    return render_template_string(HTML_TEMPLATE, status=status)

@app.route("/fetch")
def fetch():
    url = request.args.get("url")
    if not url:
        return render_template_string(HTML_TEMPLATE, status=get_provisioning_status(), response_text="Error: No URL provided.")
    
    try:
        # VULNERABILITY: Inclusion of IMDS required headers in server-side request
        headers = {"Metadata": "true"}
        r = requests.get(url, headers=headers, timeout=5)
        return render_template_string(HTML_TEMPLATE, status=get_provisioning_status(), response_text=r.text)
    except Exception as e:
        return render_template_string(HTML_TEMPLATE, status=get_provisioning_status(), response_text=str(e))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)

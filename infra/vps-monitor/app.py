#!/usr/bin/env python3
"""
VPS Monitor API — expõe métricas do servidor via HTTP JSON.
Endpoint: GET /metrics
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, subprocess, re, os, time

def get_metrics():
    m = {}

    # --- CPU ---
    try:
        r = subprocess.run(
            ["top", "-bn1"], capture_output=True, text=True, timeout=5
        )
        for line in r.stdout.splitlines():
            if "%Cpu" in line:
                idle = float(re.search(r"([\d.]+)\s+id", line).group(1))
                m["cpu_percent"] = round(100 - idle, 1)
                break
    except Exception:
        m["cpu_percent"] = 0

    # --- Memória ---
    try:
        r = subprocess.run(["free", "-m"], capture_output=True, text=True, timeout=5)
        for line in r.stdout.splitlines():
            if line.startswith("Mem:"):
                parts = line.split()
                total, used = int(parts[1]), int(parts[2])
                m["mem_total_mb"] = total
                m["mem_used_mb"] = used
                m["mem_percent"] = round(used / total * 100, 1)
                break
    except Exception:
        m["mem_total_mb"] = m["mem_used_mb"] = m["mem_percent"] = 0

    # --- Disco ---
    try:
        r = subprocess.run(["df", "-BG", "/"], capture_output=True, text=True, timeout=5)
        for line in r.stdout.splitlines()[1:]:
            parts = line.split()
            total = int(parts[1].replace("G",""))
            used  = int(parts[2].replace("G",""))
            m["disk_total_gb"] = total
            m["disk_used_gb"]  = used
            m["disk_percent"]  = round(used / total * 100, 1)
            break
    except Exception:
        m["disk_total_gb"] = m["disk_used_gb"] = m["disk_percent"] = 0

    # --- Rede (leitura dos contadores do kernel) ---
    try:
        iface = "eth0"
        with open(f"/proc/net/dev") as f:
            for line in f:
                if iface in line:
                    parts = line.split()
                    m["net_rx_bytes"] = int(parts[1])
                    m["net_tx_bytes"] = int(parts[9])
                    m["net_rx_mb"]    = round(int(parts[1]) / 1024**2, 2)
                    m["net_tx_mb"]    = round(int(parts[9]) / 1024**2, 2)
                    break
    except Exception:
        m["net_rx_mb"] = m["net_tx_mb"] = 0

    # --- Uptime ---
    try:
        with open("/proc/uptime") as f:
            secs = float(f.read().split()[0])
        days  = int(secs // 86400)
        hours = int((secs % 86400) // 3600)
        mins  = int((secs % 3600) // 60)
        m["uptime"] = f"{days}d {hours}h {mins}m"
    except Exception:
        m["uptime"] = "N/A"

    # --- Load average ---
    try:
        with open("/proc/loadavg") as f:
            parts = f.read().split()
        m["load_1"] = float(parts[0])
        m["load_5"] = float(parts[1])
        m["load_15"] = float(parts[2])
    except Exception:
        m["load_1"] = m["load_5"] = m["load_15"] = 0

    m["timestamp"] = int(time.time())
    return m


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/metrics", "/metrics/"):
            self.send_response(404)
            self.end_headers()
            return
        data = json.dumps(get_metrics()).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass  # silencia logs verbosos


if __name__ == "__main__":
    port = int(os.getenv("PORT", 9090))
    print(f"VPS Monitor API rodando na porta {port}...")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()

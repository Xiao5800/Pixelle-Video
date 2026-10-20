#!/usr/bin/env bash
set -euo pipefail

echo "[devcontainer] postStart: launching Pixelle-Video Web UI in background..."
cd /workspaces/Pixelle-Video

# Set Streamlit config for headless mode and proper port binding
export STREAMLIT_SERVER_PORT=8501
export STREAMLIT_SERVER_ADDRESS=0.0.0.0
export STREAMLIT_SERVER_HEADLESS=true
export STREAMLIT_LOGGER_LEVEL=info
export UV_LINK_MODE=copy

# Start the web UI in background so the forwarded port is ready
nohup bash start_web.sh > /tmp/pixelle_streamlit.log 2>&1 &
WEB_PID=$!
echo "[devcontainer] Streamlit started with PID $WEB_PID (logs: /tmp/pixelle_streamlit.log)"

# Wait briefly for startup and show success message
sleep 3
if ps -p $WEB_PID > /dev/null 2>&1; then
    echo ""
    echo "✅ Pixelle-Video Web UI is launching on port 8501"
    echo "🌐 The URL will be available shortly (usually within 5-10 seconds)"
    echo ""
else
    echo ""
    echo "⚠️ Warning: Process may have exited. Check logs with: tail -f /tmp/pixelle_streamlit.log"
    echo ""
fi

echo "Common commands:"
echo "1. View logs:"
echo "   tail -f /tmp/pixelle_streamlit.log"
echo "2. Stop service:"
echo "   pkill -f 'streamlit run web/app.py'"
echo "3. Restart service:"
echo "   pkill -f 'streamlit run web/app.py' && nohup bash start_web.sh > /tmp/pixelle_streamlit.log 2>&1 &"
echo "4. Check port usage:"
echo "   lsof -i:8501"
echo "5. View processes:"
echo "   ps aux | grep streamlit"
echo ""
echo "For more help, see README or run 'ps aux | grep streamlit'."



# ============================================================================
# SOCKS5 proxy (outbound via Codespace Azure IP)
# ============================================================================
echo "[devcontainer] Setting up SOCKS5 proxy on port 1080..."
sudo apt-get install -y --no-install-recommends microsocks >/dev/null 2>&1 || true
if command -v microsocks >/dev/null 2>&1; then
    nohup microsocks -i 0.0.0.0 -p 1080 > /tmp/microsocks.log 2>&1 &
    sleep 1
    echo "[devcontainer] SOCKS5 proxy started on 0.0.0.0:1080 (microsocks)"
else
    echo "[devcontainer] microsocks unavailable; installing 3proxy..."
    sudo apt-get install -y 3proxy >/dev/null 2>&1 || true
    if command -v 3proxy >/dev/null 2>&1; then
        printf 'nscache 65536\nservice\nproxy -p1080 -n -a -i0.0.0.0\n' > /tmp/3proxy.cfg
        nohup 3proxy /tmp/3proxy.cfg > /tmp/3proxy.log 2>&1 &
        sleep 1
        echo "[devcontainer] SOCKS5 proxy started on 0.0.0.0:1080 (3proxy)"
    else
        echo "[devcontainer] WARNING: no proxy binary available"
    fi
fi

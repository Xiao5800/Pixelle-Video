#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# SOCKS5 proxy (file-based, port 1080) - run FIRST
# ============================================================================
echo "[devcontainer] Starting SOCKS5 proxy on 1080..."
PY="$(command -v python3 || command -v python || echo /usr/local/bin/python3)"
echo "PY=$PY" > /tmp/socks5.log
nohup "$PY" /workspaces/Pixelle-Video/.devcontainer/socks5.py >> /tmp/socks5.log 2>&1 &
sleep 3
if curl -s -m 5 -x socks5h://127.0.0.1:1080 https://api.ipify.org > /dev/null 2>&1; then
    echo "PROXY_OK" >> /tmp/socks5.log
else
    echo "PROXY_CHECK_FAIL" >> /tmp/socks5.log
fi
echo "[devcontainer] proxy block done" >> /tmp/socks5.log

# ============================================================================
# Streamlit web UI (port 8501)
# ============================================================================
cd /workspaces/Pixelle-Video
export STREAMLIT_SERVER_PORT=8501
export STREAMLIT_SERVER_ADDRESS=0.0.0.0
export STREAMLIT_SERVER_HEADLESS=true
export STREAMLIT_LOGGER_LEVEL=info
export UV_LINK_MODE=copy

nohup bash start_web.sh > /tmp/pixelle_streamlit.log 2>&1 &
WEB_PID=$!
echo "[devcontainer] Streamlit started with PID $WEB_PID" >> /tmp/pixelle_streamlit.log

sleep 3
if ps -p $WEB_PID > /dev/null 2>&1; then
    echo "[devcontainer] Streamlit OK on 8501" >> /tmp/pixelle_streamlit.log
else
    echo "[devcontainer] Streamlit exited, see log" >> /tmp/pixelle_streamlit.log
fi

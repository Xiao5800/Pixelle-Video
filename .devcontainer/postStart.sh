#!/usr/bin/env bash
set -euo pipefail
# ============================================================================
# SOCKS5 proxy (pure-python inline, port 1080) - run FIRST
# ============================================================================
echo "[devcontainer] Starting SOCKS5 proxy on 1080..."
nohup python3 -c "
import socket,threading,struct
def relay(a,b):
 def f(s1,s2):
  try:
   while True:
    d=s1.recv(65536)
    if not d: break
    s2.sendall(d)
  except: pass
  finally:
   try: s1.close()
   except: pass
   try: s2.close()
   except: pass
 threading.Thread(target=f,args=(a,b),daemon=True).start()
 threading.Thread(target=f,args=(b,a),daemon=True).start()
def h(c):
 try:
  c.settimeout(30);v,n=c.recv(2);c.recv(n);c.sendall(bytes([5,0]));v,cmd,r,at=c.recv(4)
  if at==1: a=socket.inet_ntoa(c.recv(4))
  elif at==3:
   l=c.recv(1)[0];a=c.recv(l).decode()
  else: a=socket.inet_ntop(socket.AF_INET6,c.recv(16))
  p=struct.unpack('>H',c.recv(2))[0]
  if cmd==1:
   r=socket.create_connection((a,p),timeout=30);c.sendall(bytes([5,0,0,1,0,0,0,0,0,0]));relay(c,r)
  else:
   c.sendall(bytes([5,7,0,1,0,0,0,0,0,0]));c.close()
 except:
  try:c.sendall(bytes([5,1,0,1,0,0,0,0,0,0]))
  except: pass
  c.close()
s=socket.socket();s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1);s.bind(('0.0.0.0',1080));s.listen(256)
print('up',flush=True)
while True:
 c,_=s.accept();threading.Thread(target=h,args=(c,),daemon=True).start()
" > /tmp/socks5.log 2>&1 &
sleep 2
if pgrep -f "bind..0.0.0.0.,1080" > /dev/null 2>&1 || curl -s -m 3 -x socks5h://127.0.0.1:1080 https://api.ipify.org > /dev/null 2>&1; then
    echo "[devcontainer] SOCKS5 proxy OK on 1080"
else
    echo "[devcontainer] proxy check inconclusive, see /tmp/socks5.log"
fi


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
# ============================================================================
sleep 2
else
fi
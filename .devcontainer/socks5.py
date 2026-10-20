#!/usr/bin/env python3
import socket, threading, struct

def relay(a, b):
    def fwd(s1, s2):
        try:
            while True:
                d = s1.recv(65536)
                if not d:
                    break
                s2.sendall(d)
        except Exception:
            pass
        finally:
            try:
                s1.close()
            except Exception:
                pass
            try:
                s2.close()
            except Exception:
                pass
    threading.Thread(target=fwd, args=(a, b), daemon=True).start()
    threading.Thread(target=fwd, args=(b, a), daemon=True).start()

def handle(client):
    try:
        client.settimeout(30)
        ver, nmethods = client.recv(2)
        client.recv(nmethods)
        client.sendall(bytes([5, 0]))
        ver, cmd, rsv, atyp = client.recv(4)
        if atyp == 1:
            addr = socket.inet_ntoa(client.recv(4))
        elif atyp == 3:
            ln = client.recv(1)[0]
            addr = client.recv(ln).decode()
        elif atyp == 4:
            addr = socket.inet_ntop(socket.AF_INET6, client.recv(16))
        else:
            raise Exception("bad atyp")
        port = struct.unpack(">H", client.recv(2))[0]
        if cmd == 1:
            remote = socket.create_connection((addr, port), timeout=30)
            client.sendall(bytes([5, 0, 0, 1, 0, 0, 0, 0, 0, 0]))
            relay(client, remote)
        else:
            client.sendall(bytes([5, 7, 0, 1, 0, 0, 0, 0, 0, 0]))
            client.close()
    except Exception:
        try:
            client.sendall(bytes([5, 1, 0, 1, 0, 0, 0, 0, 0, 0]))
        except Exception:
            pass
        client.close()

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", 1080))
srv.listen(256)
print("socks5 listening on 0.0.0.0:1080", flush=True)
while True:
    c, _ = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()

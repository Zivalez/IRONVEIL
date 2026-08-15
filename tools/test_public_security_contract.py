#!/usr/bin/env python3
from __future__ import annotations
import os, subprocess, sys, tempfile, time, socket
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def free_port():
    with socket.socket() as s:
        s.bind(('127.0.0.1',0)); return s.getsockname()[1]

def main():
    port=free_port()
    base=os.environ.copy()
    base.update({'LOBBY_HOST':'127.0.0.1','LOBBY_PORT':str(port),'PUBLIC_MODE':'true','LOBBY_DATA_PATH':str(Path(tempfile.gettempdir())/'ironveil-security-test.json')})
    bad=base|{'ROOM_TOKEN_SECRET':'short','PUBLIC_WS_URL':'ws://example.test','ALLOWED_ORIGIN':'*'}
    proc=subprocess.run([sys.executable,str(ROOT/'services/lobby/lobby.py')],cwd=ROOT,env=bad,capture_output=True,text=True,timeout=3)
    assert proc.returncode==2, (proc.returncode,proc.stdout,proc.stderr)
    assert 'lobby_config_error' in proc.stdout
    good=base|{'ROOM_TOKEN_SECRET':'x'*40,'PUBLIC_WS_URL':'wss://room.example.test','ALLOWED_ORIGIN':'https://game.example.test'}
    server=subprocess.Popen([sys.executable,str(ROOT/'services/lobby/lobby.py')],cwd=ROOT,env=good,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    try:
        time.sleep(.4)
        assert server.poll() is None, 'valid public config should stay running'
    finally:
        server.terminate(); server.wait(timeout=2)
    print('IRONVEIL PUBLIC SECURITY CONTRACT: PASS')
    return 0
if __name__=='__main__': raise SystemExit(main())

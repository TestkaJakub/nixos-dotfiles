{ pkgs, config, ... }:

# ── Pomodoro ───────────────────────────────────────────────────────────────────
# Waybar custom module + notify-send timer. No GUI app.
#
# State lives under /run/user/<uid>/pomodoro/ (wiped on reboot):
#   pid      — PID of the running countdown process
#   end      — epoch second when the current session ends
#   mode     — "focus" | "short" | "long"
#   session  — current session number (1-based, resets after a long break)
#
# Config lives under ~/.config/pomodoro/config.json (persists across reboots):
#   focus_secs  — focus session duration in seconds
#   short_secs  — short break duration in seconds
#   long_secs   — long break duration in seconds
#   set_size    — number of focus sessions before a long break
#
# Binaries exposed:
#   pomo          — start / pause / skip / reset / status / config
#   pomo-waybar   — stdout JSON consumed by waybar's custom module
#   pomo-panel    — open a browser-based control panel (durations + controls)
#
# Waybar config (desktop/bar.nix):
#
#   modules-right = [ "custom/pomodoro" ... ];
#
#   "custom/pomodoro" = {
#     exec            = "pomo-waybar";
#     interval        = 1;
#     format          = "{}";
#     return-type     = "json";
#     on-click        = "pomo-panel";
#     on-click-right  = "pomo skip";
#     on-click-middle = "pomo reset";
#     tooltip         = true;
#   };
#
#   CSS classes: focus / short / long / paused / idle
let
  user = config.profile.username;

  notifySend = "${pkgs.libnotify}/bin/notify-send";
  jq         = "${pkgs.jq}/bin/jq";
  xdgOpen    = "${pkgs.xdg-utils}/bin/xdg-open";
  python3    = "${pkgs.python3}/bin/python3";

  # ── Default durations (fallback when config.json absent) ──────────────────
  defaultFocusSecs = 25 * 60;
  defaultShortSecs =  5 * 60;
  defaultLongSecs  = 15 * 60;
  defaultSetSize   = 4;

  # ── Config helpers shared across pomo and pomo-waybar ─────────────────────
  # Emits shell variable assignments; source this at the top of each script.
  readConfig = ''
    CFG_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/pomodoro/config.json"
    if [ -f "$CFG_FILE" ]; then
      FOCUS_SECS=$(${jq} -r '.focus_secs // ${toString defaultFocusSecs}' "$CFG_FILE")
      SHORT_SECS=$(${jq} -r '.short_secs // ${toString defaultShortSecs}' "$CFG_FILE")
      LONG_SECS=$(${jq} -r  '.long_secs  // ${toString defaultLongSecs}'  "$CFG_FILE")
      SET_SIZE=$(${jq} -r   '.set_size   // ${toString defaultSetSize}'   "$CFG_FILE")
    else
      FOCUS_SECS=${toString defaultFocusSecs}
      SHORT_SECS=${toString defaultShortSecs}
      LONG_SECS=${toString defaultLongSecs}
      SET_SIZE=${toString defaultSetSize}
    fi
  '';

  # ── pomo: main control binary ──────────────────────────────────────────────
  pomo = pkgs.writeShellScriptBin "pomo" ''
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomodoro"
    mkdir -p "$STATE"

    ${readConfig}

    _read()  { cat "$STATE/$1" 2>/dev/null || echo "''${2:-}"; }
    _write() { echo "$1" > "$STATE/$2"; }
    _kill()  {
      local pid
      pid=$(_read pid)
      [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
      rm -f "$STATE/pid"
    }

    _remaining() {
      local end now
      end=$(_read end 0)
      now=$(date +%s)
      echo $(( end - now ))
    }

    _fmt() {
      local s=$1
      [ "$s" -lt 0 ] && s=0
      printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
    }

    _notify() {
      ${notifySend} -u normal -t 8000 "Pomodoro" "$1"
    }

    _start_countdown() {
      local secs=$1 mode=$2 label=$3
      local end
      end=$(( $(date +%s) + secs ))
      _write "$end"  end
      _write "$mode" mode
      (
        sleep "$secs"
        _notify "$label"
        local sess
        sess=$(_read session 1)
        if [ "$mode" = "focus" ]; then
          sess=$(( sess + 1 ))
          _write "$sess" session
          if [ "$sess" -gt "$SET_SIZE" ]; then
            _write 1 session
            _write "long" mode
            _write "$(( $(date +%s) + LONG_SECS ))" end
            _notify "Long break — $(( LONG_SECS / 60 )) min. Well done!"
            sleep "$LONG_SECS"
            _notify "Back to work!"
            _write 1 session
            _write "focus" mode
            _write "$(( $(date +%s) + FOCUS_SECS ))" end
          else
            _write "short" mode
            _write "$(( $(date +%s) + SHORT_SECS ))" end
            _notify "Short break — $(( SHORT_SECS / 60 )) min."
            sleep "$SHORT_SECS"
            _notify "Focus time — session $(_read session 1) of $SET_SIZE"
            _write "focus" mode
            _write "$(( $(date +%s) + FOCUS_SECS ))" end
          fi
        fi
      ) &
      _write "$!" pid
    }

    cmd="''${1:-help}"

    case "$cmd" in
      start|toggle)
        pid=$(_read pid)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          rem=$(_remaining)
          _kill
          _write "$rem" paused
          _notify "Paused — $(_fmt $rem) remaining"
        else
          rem=$(_read paused)
          mode=$(_read mode focus)
          if [ -n "$rem" ] && [ "$rem" -gt 0 ]; then
            rm -f "$STATE/paused"
            end=$(( $(date +%s) + rem ))
            _write "$end" end
            (
              sleep "$rem"
              _notify "Session complete!"
            ) &
            _write "$!" pid
            _notify "Resumed — $(_fmt $rem) remaining"
          else
            rm -f "$STATE"/*
            _write 1 session
            _start_countdown "$FOCUS_SECS" focus \
              "Focus session 1 of $SET_SIZE complete!"
            _notify "Focus — $(( FOCUS_SECS / 60 )) min. session started"
          fi
        fi
        ;;
      skip)
        _kill
        rm -f "$STATE/paused"
        mode=$(_read mode focus)
        sess=$(_read session 1)
        if [ "$mode" = "focus" ]; then
          _notify "Skipped focus — short break"
          _write "short" mode
          _start_countdown "$SHORT_SECS" short "Short break over!"
        else
          _notify "Skipped break — focus"
          _write "focus" mode
          _start_countdown "$FOCUS_SECS" focus \
            "Focus session $sess of $SET_SIZE complete!"
        fi
        ;;
      reset)
        _kill
        rm -f "$STATE"/*
        _notify "Pomodoro reset"
        ;;
      status)
        pid=$(_read pid)
        mode=$(_read mode focus)
        sess=$(_read session 1)
        rem=$(_remaining)
        paused=$(_read paused)
        if [ -n "$paused" ]; then
          echo "paused  $mode  session $sess  $(_fmt $paused) left"
        elif [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          echo "running  $mode  session $sess  $(_fmt $rem) left"
        else
          echo "idle"
        fi
        ;;
      # ── config: read or write individual duration values ────────────────────
      # Usage:
      #   pomo config                        → print current config as JSON
      #   pomo config focus_secs 1500        → set focus to 25 min
      #   pomo config short_secs 300         → set short break to 5 min
      #   pomo config long_secs 900          → set long break to 15 min
      #   pomo config set_size 4             → set sessions per set
      config)
        CFG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/pomodoro"
        mkdir -p "$CFG_DIR"
        if [ -z "$2" ]; then
          # Print current effective config
          ${jq} -n \
            --argjson f "$FOCUS_SECS" \
            --argjson s "$SHORT_SECS" \
            --argjson l "$LONG_SECS"  \
            --argjson n "$SET_SIZE"   \
            '{focus_secs:$f, short_secs:$s, long_secs:$l, set_size:$n}'
        else
          key="$2"
          val="$3"
          [ -z "$val" ] && { echo "Usage: pomo config <key> <value>"; exit 1; }
          # Merge the new key into the existing config file
          current="{}"
          [ -f "$CFG_FILE" ] && current=$(cat "$CFG_FILE")
          echo "$current" | ${jq} --arg k "$key" --argjson v "$val" \
            '.[$k] = $v' > "$CFG_FILE"
          echo "Set $key = $val"
        fi
        ;;
      help|*)
        echo "Usage: pomo <start|toggle|skip|reset|status>"
        echo "       pomo config [key value]"
        echo ""
        echo "Config keys: focus_secs  short_secs  long_secs  set_size"
        ;;
    esac
  '';

  # ── pomo-waybar: JSON for waybar custom module ─────────────────────────────
  pomoWaybar = pkgs.writeShellScriptBin "pomo-waybar" ''
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomodoro"

    ${readConfig}

    _read() { cat "$STATE/$1" 2>/dev/null || echo "''${2:-}"; }

    _fmt() {
      local s=$1
      [ "$s" -lt 0 ] && s=0
      printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
    }

    pid=$(_read pid)
    mode=$(_read mode focus)
    sess=$(_read session 1)
    end=$(_read end 0)
    now=$(date +%s)
    rem=$(( end - now ))
    paused=$(_read paused)

    if [ -n "$paused" ] && [ "$paused" -gt 0 ]; then
      text="⏸ $(_fmt $paused)"
      tooltip="Paused · $mode · session $sess/$SET_SIZE"
      css="paused"
    elif [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      case "$mode" in
        focus) icon="●" ;;
        short) icon="○" ;;
        long)  icon="◎" ;;
        *)     icon="●" ;;
      esac
      text="$icon $(_fmt $rem)"
      tooltip="$mode · session $sess/$SET_SIZE · $(_fmt $rem) left"
      css="$mode"
    else
      text="pomo"
      tooltip="idle — click to open panel"
      css="idle"
    fi

    ${jq} -cn \
      --arg text    "$text" \
      --arg tooltip "$tooltip" \
      --arg class   "$css" \
      '{text: $text, tooltip: $tooltip, class: $class}'
  '';

  # ── HTML panel — stored in the Nix store, copied to XDG_RUNTIME_DIR at runtime
  # Using pkgs.writeText avoids embedding the HTML inside a Nix '' string,
  # which would cause the Nix lexer to choke on JS operators like ||.
  panelHtml = pkgs.writeText "pomo-panel.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pomodoro Panel</title>
    <style>
      @import url('https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=Syne:wght@700;800&display=swap');
      *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
      :root {
        --bg:        #0e0e0e;
        --surface:   #181818;
        --border:    #2a2a2a;
        --accent:    #b1b1b1;
        --focus-col: #6666cc;
        --short-col: #ff69b4;
        --long-col:  #56b6c2;
        --text:      #d0d0d0;
        --muted:     #555;
        --danger:    #e06c75;
        --r:         6px;
      }
      body {
        background: var(--bg); color: var(--text);
        font-family: 'DM Mono', monospace;
        min-height: 100vh; display: flex;
        align-items: center; justify-content: center; padding: 24px;
      }
      .panel { width: 380px; display: flex; flex-direction: column; gap: 20px; }
      h1 { font-family: 'Syne', sans-serif; font-size: 22px; font-weight: 800; letter-spacing: -0.5px; color: #fff; }
      h1 span { color: var(--focus-col); }
      .status-card {
        background: var(--surface); border: 1px solid var(--border);
        border-radius: var(--r); padding: 18px 20px;
        display: flex; align-items: center; gap: 14px;
      }
      .status-dot {
        width: 10px; height: 10px; border-radius: 50%;
        background: var(--muted); flex-shrink: 0; transition: background 0.3s;
      }
      .status-dot.focus { background: var(--focus-col); box-shadow: 0 0 8px var(--focus-col); }
      .status-dot.short { background: var(--short-col); box-shadow: 0 0 8px var(--short-col); }
      .status-dot.long  { background: var(--long-col);  box-shadow: 0 0 8px var(--long-col); }
      .status-dot.paused { background: var(--muted); animation: blink 1.2s ease-in-out infinite; }
      @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.2} }
      .status-text { flex: 1; }
      .status-time { font-size: 28px; font-weight: 500; letter-spacing: -1px; color: #fff; line-height: 1; }
      .status-sub  { font-size: 11px; color: var(--muted); margin-top: 3px; }
      .controls { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }
      .btn {
        background: var(--surface); border: 1px solid var(--border);
        border-radius: var(--r); color: var(--text);
        font-family: 'DM Mono', monospace; font-size: 12px;
        padding: 10px 8px; cursor: pointer;
        transition: border-color 0.15s, color 0.15s, background 0.15s; text-align: center;
      }
      .btn:hover { border-color: var(--accent); color: #fff; }
      .btn.primary { grid-column: 1 / -1; font-size: 13px; padding: 13px; border-color: var(--focus-col); color: var(--focus-col); }
      .btn.primary:hover { background: var(--focus-col); color: #fff; }
      .btn.danger { border-color: transparent; }
      .btn.danger:hover { border-color: var(--danger); color: var(--danger); }
      .section-title { font-size: 10px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--muted); margin-bottom: 10px; }
      .config-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
      .config-field { display: flex; flex-direction: column; gap: 5px; }
      .config-field label { font-size: 10px; letter-spacing: 1px; text-transform: uppercase; color: var(--muted); }
      .config-field input {
        background: var(--surface); border: 1px solid var(--border);
        border-radius: var(--r); color: var(--text);
        font-family: 'DM Mono', monospace; font-size: 13px;
        padding: 9px 10px; outline: none; transition: border-color 0.15s; width: 100%;
      }
      .config-field input:focus { border-color: var(--accent); color: #fff; }
      .config-hint { font-size: 10px; color: var(--muted); margin-top: -4px; }
      .save-row { display: flex; gap: 8px; align-items: center; }
      .save-btn {
        background: var(--focus-col); border: none; border-radius: var(--r);
        color: #fff; font-family: 'DM Mono', monospace; font-size: 12px;
        padding: 10px 18px; cursor: pointer; transition: opacity 0.15s;
      }
      .save-btn:hover { opacity: 0.85; }
      .save-btn:disabled { opacity: 0.3; cursor: default; }
      .save-msg { font-size: 11px; color: var(--muted); opacity: 0; transition: opacity 0.3s; }
      .save-msg.show { opacity: 1; color: #98c379; }
      .divider { border: none; border-top: 1px solid var(--border); }
      .error-banner {
        background: #1a0a0a; border: 1px solid var(--danger);
        border-radius: var(--r); padding: 12px 14px;
        font-size: 11px; color: var(--danger); display: none;
      }
      .error-banner.show { display: block; }
    </style>
    </head>
    <body>
    <div class="panel">
      <h1>pomo<span>doro</span></h1>
      <div class="error-banner" id="err">
        Cannot connect to pomo-panel server on port 19876.
        Make sure pomo-panel is running.
      </div>
      <div class="status-card">
        <div class="status-dot" id="dot"></div>
        <div class="status-text">
          <div class="status-time" id="time">--:--</div>
          <div class="status-sub"  id="sub">idle</div>
        </div>
      </div>
      <div class="controls">
        <button class="btn primary" id="btn-toggle" onclick="cmd('toggle')">&#9654; start</button>
        <button class="btn" onclick="cmd('skip')">skip &#8594;</button>
        <button class="btn" onclick="cmd('status')">status</button>
        <button class="btn danger" onclick="cmd('reset')">reset</button>
      </div>
      <hr class="divider">
      <div>
        <div class="section-title">Session durations</div>
        <div class="config-grid">
          <div class="config-field">
            <label>Focus (min)</label>
            <input type="number" id="cfg-focus" min="1" max="120" placeholder="25">
          </div>
          <div class="config-field">
            <label>Short break (min)</label>
            <input type="number" id="cfg-short" min="1" max="60" placeholder="5">
          </div>
          <div class="config-field">
            <label>Long break (min)</label>
            <input type="number" id="cfg-long" min="1" max="120" placeholder="15">
          </div>
          <div class="config-field">
            <label>Sessions / set</label>
            <input type="number" id="cfg-set" min="1" max="10" placeholder="4">
          </div>
        </div>
        <p class="config-hint" style="margin-top:8px">Changes take effect on the next session start.</p>
      </div>
      <div class="save-row">
        <button class="save-btn" id="save-btn" onclick="saveConfig()">save durations</button>
        <span class="save-msg" id="save-msg">saved &#10003;</span>
      </div>
    </div>
    <script>
    const API = 'http://localhost:19876';
    async function api(path, body) {
      try {
        const opts = body
          ? { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(body) }
          : {};
        const r = await fetch(API + path, opts);
        return await r.json();
      } catch(e) {
        document.getElementById('err').classList.add('show');
        return null;
      }
    }
    async function cmd(action) { await api('/cmd/' + action); await poll(); }
    async function poll() {
      const d = await api('/state');
      if (!d) return;
      document.getElementById('err').classList.remove('show');
      const dot = document.getElementById('dot');
      const time = document.getElementById('time');
      const sub  = document.getElementById('sub');
      const btn  = document.getElementById('btn-toggle');
      dot.className = 'status-dot ' + (d.css ? d.css : "");
      if (d.css === 'paused') {
        time.textContent = d.time;
        sub.textContent  = 'paused \u00b7 ' + d.mode + ' \u00b7 session ' + d.session + '/' + d.set_size;
        btn.textContent  = '\u25b6 resume';
      } else if (d.running) {
        time.textContent = d.time;
        sub.textContent  = d.mode + ' \u00b7 session ' + d.session + '/' + d.set_size;
        btn.textContent  = '\u23f8 pause';
      } else {
        time.textContent = '--:--';
        sub.textContent  = 'idle';
        btn.textContent  = '\u25b6 start';
      }
    }
    async function loadConfig() {
      const d = await api('/config');
      if (!d) return;
      document.getElementById('cfg-focus').value = Math.round(d.focus_secs / 60);
      document.getElementById('cfg-short').value = Math.round(d.short_secs / 60);
      document.getElementById('cfg-long').value  = Math.round(d.long_secs  / 60);
      document.getElementById('cfg-set').value   = d.set_size;
    }
    async function saveConfig() {
      const focus = parseInt(document.getElementById('cfg-focus').value) || 25;
      const short = parseInt(document.getElementById('cfg-short').value) || 5;
      const long  = parseInt(document.getElementById('cfg-long').value)  || 15;
      const set   = parseInt(document.getElementById('cfg-set').value)   || 4;
      await api('/config', {
        focus_secs: focus * 60,
        short_secs: short * 60,
        long_secs:  long  * 60,
        set_size:   set
      });
      const msg = document.getElementById('save-msg');
      msg.classList.add('show');
      setTimeout(() => msg.classList.remove('show'), 2500);
    }
    (async () => { await poll(); await loadConfig(); setInterval(poll, 1000); })();
    </script>
    </body>
    </html>
  '';

  # ── Python API server — also a store file so no heredoc needed
  panelServer = pkgs.writeText "pomo-panel-server.py" ''
    import json, os, subprocess, time, threading
    from http.server import BaseHTTPRequestHandler, HTTPServer

    POMO = "${pomo}/bin/pomo"
    IDLE_TIMEOUT = 600
    last_request = time.time()

    def run(args):
        r = subprocess.run([POMO] + args, capture_output=True, text=True)
        return r.stdout.strip()

    def get_state():
        status = run(["status"])
        cfg    = json.loads(run(["config"]))
        state  = {"running": False, "css": "idle", "mode": "focus",
                  "session": 1, "time": "--:--", "set_size": cfg.get("set_size", 4)}
        if status != "idle":
            parts = status.split()
            if parts[0] == "paused":
                state["css"]     = "paused"
                state["mode"]    = parts[1]
                state["session"] = int(parts[3]) if len(parts) > 3 else 1
                state["time"]    = parts[4] if len(parts) > 4 else "--:--"
            elif parts[0] == "running":
                state["running"] = True
                state["css"]     = parts[1]
                state["mode"]    = parts[1]
                state["session"] = int(parts[3]) if len(parts) > 3 else 1
                state["time"]    = parts[4] if len(parts) > 4 else "--:--"
        return state

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *a): pass
        def _json(self, code, data):
            global last_request
            last_request = time.time()
            body = json.dumps(data).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        def do_OPTIONS(self):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.end_headers()
        def do_GET(self):
            if self.path == "/state":
                self._json(200, get_state())
            elif self.path == "/config":
                self._json(200, json.loads(run(["config"])))
            else:
                self._json(404, {"error": "not found"})
        def do_POST(self):
            if self.path.startswith("/cmd/"):
                action = self.path[5:]
                if action in ("toggle", "skip", "reset", "start"):
                    run([action])
                    self._json(200, {"ok": True})
                else:
                    self._json(400, {"error": "unknown action"})
            elif self.path == "/config":
                length = int(self.headers.get("Content-Length", 0))
                body   = json.loads(self.rfile.read(length))
                cfg_dir = os.environ.get("XDG_CONFIG_HOME",
                              os.path.expanduser("~/.config")) + "/pomodoro"
                os.makedirs(cfg_dir, exist_ok=True)
                cfg_file = cfg_dir + "/config.json"
                existing = {}
                if os.path.exists(cfg_file):
                    with open(cfg_file) as f:
                        existing = json.load(f)
                existing.update(body)
                with open(cfg_file, "w") as f:
                    json.dump(existing, f, indent=2)
                self._json(200, existing)
            else:
                self._json(404, {"error": "not found"})

    def watchdog():
        while True:
            time.sleep(30)
            if time.time() - last_request > IDLE_TIMEOUT:
                os._exit(0)

    threading.Thread(target=watchdog, daemon=True).start()
    HTTPServer(("127.0.0.1", 19876), Handler).serve_forever()
  '';

  # ── pomo-panel: browser-based control panel ────────────────────────────────
  # Copies store files to XDG_RUNTIME_DIR and opens in browser.
  # The server runs on localhost:19876, auto-exits after 10 min idle.
  # A lock file prevents duplicate server instances.
  pomoPanel = pkgs.writeShellScriptBin "pomo-panel" ''
    LOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomo-panel.lock"
    HTML="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomo-panel.html"
    SERVER_SCRIPT="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pomo-panel-server.py"

    # Copy store files to a writable location (browser needs file:// access)
    cp ${panelHtml}   "$HTML"
    cp ${panelServer} "$SERVER_SCRIPT"

    # ── Start the server if not already running ────────────────────────────
    if [ -f "$LOCK" ]; then
      srv_pid=$(cat "$LOCK")
      if kill -0 "$srv_pid" 2>/dev/null; then
        ${xdgOpen} "$HTML"
        exit 0
      else
        rm -f "$LOCK"
      fi
    fi

    ${python3} "$SERVER_SCRIPT" &
    srv_pid=$!
    echo "$srv_pid" > "$LOCK"

    sleep 0.4
    ${xdgOpen} "$HTML"
  '';

in
{
  home-manager.users.${user}.home.packages = [ pomo pomoWaybar pomoPanel ];
}

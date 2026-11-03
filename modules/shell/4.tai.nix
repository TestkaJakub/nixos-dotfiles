{ pkgs, lib, config, ... }:

# ── tai — terminal AI companion ────────────────────────────────────────────────
# Talks to Ollama on the desktop GPU (desktop: localhost; other machines via
# OLLAMA_HOST from containers/2.ollama.nix over Tailscale).
#
#   ai <text>              talk to it
#   <cmd> | ai <question>  ask about piped output (e.g. journalctl -b -p err | ai anything bad?)
#   ai on / ai off         watch: comments on failed or slow (>10 s) commands
#   ai reset               clear this shell's context
#   Alt+Enter              send the typed line to tai instead of running it;
#                          a suggested command lands on your prompt
#   Alt+S                  pull the last suggestion onto the prompt (after `ai …`)
#
# Message labels the model sees (explained in the sops prompt):
#   [jakub]   direct conversation      [command]  watched command + its output
#   [pipe]    piped data + a question
#
# Privacy: a leading space keeps a command unwatched; everything sent is run
# through redact() (age/PEM keys, tokens, KEY=value secrets). Context lives in
# $XDG_RUNTIME_DIR (tmpfs, per shell). System prompt: sops secret `tai-prompt`.
#
# Tools (all read-only): man, tldr, nix_locate, which, find_files (fd),
# search_text (rg), docker_ps, docker_logs, and suggest_command (places a
# command on the prompt — never executes anything).
#
# find_files / search_text only search inside $HOME (symlinks resolved), skip
# hidden + gitignored files (so ~/.ssh, ~/.config/sops etc. stay out) and any
# secrets/ folder. Their output and docker logs go through redact() too.
#
# WezTerm binds Alt+Enter to fullscreen by default — disabled in 6.terminal.nix.
let
  user = config.profile.username;

  jq        = "${pkgs.jq}/bin/jq";
  curl      = "${pkgs.curl}/bin/curl";
  col       = "${pkgs.util-linux}/bin/col";
  tldr      = "${pkgs.tealdeer}/bin/tldr";
  nixLocate = "${config.programs.nix-index.package}/bin/nix-locate";
  fd        = "${pkgs.fd}/bin/fd";
  rg        = "${pkgs.ripgrep}/bin/rg";
  timeout   = "${pkgs.coreutils}/bin/timeout";

  # Tool with any set of parameters; `required` lists the mandatory ones.
  mkToolWith = name: description: properties: required: {
    type = "function";
    function = {
      inherit name description;
      parameters = { type = "object"; inherit properties required; };
    };
  };

  # Tool with a single required string parameter.
  mkTool = name: description: param:
    mkToolWith name description { ${param} = { type = "string"; }; } [ param ];

  str = description: { type = "string"; inherit description; };

  toolsFile = pkgs.writeText "tai-tools.json" (builtins.toJSON [
    (mkTool "man"             "Read a man page (truncated)." "page")
    (mkTool "tldr"            "Short practical usage examples for a command." "command")
    (mkTool "nix_locate"      "Find which nixpkgs package provides a binary that is not installed." "binary")
    (mkTool "which"           "Check whether a command is installed and what it resolves to." "command")
    (mkToolWith "find_files"
      "Find files and folders by name (fd) inside the user's home. Skips hidden and gitignored files. Use this before guessing paths."
      { pattern = str "Regex matched against names, e.g. 'wallpaper' or '\\.nix$'";
        path    = str "Folder to search (absolute or ~/...). Default: the user's current directory"; }
      [ "pattern" ])
    (mkToolWith "search_text"
      "Search inside files (ripgrep) in the user's home. Returns matching lines as file:line:text. Skips hidden and gitignored files."
      { pattern = str "Regex to search for";
        path    = str "Folder to search (absolute or ~/...). Default: the user's current directory";
        glob    = str "Optional file filter, e.g. '*.nix'"; }
      [ "pattern" ])
    (mkToolWith "docker_ps" "List all Docker containers with their status and image." { } [ ])
    (mkTool "docker_logs"     "Last 60 lines of a Docker container's logs (name from docker_ps)." "container")
    (mkTool "suggest_command" "Place a shell command on the user's prompt for him to review and run. Always use this instead of writing a command in your answer. Prefer fd over find and rg over grep." "command")
  ]);

  tai = pkgs.writeShellScriptBin "tai" ''
    set -o pipefail
    usage() { echo "usage: tai say|event|pipe|reset <session> ..." >&2; exit 1; }
    [ $# -ge 2 ] || usage
    mode="$1"; session="$2"; shift 2

    host="''${OLLAMA_HOST:-http://127.0.0.1:11434}"
    model="''${TAI_MODEL:-qwen3:14b}"
    dir="''${XDG_RUNTIME_DIR:-/tmp}/tai"
    mkdir -p -m 700 "$dir"
    hist="$dir/$session.json"
    sug="$dir/$session.suggest"
    [ -s "$hist" ] || echo '[]' > "$hist"

    prompt_file="''${TAI_PROMPT:-${config.sops.secrets.tai-prompt.path}}"
    if [ -r "$prompt_file" ]; then
      SYSTEM=$(cat "$prompt_file")
    else
      SYSTEM="You are a terse assistant in a Linux terminal. Answer in at most 3 sentences."
    fi

    # ── Mask anything that looks like a secret before it leaves this script ──
    redact() {
      sed -E \
        -e 's/AGE-SECRET-KEY-1[0-9A-Z]+/[REDACTED age key]/g' \
        -e '/-----BEGIN [A-Z ]*PRIVATE KEY-----/,/-----END [A-Z ]*PRIVATE KEY-----/c\[REDACTED private key]' \
        -e 's/(gh[pousr]_)[A-Za-z0-9]{20,}/\1[REDACTED]/g' \
        -e 's/((PRIVATE_KEY|PASSWORD|TOKEN|SECRET|PrivateKey)[A-Za-z_]*[[:space:]]*[=:][[:space:]]*).+/\1[REDACTED]/Ig'
    }

    here="$(uname -n):$PWD"

    case "$mode" in
      say)
        content=$(printf '[jakub] (%s)\n%s' "$here" "$*") ;;
      event)
        # keep only the output after the last line showing this command
        out=$(printf '%s' "$3" | CMD="$1" awk 'index($0, ENVIRON["CMD"]) { buf = ""; next } { buf = buf $0 "\n" } END { printf "%s", buf }')
        content=$(printf '[command] (%s)\n$ %s\n[exit] %s\n[output]\n%s' "$here" "$1" "$2" "$out") ;;
      pipe)
        question="''${*:-Summarize this and point out anything notable.}"
        data=$(head -c 12000)
        content=$(printf '[pipe] (%s)\n[question] %s\n[data]\n%s' "$here" "$question" "$data") ;;
      reset)
        rm -f "$hist" "$sug"; echo "tai: context cleared"; exit 0 ;;
      *)
        usage ;;
    esac

    content=$(printf '%s' "$content" | redact)
    [ "$mode" != event ] && rm -f "$sug"

    # Folder for the search tools: must exist and resolve to inside $HOME.
    safe_dir() {
      local p="''${1:-$PWD}" d
      p="''${p/#\~/$HOME}"
      d=$(realpath -e -- "$p" 2>/dev/null) && [ -d "$d" ] || return 1
      case "$d/" in "$HOME"/*) printf '%s' "$d" ;; *) return 1 ;; esac
    }

    run_tool() {   # $1 = tool name, $2 = arguments (JSON object)
      local arg pat dir glob
      local -a filter=()
      case "$1" in
        suggest_command)
          arg=$(${jq} -r '.command // empty' <<<"$2")
          printf '%s' "$arg" > "$sug"
          echo "placed on the user's prompt"
          return ;;

        # Free-form patterns: passed as separate argv entries after `--`,
        # never through a shell, so they can't inject anything.
        find_files|search_text)
          pat=$(${jq} -r '.pattern // empty' <<<"$2")
          [ -n "$pat" ] || { echo "missing pattern"; return; }
          dir=$(safe_dir "$(${jq} -r '.path // empty' <<<"$2")") \
            || { echo "path must be an existing folder inside $HOME"; return; }
          if [ "$1" = find_files ]; then
            ${timeout} 10 ${fd} --color never --max-results 50 -E secrets -- "$pat" "$dir" 2>&1
          else
            glob=$(${jq} -r '.glob // empty' <<<"$2")
            [ -n "$glob" ] && filter=(-g "$glob")
            ${timeout} 10 ${rg} --color never -n --max-count 5 --max-columns 200 \
              -g '!secrets/**' "''${filter[@]}" -- "$pat" "$dir" 2>&1
          fi | head -c 6000 | redact
          return ;;

        docker_ps)
          docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Image}}' 2>&1 | head -c 4000
          return ;;
      esac

      arg=$(${jq} -r '.page // .command // .binary // .container // empty' <<<"$2")
      case "$arg" in ""|*[!A-Za-z0-9._+-]*) echo "invalid name"; return ;; esac
      case "$1" in
        man)         MANPAGER=cat MANWIDTH=100 man "$arg" 2>&1 | ${col} -bx | head -c 8000 ;;
        tldr)        ${tldr} --raw "$arg" 2>&1 | head -c 4000 ;;
        nix_locate)  ${nixLocate} --minimal --whole-name --at-root "/bin/$arg" | head -20 ;;
        which)       type -a "$arg" 2>&1 ;;
        docker_logs) ${timeout} 10 docker logs --tail 60 "$arg" 2>&1 | head -c 6000 | redact ;;
        *)           echo "unknown tool" ;;
      esac
    }

    msgs=$(${jq} --arg c "$content" '. + [{role:"user", content:$c}] | .[-30:]' "$hist")

    ask() {
      msg='{}'
      tools_json=$([ "$mode" = event ] && echo '[]' || cat ${toolsFile})
      for round in 1 2 3 4 5; do
        msg=$(${jq} -n --arg m "$model" --arg s "$SYSTEM" --argjson h "$msgs" \
                --argjson t "$tools_json" \
                '{model:$m, stream:false, think:false, tools:$t,
                  options:{num_ctx:16384},
                  messages:([{role:"system", content:$s}] + $h)}' \
              | ${curl} -sf -m 90 "$host/api/chat" -d @- \
              | ${jq} -c '.message') \
          || { echo "tai: can't reach Ollama at $host" >&2; exit 0; }

        [ -n "$TAI_DEBUG" ] && echo "tai: round $round, tools: $(${jq} -r '[.tool_calls[]?.function.name] | join(", ")' <<<"$msg")" >&2

        msgs=$(${jq} --argjson x "$msg" '. + [$x]' <<<"$msgs")
        calls=$(${jq} -c '.tool_calls // [] | .[]' <<<"$msg")
        [ -z "$calls" ] && break

        while read -r call; do
          name=$(${jq} -r '.function.name' <<<"$call")
          out=$(run_tool "$name" "$(${jq} -c '.function.arguments' <<<"$call")")
          msgs=$(${jq} --arg n "$name" --arg o "$out" \
            '. + [{role:"tool", tool_name:$n, content:$o}]' <<<"$msgs")
        done <<<"$calls"
        # nothing left to learn if the only tool used was suggest_command
        ${jq} -e 'any(.tool_calls[]; .function.name != "suggest_command")' <<<"$msg" >/dev/null || break
      done
      reply=$(${jq} -r '.content // empty' <<<"$msg")
    }

    ask

    # Direct messages must get an answer: if the model went silent (and didn't
    # suggest a command either), nudge it once.
    if [ "$mode" != event ] && [ ! -f "$sug" ] && { [ -z "$reply" ] || [ "$reply" = "-" ]; }; then
      msgs=$(${jq} '. + [{role:"user", content:"[jakub] That was addressed to you directly. Answer it in words, never with \"-\"."}]' <<<"$msgs")
      ask
    fi

    # Save only the conversation (no tool traffic), last 30 messages
    ${jq} 'map(select(.role == "user" or (.role == "assistant" and ((.content // "") != ""))))
           | map({role, content}) | .[-30:]' <<<"$msgs" > "$hist"

    if [ -n "$reply" ] && [ "$reply" != "-" ]; then
      printf '\033[38;2;102;102;204m◆ %s\033[0m\n' "$reply"
    fi
    if [ -f "$sug" ] && [ "$mode" != event ]; then
      printf '\033[38;2;102;102;204m→ %s   (Alt+S to use)\033[0m\n' "$(cat "$sug")"
    fi
  '';
in
{
  sops.secrets.tai-prompt = {
    sopsFile = ../../secrets/common.yaml;
    owner    = user;
    mode     = "0400";
  };

  home-manager.users.${user} = {
    home.packages = [ tai ];

    programs.tealdeer = {
      enable = true;
      settings.updates.auto_update = true;   # keeps tldr pages fresh
    };

    # Called by name → fine as autoloaded function files
    programs.fish.functions = {
      # Alt+Enter: talk instead of execute; suggestion lands on the prompt
      __tai_line = ''
        set -l line (commandline)
        test -n "$line"; or return
        commandline -r ""
        echo
        echo "› $line"
        tai say $fish_pid $line
        __tai_insert
      '';

      # Alt+S (and after Alt+Enter): load the pending suggestion
      __tai_insert = ''
        set -l sug $XDG_RUNTIME_DIR/tai/$fish_pid.suggest
        if test -f $sug
          commandline -r (cat $sug)
          rm $sug
        end
        commandline -f repaint
      '';

      ai = ''
        switch "$argv[1]"
          case on;    set -g TAI_ON 1; echo "tai: watching"
          case off;   set -e TAI_ON;  echo "tai: quiet"
          case reset; tai reset $fish_pid
          case '*'
            if not isatty stdin
              tai pipe $fish_pid $argv          # <cmd> | ai <question>
            else if test (count $argv) -eq 0
              echo "usage: ai <text> | ai on|off|reset | <cmd> | ai <question>"
            else
              tai say $fish_pid $argv
            end
        end
      '';
    };

    # Event handlers must be defined at startup — autoloaded function files
    # never register their --on-event hooks.
    programs.fish.interactiveShellInit = ''
      function __tai_postexec --on-event fish_postexec
        set -l st $status
        set -q TAI_ON; or return
        string match -qr '^\s' -- $argv[1]; and return            # private
        string match -qr '^(ai|tai)\b' -- $argv[1]; and return     # not about itself
        test $st -eq 127; and return                               # handled by command-not-found
        test $st -eq 0 -a $CMD_DURATION -lt 10000; and return      # quiet on fast successes
        set -l out (wezterm cli get-text --start-line -40 2>/dev/null | string collect)
        tai event $fish_pid "$argv[1]" $st "$out"
      end

      bind \e\r __tai_line     # Alt+Enter
      bind \es  __tai_insert   # Alt+S
    '';
  };
}

{ pkgs, lib, config, ... }:

# ── tai-morning — poranny briefing z daily note ────────────────────────────────
# Przy pierwszym logowaniu danego dnia otwiera WezTerm z fishem, w którym tai
# czyta dzisiejszą notatkę z Obsidiana (YYYY-MM-DD.md), wita, podsumowuje
# zadania, proponuje kolejność i motywuje. Dokleja też niezrobione `- [ ]`
# z wczorajszej notatki.
#
# Sesja tai = $fish_pid tego terminala, więc po briefingu można od razu
# rozmawiać dalej:  ai a jak rozbić punkt 3?
#
#   tai-morning           uruchamia briefing (raz dziennie, stamp w ~/.cache)
#   tai-morning --force   ignoruje stamp (testy)
#
# Treść poleceń dla modelu żyje w sops (secrets/common.yaml):
#   tai-morning-brief    gdy jest dzisiejsza notatka
#   tai-morning-nonote   gdy jej brak
# Placeholder {now} jest podmieniany na aktualną datę i godzinę.
#
# Prefiks 4 = tylko desktop. Autostart dopisuje się sam do konfiguracji i3
# i sway (xdg.configFile.*.text to types.lines, więc definicje się sklejają),
# więc 6.i3.nix i 6.sway.nix nie wymagają zmian. Usunięcie tego pliku usuwa
# też autostart.
let
  user     = config.profile.username;
  vault    = "/home/${user}/data/Documents/notes";   # ← ścieżka do vaultu
  dailyDir = "${vault}/notes";                                     # ← folder z daily notes
  curl     = "${pkgs.curl}/bin/curl";
  fish     = "${config.programs.fish.package}/bin/fish";
  morning  = "${config.scripts.taiMorning}/bin/tai-morning";

  briefFile  = config.sops.secrets.tai-morning-brief.path;
  nonoteFile = config.sops.secrets.tai-morning-nonote.path;

  # Zbiera notatki i wysyła do tai w sesji podanej jako $1
  taiBrief = pkgs.writeShellScriptBin "tai-brief" ''
    session="''${1:?usage: tai-brief <session>}"
    today="${dailyDir}/$(date +%d.%m.%Y).md"
    yesterday="${dailyDir}/$(date -d yesterday +%d.%m.%Y).md"
    host="''${OLLAMA_HOST:-http://127.0.0.1:11434}"

    # Kontener Ollamy może jeszcze wstawać po boocie
    for _ in $(seq 30); do
      ${curl} -sf -m 2 "$host/api/tags" >/dev/null && break
      sleep 2
    done

    now=$(LC_TIME=pl_PL.UTF-8 date '+%A, %-d %B %Y, %H:%M')

    # Czyta szablon z sops i podstawia {now}; neutralny fallback, gdyby
    # sekret był nieczytelny (np. brak klucza maszyny)
    load() {   # $1 = plik z szablonem, $2 = fallback
      local tpl
      if [ -r "$1" ]; then tpl=$(cat "$1"); else tpl="$2"; fi
      printf '%s' "''${tpl//\{now\}/"$now"}"
    }

    if [ ! -f "$today" ]; then
      exec tai say "$session" "$(load ${nonoteFile} 'Jest {now}. Nie ma dzisiejszej notatki.')"
    fi

    {
      printf '# Notatka dnia (%s)\n' "$(date +%F)"
      cat "$today"
      if [ -f "$yesterday" ]; then
        left=$(grep -E '^[[:space:]]*- \[ \]' "$yesterday" || true)
        [ -n "$left" ] && printf '\n# Niezrobione z wczoraj\n%s\n' "$left"
      fi
    } | tai pipe "$session" "$(load ${briefFile} 'Jest {now}. Podsumuj tę notatkę dnia.')"
  '';

  # Wspólne dla i3 i sway — WezTerm działa przez XWayland (enable_wayland = false),
  # więc w obu sesjach okno dopasowuje się po class.
  windowRule = ''for_window [class="tai-morning"] floating enable, resize set 1000 750, move position center'';
in
{
  options.scripts.taiMorning = lib.mkOption {
    type        = lib.types.package;
    readOnly    = true;
    description = "Open a terminal with tai's morning briefing (once per day).";
  };

  config = {
    sops.secrets = {
      tai-morning-brief = {
        sopsFile = ../../secrets/common.yaml;
        owner    = user;
        mode     = "0400";
      };
      tai-morning-nonote = {
        sopsFile = ../../secrets/common.yaml;
        owner    = user;
        mode     = "0400";
      };
    };

    scripts.taiMorning = pkgs.writeShellScriptBin "tai-morning" ''
      stamp="''${XDG_CACHE_HOME:-$HOME/.cache}/tai-morning.stamp"
      today=$(date +%F)

      if [ "''${1:-}" != "--force" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$today" ]; then
        exit 0
      fi
      mkdir -p "$(dirname "$stamp")"
      echo "$today" > "$stamp"

      # fish -C: uruchom briefing, potem zostań w interaktywnej sesji.
      # TAI_MARKDOWN jest eksportowane na całą sesję, więc dalsze `ai …`
      # w tym oknie też renderują się przez glow.
      exec ${pkgs.wezterm}/bin/wezterm start --class tai-morning -- \
        ${fish} -C 'set -gx TAI_MARKDOWN 1; tai-brief $fish_pid'
    '';

    home-manager.users.${user} = {
      home.packages = [ taiBrief config.scripts.taiMorning ];

      # ── Autostart (exec, nie exec_always — reload WM go nie odpala) ─────────
      xdg.configFile."i3/config".text = lib.mkAfter ''

        # ── tai-morning (4.tai-morning.nix) ──────────────────────────────────
        exec --no-startup-id ${morning}
        ${windowRule}
      '';

      xdg.configFile."sway/config".text = lib.mkAfter ''

        # ── tai-morning (4.tai-morning.nix) ──────────────────────────────────
        exec ${morning}
        ${windowRule}
      '';
    };
  };
}
{ pkgs, ... }:

# ── Vivaldi ────────────────────────────────────────────────────────────────────
# Brave pulls GTK4 into the session which conflicts with Vivaldi's hardcoded
# GTK3 wrapper. Solution: shell wrapper that strips gtk+3 from LD_LIBRARY_PATH
# and XDG_DATA_DIRS before launching the real binary, then lets GTK4 be used.
let
  vivaldi-wrapped = pkgs.writeShellScriptBin "vivaldi" ''
    # Strip gtk+3 entries from LD_LIBRARY_PATH so GTK4 (from Brave/system) wins
    clean_ldpath=$(echo "''${LD_LIBRARY_PATH:-}" \
      | tr ':' '\n' \
      | grep -v 'gtk+3' \
      | tr '\n' ':' \
      | sed 's/:$//')

    # Strip gtk+3 from XDG_DATA_DIRS
    clean_xdg=$(echo "''${XDG_DATA_DIRS:-}" \
      | tr ':' '\n' \
      | grep -v 'gtk+3' \
      | tr '\n' ':' \
      | sed 's/:$//')

    export LD_LIBRARY_PATH="$clean_ldpath"
    export XDG_DATA_DIRS="$clean_xdg"

    exec ${pkgs.vivaldi}/bin/.vivaldi-wrapped \
      --ozone-platform=x11 \
      --gtk-version=4 \
      "$@"
  '';
in
{
  environment.systemPackages = [
    pkgs.vivaldi       # keep installed for its desktop entry and deps
    vivaldi-wrapped    # our wrapper overrides the vivaldi binary in PATH
  ];
}
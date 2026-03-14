{ pkgs, lib, ... }:

# ── Theming ────────────────────────────────────────────────────────────────────
# Declares options.theme.{palette, functions}.
# Any module that needs colors reads config.theme.palette.primary etc. directly.
# No specialArgs, no extraSpecialArgs — the module system handles propagation.
#
# To change the color scheme, edit the palette values below.
# All consumers (waybar, mango, fuzzel, bash, fish) update automatically on rebuild.
let
  runPastel = command:
    lib.strings.trim (builtins.readFile (pkgs.runCommand "pastel-run"
      { nativeBuildInputs = [ pkgs.pastel ]; }
      ''
        ${pkgs.pastel}/bin/pastel ${command} > $out
      ''));
in
{
  options.theme = {
    palette = lib.mkOption {
      type        = lib.types.attrsOf lib.types.str;
      description = "The central color palette. All values are #RRGGBB hex strings.";
    };

    functions = lib.mkOption {
      type        = lib.types.attrsOf lib.types.anything;
      readOnly    = true;
      description = "Color manipulation helpers. All take and return #RRGGBB strings unless noted.";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.pastel ];

    theme = {
      # ── Palette ─────────────────────────────────────────────────────────────
      palette = {
        # Desktop / UI colors
        primary    = "#b1b1b1";
        secondary  = "#1f1f1f";
        border     = "#1f1f1f";
        background = "#b1b1b1";
        text       = "#b1b1b1";

        # ── Terminal prompt colors ───────────────────────────────────────────
        # Used by both bash (PS1) and fish (fish_color_* + prompt function).
        termUser    = "#ff69b4";   # user and host name  (pink,   ANSI 206)
        termAccent  = "#6666cc";   # @ symbol and >      (purple, ANSI 63)

        # ── Fish syntax highlighting colors ──────────────────────────────────
        # These apply to fish only (no bash equivalent).
        shellCommand   = "#b1b1b1";   # valid commands
        shellError     = "#e06c75";   # errors / invalid commands
        shellParam     = "#abb2bf";   # parameters and arguments
        shellComment   = "#5c6370";   # comments
        shellAutosugg  = "#4b5263";   # autosuggestion ghost text
        shellKeyword   = "#c678dd";   # keywords (if, for, while…)
        shellString    = "#98c379";   # quoted strings
        shellOperator  = "#56b6c2";   # operators (|, &&, ;…)
      };

      # ── Functions ────────────────────────────────────────────────────────────
      functions = {
        # Format converters
        toMango  = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";
        toFuzzel = hex: hex + "ff";

        # Color operations (all use pastel at eval time)
        textcolor  = hex:         runPastel "textcolor '${hex}' | pastel format hex";
        complement = hex:         runPastel "complement '${hex}' | pastel format hex";
        lighten    = hex: amount: runPastel "lighten ${toString amount} '${hex}' | pastel format hex";
        darken     = hex: amount: runPastel "darken ${toString amount} '${hex}' | pastel format hex";
        saturate   = hex: amount: runPastel "saturate ${toString amount} '${hex}' | pastel format hex";

        # Convert #RRGGBB to the escape sequence bash PS1 needs: \033[38;2;R;G;Bm
        # Usage in PS1: "\[${toPs1 color}\]text\[\033[0m\]"
        toPs1 = hex:
          let
            r = lib.strings.toInt ("0x" + builtins.substring 1 2 hex);
            g = lib.strings.toInt ("0x" + builtins.substring 3 2 hex);
            b = lib.strings.toInt ("0x" + builtins.substring 5 2 hex);
          in "\\033[38;2;${toString r};${toString g};${toString b}m";
      };
    };
  };
}

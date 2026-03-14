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
        # Used by both bash (PS1) and fish (fish_prompt function).
        termUser   = "#ff69b4";   # user and host name  (pink,   ANSI 206)
        termAccent = "#6666cc";   # @ symbol and >      (purple, ANSI 63)

        # ── Fish syntax highlighting colors ──────────────────────────────────
        # These apply to fish only (no bash equivalent).
        shellCommand  = "#b1b1b1";
        shellError    = "#e06c75";
        shellParam    = "#abb2bf";
        shellComment  = "#5c6370";
        shellAutosugg = "#4b5263";
        shellKeyword  = "#c678dd";
        shellString   = "#98c379";
        shellOperator = "#56b6c2";
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
        # Uses pastel to extract R;G;B — avoids hex parsing in Nix eval.
        toPs1 = hex:
          let
            # pastel outputs e.g. "rgb(255, 105, 180)"
            rgb   = runPastel "format rgb '${hex}'";
            nums  = lib.strings.trim (builtins.replaceStrings
                      [ "rgb(" ")" " " ] [ "" "" "" ] rgb);
            parts = lib.strings.splitString "," nums;
            r     = lib.strings.trim (builtins.elemAt parts 0);
            g     = lib.strings.trim (builtins.elemAt parts 1);
            b     = lib.strings.trim (builtins.elemAt parts 2);
          in "\\033[38;2;${r};${g};${b}m";
      };
    };
  };
}

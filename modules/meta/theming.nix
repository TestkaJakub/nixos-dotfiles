{ pkgs, lib, ... }:

# ── Theming ────────────────────────────────────────────────────────────────────
# Declares options.theme.{palette, functions}.
# Any module that needs colors reads config.theme.palette.primary etc. directly.
# No specialArgs, no extraSpecialArgs — the module system handles propagation.
#
# To change the color scheme, edit the palette values below.
# All consumers (waybar, mango, fuzzel) update automatically on rebuild.
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
    # pastel is needed at eval time for color computation
    environment.systemPackages = [ pkgs.pastel ];

    theme = {
      # ── Palette ─────────────────────────────────────────────────────────────
      # Edit these values to retheme the entire system.
      palette = {
        primary    = "#b1b1b1";
        secondary  = "#1f1f1f";
        border     = "#1f1f1f";
        background = "#b1b1b1";
        text       = "#b1b1b1";
      };

      # ── Functions ────────────────────────────────────────────────────────────
      functions = {
        # Format converters
        toMango  = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";  # MangoWC: 0xRRGGBBff
        toFuzzel = hex: hex + "ff";                                         # Fuzzel:  #RRGGBBff

        # Color operations (all use pastel at eval time)
        textcolor  = hex:         runPastel "textcolor '${hex}' | pastel format hex";
        complement = hex:         runPastel "complement '${hex}' | pastel format hex";
        lighten    = hex: amount: runPastel "lighten ${toString amount} '${hex}' | pastel format hex";
        darken     = hex: amount: runPastel "darken ${toString amount} '${hex}' | pastel format hex";
        saturate   = hex: amount: runPastel "saturate ${toString amount} '${hex}' | pastel format hex";
      };
    };
  };
}

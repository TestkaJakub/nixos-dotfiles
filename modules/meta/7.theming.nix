{ pkgs, lib, ... }:

# ── Theming ────────────────────────────────────────────────────────────────────
# Declares options.theme.{palette, functions}.
# Any module that needs colors reads config.theme.palette.primary etc. directly.
# No specialArgs, no extraSpecialArgs — the module system handles propagation.
#
# To change the color scheme, edit the palette values below.
# All consumers (waybar, mango, fuzzel, bash, fish) update automatically on rebuild.
#
# Color computation: all pastel operations are batched into a single derivation
# (computedColors) that runs pastel once at eval time and outputs a JSON file.
# This is much faster than spawning one derivation per color operation.
let
  # ── Raw palette (before any computation) ────────────────────────────────────
  rawPalette = {
    primary    = "#b1b1b1";
    secondary  = "#1f1f1f";
    border     = "#1f1f1f";
    background = "#b1b1b1";
    text       = "#b1b1b1";
    termUser   = "#ff69b4";
    termAccent = "#6666cc";

    shellCommand  = "#b1b1b1";
    shellError    = "#e06c75";
    shellParam    = "#abb2bf";
    shellComment  = "#5c6370";
    shellAutosugg = "#4b5263";
    shellKeyword  = "#c678dd";
    shellString   = "#98c379";
    shellOperator = "#56b6c2";
  };

  # ── Single batched pastel derivation ────────────────────────────────────────
  # Runs every computation the rest of the config needs and writes them all
  # to a JSON file. The result is read once at eval time via builtins.fromJSON.
  computedColors = pkgs.runCommand "pastel-colors"
    { nativeBuildInputs = [ pkgs.pastel pkgs.jq ]; }
    ''
      pastel() { ${pkgs.pastel}/bin/pastel "$@"; }

      p="${rawPalette.primary}"
      s="${rawPalette.secondary}"

      textcolor_p=$(pastel textcolor "$p" | pastel format hex)
      textcolor_s=$(pastel textcolor "$s" | pastel format hex)
      complement_p=$(pastel complement "$p" | pastel format hex)
      lighten_p_01=$(pastel lighten 0.1 "$p" | pastel format hex)
      lighten_s_005=$(pastel lighten 0.05 "$s" | pastel format hex)
      darken_p_02=$(pastel darken 0.2 "$p" | pastel format hex)
      darken_s_005=$(pastel darken 0.05 "$s" | pastel format hex)

      # textcolor of derived colors
      textcolor_complement_p=$(pastel textcolor "$complement_p" | pastel format hex)
      textcolor_lighten_p_01=$(pastel textcolor "$lighten_p_01" | pastel format hex)

      # PS1 escape sequences for termUser and termAccent
      fmt_rgb() {
        pastel format rgb "$1" \
          | sed 's/rgb(\(.*\), \(.*\), \(.*\))/\\033[38;2;\1;\2;\3m/'
      }
      ps1_termUser=$(fmt_rgb "${rawPalette.termUser}")
      ps1_termAccent=$(fmt_rgb "${rawPalette.termAccent}")

      ${pkgs.jq}/bin/jq -n \
        --arg textcolor_p        "$textcolor_p"           \
        --arg textcolor_s        "$textcolor_s"           \
        --arg complement_p       "$complement_p"          \
        --arg lighten_p_01       "$lighten_p_01"          \
        --arg lighten_s_005      "$lighten_s_005"         \
        --arg darken_p_02        "$darken_p_02"           \
        --arg darken_s_005       "$darken_s_005"          \
        --arg tc_complement_p    "$textcolor_complement_p" \
        --arg tc_lighten_p_01    "$textcolor_lighten_p_01" \
        --arg ps1_termUser       "$ps1_termUser"          \
        --arg ps1_termAccent     "$ps1_termAccent"        \
        '{
          textcolor_primary:        $textcolor_p,
          textcolor_secondary:      $textcolor_s,
          complement_primary:       $complement_p,
          lighten_primary_0_1:      $lighten_p_01,
          lighten_secondary_0_05:   $lighten_s_005,
          darken_primary_0_2:       $darken_p_02,
          darken_secondary_0_05:    $darken_s_005,
          tc_complement_primary:    $tc_complement_p,
          tc_lighten_primary_0_1:   $tc_lighten_p_01,
          ps1_termUser:             $ps1_termUser,
          ps1_termAccent:           $ps1_termAccent
        }' > $out
    '';

  # Read results once
  c = builtins.fromJSON (builtins.readFile computedColors);

  # ── Convenience: call pastel for arbitrary one-off operations ────────────────
  # This is the escape hatch for any consumer that needs a color combination
  # not pre-computed above. Use sparingly — prefer adding to the batch above.
  runPastel = command:
    lib.strings.trim (builtins.readFile (pkgs.runCommand "pastel-oneoff"
      { nativeBuildInputs = [ pkgs.pastel ]; }
      ''${pkgs.pastel}/bin/pastel ${command} > $out''
    ));
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
      palette = rawPalette;

      # ── Functions ────────────────────────────────────────────────────────────
      # Format converters are pure Nix — zero cost.
      # Color operations return pre-computed values from the batch derivation
      # where possible, falling back to runPastel for uncommon combinations.
      functions = {
        # Format converters
        toMango  = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";
        toFuzzel = hex: hex + "ff";

        # Pre-computed color operations (fast — read from JSON, no new derivation)
        textcolor  = hex:
          if hex == rawPalette.primary   then c.textcolor_primary
          else if hex == rawPalette.secondary then c.textcolor_secondary
          else if hex == c.complement_primary then c.tc_complement_primary
          else if hex == c.lighten_primary_0_1 then c.tc_lighten_primary_0_1
          else runPastel "textcolor '${hex}' | pastel format hex";

        complement = hex:
          if hex == rawPalette.primary then c.complement_primary
          else runPastel "complement '${hex}' | pastel format hex";

        lighten = hex: amount:
          if hex == rawPalette.primary   && amount == 0.1  then c.lighten_primary_0_1
          else if hex == rawPalette.secondary && amount == 0.05 then c.lighten_secondary_0_05
          else runPastel "lighten ${toString amount} '${hex}' | pastel format hex";

        darken = hex: amount:
          if hex == rawPalette.primary   && amount == 0.2  then c.darken_primary_0_2
          else if hex == rawPalette.secondary && amount == 0.05 then c.darken_secondary_0_05
          else runPastel "darken ${toString amount} '${hex}' | pastel format hex";

        saturate = hex: amount:
          runPastel "saturate ${toString amount} '${hex}' | pastel format hex";

        # PS1 escape sequences — pre-computed, no derivation at call site
        toPs1 = hex:
          if hex == rawPalette.termUser   then c.ps1_termUser
          else if hex == rawPalette.termAccent then c.ps1_termAccent
          else
            let
              rgb   = runPastel "format rgb '${hex}'";
              nums  = lib.strings.trim (builtins.replaceStrings [ "rgb(" ")" " " ] [ "" "" "" ] rgb);
              parts = lib.strings.splitString "," nums;
              r     = lib.strings.trim (builtins.elemAt parts 0);
              g     = lib.strings.trim (builtins.elemAt parts 1);
              b     = lib.strings.trim (builtins.elemAt parts 2);
            in "\\033[38;2;${r};${g};${b}m";
      };
    };
  };
}

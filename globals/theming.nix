{ pkgs, lib, ... }:

let
  runPastel = command:
    lib.strings.trim (builtins.readFile (pkgs.runCommand "pastel-run" {
      nativeBuildInputs = [ pkgs.pastel ];
    } ''
      ${pkgs.pastel}/bin/pastel ${command} > $out
    ''));

  # Path to pywal's color JSON
  walFile = builtins.pathExists "/home/jakub/.cache/wal/colors.json"
    then "/home/jakub/.cache/wal/colors.json"
    else null;

  walColors = if walFile != null then
    builtins.fromJSON (builtins.readFile walFile)
  else
    {};
in
{
  options.theme = {
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Central color palette, possibly from wallpaper";
    };

    functions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.functionTo lib.types.str);
      readOnly = true;
      description = "Helper color manipulation functions";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.pastel pkgs.pywal ];

    theme = {
      palette = if walFile != null then {
        primary = walColors.colors.color1 or "#d1d1d1";
        secondary = walColors.colors.color0 or "#1f1f1f";
        border = walColors.colors.color8 or "#2f2f2f";
        background = walColors.special.background or "#f1f1f1";
        text = walColors.special.foreground or "#f1f1f1";
      } else {
        primary = "#d1d1d1";
        secondary = "#1f1f1f";
        border = "#1f1f1f";
        background = "#f1f1f1";
        text = "#f1f1f1";
      };

      functions = {
        toMango = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";
        toFuzzel = hex: hex + "ff";
        textcolor = hex: runPastel "textcolor '${hex}' | pastel format hex";
        complement = hex: runPastel "complement '${hex}' | pastel format hex";
        lighten = hex: amount: runPastel "lighten ${toString amount} '${hex}' | pastel format hex";
        darken = hex: amount: runPastel "darken ${toString amount} '${hex}' | pastel format hex";
        saturate = hex: amount: runPastel "saturate ${toString amount} '${hex}' | pastel format hex";
      };
    };
  };
}

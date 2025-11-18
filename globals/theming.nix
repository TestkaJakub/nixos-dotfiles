{ pkgs, lib, ... }:

let
  runPastel = command:
    lib.strings.trim (builtins.readFile (pkgs.runCommand "pastel-run"
      {
        nativeBuildInputs = [ pkgs.pastel ];
      }
      ''
        ${pkgs.pastel}/bin/pastel ${command} > $out
      ''));

in
{
  options.theme = {
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "The central color palette for the system.";
    };

    functions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.functionTo lib.types.str);
      readOnly = true;
      description = "Helper functions for color manipulation.";
    };
  };

  config = {
    environment.systemPackages = [ pkgs.pastel ];

    theme = {
      palette = {
        primary = "#ff5fd7";
        secondary = "#5f5fff";
        border = "#555555";
        background = "#2e3440";
	text = "#eceff4";
      };

      functions = {
        # Converts #RRGGBB -> 0xRRGGBBff for MangoWC
        toMango = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";
        # Converts #RRGGBB -> #RRGGBBAA for Fuzzel
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

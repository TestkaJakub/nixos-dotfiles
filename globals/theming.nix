# /home/jakub/nixos-dotfiles/globals/theming.nix
{ pkgs, lib, ... }:

let
  # Helper to run a pastel command at evaluation time and get the output.
  # This is a powerful Nix feature that lets us run code to generate our config.
  runPastel = command:
    lib.strings.trim (builtins.readFile (pkgs.runCommand "pastel-run"
      {
        # 'pastel' is a build-time dependency for this command
        nativeBuildInputs = [ pkgs.pastel ];
      }
      # The shell command to execute
      ''
        ${pkgs.pastel}/bin/pastel ${command} > $out
      ''));

in
{
  # Define a new option space called "theme"
  options.theme = {
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "The central color palette for the system.";
    };

    functions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.functionTo lib.types.str);
      readOnly = true; # These are defined by the module, not the user
      description = "Helper functions for color manipulation.";
    };
  };

  # Configure the options we just defined
  config = {
    # This makes pastel available system-wide, as you requested.
    environment.systemPackages = [ pkgs.pastel ];

    theme = {
      # --- YOUR COLOR PALETTE ---
      # This is the single source of truth for all your colors.
      palette = {
        # Core
        #primary = "#ff5fd7";
	primary = "#ff0000";
        secondary = "#5f5fff";
        border = "#555555";
        background = "#2e3440"; # Example background, change as needed
        text = "#eceff4";       # Example text, change as needed

        # Waybar
        waybarActive = "#ff78dd";
        waybarUrgent = "#ff92e4";
        waybarText = "#000000";
        waybarUrgentText = "#ffffff";

        # Fuzzel
        fuzzelBackground = "#5f5fff";
        fuzzelSelection = "#ff5fd7";
        fuzzelText = "#ffffff";
      };

      # --- COLOR CONVERSION FUNCTIONS ---
      functions = {
        # Converts #RRGGBB -> 0xRRGGBBff for MangoWC
        toMango = hex: "0x" + (lib.strings.removePrefix "#" hex) + "ff";
        # Converts #RRGGBB -> #RRGGBBAA for Fuzzel
        toFuzzel = hex: hex + "ff";
        # Example functions using pastel
        lighten = hex: amount: runPastel "lighten ${toString amount} '${hex}'";
        darken = hex: amount: runPastel "darken ${toString amount} '${hex}'";
        saturate = hex: amount: runPastel "saturate ${toString amount} '${hex}'";
      };
    };
  };
}

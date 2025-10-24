{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "kbm" ''
      path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
      max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
      cur=$(cat "$path" 2>/dev/null || echo 0)
      max=$(cat "$max_path" 2>/dev/null || echo 2)
      val=$(( (cur + 1) % (max + 1) ))
      echo "$val" > "$path"
    '')

    #inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
  ];

  environment.variables = {
    PF_INFO = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
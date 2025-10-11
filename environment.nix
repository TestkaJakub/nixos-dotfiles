{ pkgs, inputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      (pkgsi686Linux.gtk2)
  (pkgsi686Linux.pipewire)
  (pkgsi686Linux.pulseaudio)
  (pkgsi686Linux.libvdpau)
  (pkgsi686Linux.bzip2)
      (writeShellScriptBin "kbm" ''
        path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
        max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
        cur=$(cat "$path" 2>/dev/null || echo 0)
        max=$(cat "$max_path" 2>/dev/null || echo 2)
        val=$(( (cur + 1) % (max + 1) ))
        echo "$val" > "$path"
      '')

      inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
      vulkan-tools
      mangohud
    ];
    variables = {
      PF_INFO = "ascii title os host kernel uptime pkgs memory";
      PF_SOURCE = "";
    };

    sessionVariables.NIXOS_OZONE_WL = "1";
  };
}

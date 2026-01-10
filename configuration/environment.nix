{ pkgs, inputs, user, ... }:

{

  environment.systemPackages = with pkgs; [
    prismlauncher
    heroic
    krita
    xf86_input_wacom
    libinput
    discord
    wayvnc
    exfatprogs
    parted
    gvfs
    polkit
    xfce.thunar
    xfce.thunar-volman
    xfce.tumbler
    vscodium
    libreoffice-qt-fresh
    blender-hip
    (writeShellScriptBin "kbm" ''
      path="/sys/class/leds/tpacpi::kbd_backlight/brightness"
      max_path="/sys/class/leds/tpacpi::kbd_backlight/max_brightness"
      cur=$(cat "$path" 2>/dev/null || echo 0)
      max=$(cat "$max_path" 2>/dev/null || echo 2)
      val=$(( (cur + 1) % (max + 1) ))
      echo "$val" > "$path"
    '')

    (writeShellScriptBin "cpc" ''
      echo "Copying .nix configs to clipboard..."
      find ~/nixos-dotfiles -type f -name '*.nix' \
        -exec echo "===== {} =====" \; -exec cat {} \; | wl-copy
      notify-send "✅ Config copied to clipboard"
    '')

    #inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
  ];

  environment.variables = {
    PF_INFO = "ascii title os host kernel uptime pkgs memory";
    PF_SOURCE = "";
  };

  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true;
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

   hardware.opentabletdriver.enable = true;

  # Required by OpenTabletDriver
  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];
}

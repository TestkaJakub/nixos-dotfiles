{ config, pkgs, lib, version, timezone, ... }:

{
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "pl_PL.UTF-8/UTF-8" ];
  };

  console.keyMap = "pl2";

  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  fonts.packages = with pkgs; [ jetbrains-mono ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      amdvlk
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  time.timeZone = timezone;
  system.stateVersion = version;
}

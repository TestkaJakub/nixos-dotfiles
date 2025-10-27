{ config, pkgs, lib, version, timezone, ... }:

{
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "pl_PL.UTF-8/UTF-8" ];
  };
  console.keyMap = "pl2";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  hardware.graphics.enable = true;
  fonts.packages = with pkgs; [ jetbrains-mono ];

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

{ config, pkgs, lib, system, user, version, configurationModulesPath, wrapsPath, wrappers, ... }:

let
  confDir = configurationModulesPath;
  moduleFiles = [
    "hardware.nix"
    "system.nix"
    "networking.nix"
    "services.nix"
    "environment.nix"
  ];

  modules = map (file: confDir + ("/" + file)) moduleFiles;

  wrapsDir = wrapsPath;
  wrapsFiles = [
    "fuzzel.nix"
  ];

  wraps = map (file:
    import (wrapsDir + ("/" + file)) {
      inherit wrappers;
      pkgs = pkgs // { lndir = pkgs.xorg.lndir; }; # temporary shim for wrappers expecting pkgs.lndir
    }
  )
  wrapsFiles;

in
{
  imports = modules;
   environment.systemPackages = with pkgs; wraps ++ [

  ];
}

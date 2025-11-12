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

  wraps = map (file: import (wrapsDir + ("/" + file)) {inherit pkgs wrappers}) wrapsFiles;
in
{
  imports = modules;
   environment.systemPackages = with pkgs; wraps ++ [

  ];
}

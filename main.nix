{ config, pkgs, lib, system, user, version, configurationModulesPath, ... }:

let
  confDir = configurationModulesPath;
  moduleFiles = [
    "hardware.nix"
    "system.nix"
    "networking.nix"
    "services.nix"
    "environment.nix"
    #"gaming.nix"
  ];

  modules = map (file: confDir + ("/" + file)) moduleFiles;
in
{
  imports = modules;
}

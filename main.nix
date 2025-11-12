{ config, pkgs, lib, system, user, version, configurationModulesPath, wrapsPath, ... }:

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

  wraps = map (file: wrapsDir + ("/" + file)) wrapsFiles;
in
{
  imports = { modules, wraps };
}

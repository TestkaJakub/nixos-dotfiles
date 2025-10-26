{ config, pkgs, lib, system, user, version, ... }:

let
  confDir = ./configuration;
  moduleFiles = [
    "hardware.nix"
    "system.nix"
    "networking.nix"
    "services.nix"
    "environment.nix"
    "gaming.nix"
  ];

  modules = map (file: confDir + ("/" + file)) moduleFiles;
in
{
  imports = modules;
}

{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.piggy.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
{ config, pkgs, latitude, longitude, ... }:
{
  services.gammastep = {
    enable = true;
    inherit latitude longitude;
    temperature.day = 6000;
    temperature.night = 3700;
  };
}

{ config, pkgs, ... }:
{
  services.gammastep = {
    enable = true;
    latitude = 52.2;
    longitude = 21.0;
    temperature.day = 6000;
    temperature.night = 3700;
  };
}

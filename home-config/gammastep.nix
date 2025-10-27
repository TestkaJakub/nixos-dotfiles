{ config, pkgs, ... }:
{
  services.gammastep = {
    enable = true;
    latitude = 52.4;
    longitude = 17;
    temperature.day = 6000;
    temperature.night = 3700;
  };
}

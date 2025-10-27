{ config, pkgs, ... }:
{
  programs.gammastep = {
    enable = true;
    Unit = { Description = "Night light / blue light filter"; };
    Service = {
      ExecStart = "${pkgs.gammastep}/bin/gammastep -l 52.23:21.01 -t 6500:4000";
      Restart = "always";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}

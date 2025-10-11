{ config, pkgs, ... }:
{
  services.swww.enable = true;

  # Automatically set your wallpaper after swww starts
  systemd.user.services."swww-wallpaper" = {
    Unit = {
      Description = "Set initial wallpaper via swww";
      After = [ "graphical-session.target" "swww.service" ];
      Wants = [ "swww.service" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.swww}/bin/swww img /home/jakub/Wallpapers/makima.gif --transition-type grow --transition-step 90
      '';
      Type = "oneshot";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

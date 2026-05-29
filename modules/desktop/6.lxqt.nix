{ pkgs, ... }:
{
  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable    = true;

  environment.systemPackages = with pkgs; [
    lxqt.lxqt-archiver
    lxqt.lximage-qt
    lxqt.qps
    lxqt.screengrab
    lxqt.lxqt-powermanagement
    libsForQt5.qt5ct
    vlc
    xclip
    hardinfo2
    kdiff3
  ];
}
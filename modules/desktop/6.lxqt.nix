{ pkgs, lib, ... }:
{
  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable    = true;

  # Ensure Plasma/KDE is fully absent
  services.xserver.desktopManager.plasma6.enable = lib.mkForce false;
  services.displayManager.sddm.enable            = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    lxqt.lxqt-archiver
    lxqt.lxqt-calendar
    lxqt.lximage-qt
    lxqt.qps
    lxqt.screengrab
    lxqt.lxqt-bluetooth
    lxqt.lxqt-powermanagement
    libsForQt5.qt5ct
    vlc
    xclip
    hardinfo2
    kdiff3
  ];
}
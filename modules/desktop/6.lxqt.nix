{ pkgs, lib, ... }:
{
  services.xserver.enable = true;

  services.displayManager.lightdm.enable = true;
  services.desktopManager.lxqt.enable   = true;

  # Ensure Plasma/KDE is fully absent
  services.desktopManager.plasma6.enable = lib.mkForce false;
  services.displayManager.sddm.enable    = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    lxqt.lxqt-archiver     # archive manager
    lxqt.lxqt-calendar     # calendar widget
    lxqt.lximage-qt        # image viewer
    lxqt.qps               # process manager (replaces ksystemlog/hardinfo2)
    lxqt.screengrab         # screenshot tool (replaces kdePackages.spectacle)
    lxqt.lxqt-bluetooth    # bluetooth GUI (if hasBluetooth)
    lxqt.lxqt-powermanagement
    libsForQt5.qt5ct       # Qt5 theme configurator
    vlc
    xclip
    hardinfo2
    kdiff3
  ];
}
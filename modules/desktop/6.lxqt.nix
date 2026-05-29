{ pkgs, config, ... }:

# ── LXQt desktop ───────────────────────────────────────────────────────────────
# Window manager: Openbox (default for LXQt)
# Display manager: LightDM
#
# LXQt config files are managed here as a starting point.
# Note: LXQt rewrites its own config when you use the GUI settings panels,
# so these are initial defaults only — after first boot feel free to
# configure via GUI and the files will diverge from what's here.
#
# To capture your current GUI config back into Nix:
#   cat ~/.config/lxqt/session.conf   (etc.) and paste below
let
  user = config.profile.username;
in
{
  services.xserver.enable                        = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable    = true;

  environment.systemPackages = with pkgs; [
    lxqt.lxqt-archiver
    lxqt.lximage-qt
    lxqt.qps
    lxqt.screengrab
    lxqt.lxqt-powermanagement
    libsForQt5.qt5ct
    papirus-icon-theme   # good default icon theme for LXQt
    vlc
    xclip
    hardinfo2
    kdiff3
  ];

  # ── LXQt config files ───────────────────────────────────────────────────────
  # Written to /etc/skel so they land in home on first login.
  # If the user already exists, copy manually once:
  #   cp /etc/skel/.config/lxqt/* ~/.config/lxqt/
  environment.etc = {

    # ── Session ────────────────────────────────────────────────────────────────
    "skel/.config/lxqt/session.conf".text = ''
      [General]
      iconTheme=Papirus-Dark
      lockScreenBeforeSuspend=false
      terminal=wezterm

      [Environment]
      QT_QPA_PLATFORMTHEME=lxqt
    '';

    # ── LXQt appearance ────────────────────────────────────────────────────────
    "skel/.config/lxqt/lxqt.conf".text = ''
      [General]
      theme=dark
      single_click_activate=false
    '';

    # ── Panel ──────────────────────────────────────────────────────────────────
    "skel/.config/lxqt/panel.conf".text = ''
      [panel1]
      alignment=-1
      animation-duration=0
      background-color=#1f1f1f
      background-image=
      custom-background-color=true
      custom-font-color=false
      font-color=#b1b1b1
      hidable=false
      height=32
      iconSize=22
      opacity=100
      panelSize=32
      plugins=mainmenu, taskbar, spacer, statusnotifier, volume, clock, showdesktop
      position=Bottom
      rows=1
      show-border=false
      visible=true
    '';

    # ── Openbox keybindings ────────────────────────────────────────────────────
    # Super+T  → terminal
    # Super+B  → browser
    # Super+E  → file manager
    # Super+L  → lock screen
    # Print    → screenshot region
    "skel/.config/openbox/lxqt-rc.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <openbox_config xmlns="http://openbox.org/3.4/rc"
                      xmlns:xi="http://www.w3.org/2001/XInclude">
        <resistance>
          <strength>10</strength>
          <screen_edge_strength>20</screen_edge_strength>
        </resistance>
        <focus>
          <focusNew>yes</focusNew>
          <followMouse>no</followMouse>
          <focusLast>yes</focusLast>
          <underMouse>no</underMouse>
          <focusDelay>200</focusDelay>
          <raiseOnFocus>no</raiseOnFocus>
        </focus>
        <theme>
          <name>Clearlooks</name>
          <titleLayout>NLIMC</titleLayout>
          <keepBorder>yes</keepBorder>
          <animateIconify>yes</animateIconify>
        </theme>
        <desktops>
          <number>2</number>
          <firstdesk>1</firstdesk>
          <names>
            <name>1</name>
            <name>2</name>
          </names>
          <popupTime>875</popupTime>
        </desktops>
        <keyboard>
          <chainQuitKey>C-g</chainQuitKey>

          <keybind key="W-t">
            <action name="Execute">
              <command>wezterm</command>
            </action>
          </keybind>

          <keybind key="W-b">
            <action name="Execute">
              <command>vivaldi</command>
            </action>
          </keybind>

          <keybind key="W-e">
            <action name="Execute">
              <command>nemo</command>
            </action>
          </keybind>

          <keybind key="W-l">
            <action name="Execute">
              <command>lxqt-leave --lockscreen</command>
            </action>
          </keybind>

          <keybind key="Print">
            <action name="Execute">
              <command>screenshot-region</command>
            </action>
          </keybind>

          <keybind key="W-Print">
            <action name="Execute">
              <command>screenshot-full</command>
            </action>
          </keybind>

          <!-- Virtual desktops -->
          <keybind key="W-1">
            <action name="GoToDesktop"><to>1</to></action>
          </keybind>
          <keybind key="W-2">
            <action name="GoToDesktop"><to>2</to></action>
          </keybind>
          <keybind key="W-S-1">
            <action name="SendToDesktop"><to>1</to></action>
          </keybind>
          <keybind key="W-S-2">
            <action name="SendToDesktop"><to>2</to></action>
          </keybind>
        </keyboard>

        <mouse>
          <dragThreshold>8</dragThreshold>
          <doubleClickTime>200</doubleClickTime>
          <screenEdgeWarpTime>400</screenEdgeWarpTime>
          <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
        </mouse>
      </openbox_config>
    '';
  };
}
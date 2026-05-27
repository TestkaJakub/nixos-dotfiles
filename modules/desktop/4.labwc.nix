{ pkgs, config, inputs, ... }:

# ── Labwc — stacking Wayland compositor ────────────────────────────────────────
# Labwc is an openbox-inspired stacking WM for Wayland.
# It shares the same autostart stack as Hyprland:
#   hyprpaper, mako, waybar, gammastep, cliphist, startupBrowser.
#
# Select at the SDDM login screen — both sessions appear in the session list.
#
# Keybinds mirror Hyprland where possible. Labwc uses rc.xml (XML config)
# and environment.d for session variables.
#
# Notable differences from Hyprland:
#   - No tiling; windows stack/float (openbox-style)
#   - Mouse focus follows pointer by default (overridden here to click-to-focus)
#   - Workspaces via virtual-desktops (labwc >= 0.8)
#   - No built-in screenshot keybind — uses the same screenshot-region/full scripts

let
  meta = config.meta.defaults;
  loc  = config.locale;
  user = config.profile.username;

  hyprlock  = "${pkgs.hyprlock}/bin/hyprlock";
  cliphist  = "${pkgs.cliphist}/bin/cliphist";
  wlCopy    = "${pkgs.wl-clipboard}/bin/wl-copy";
  pamixer   = "${pkgs.pamixer}/bin/pamixer";
  hyprpaper = "${pkgs.hyprpaper}/bin/hyprpaper";
  mako      = "${pkgs.mako}/bin/mako";
  waybar    = "${pkgs.waybar}/bin/waybar";
  gammastep = "${pkgs.gammastep}/bin/gammastep";
  wlPaste   = "${pkgs.wl-clipboard}/bin/wl-paste";

  browser     = "${meta.browserPackage}/bin/${meta.browser}";
  terminal    = "${meta.terminalPackage}/bin/${meta.terminal}";
  fileManager = "${meta.fileManagerPackage}/bin/${meta.fileManager}";
  fuzzel      = "${meta.fuzzel}/bin/fuzzel";

  # labwc autostart script — same daemons as hyprland, different syntax
  autostartScript = pkgs.writeShellScript "labwc-autostart" ''
    ${hyprpaper} --config ~/.config/hypr/hyprpaper.conf &
    ${mako} &
    ${waybar} &
    ${gammastep} -m wayland -l ${toString loc.latitude}:${toString loc.longitude} -t 6000:3700 &
    ${wlPaste} --type text  --watch ${cliphist} store &
    ${wlPaste} --type image --watch ${cliphist} store &
    ${config.scripts.startupBrowser}/bin/startup-browser &
  '';
in
{
  # ── labwc package ──────────────────────────────────────────────────────────
  # in 6.labwc.nix, replace the writeTextDir approach with:
  services.displayManager.sessionPackages = [
    (pkgs.runCommand "labwc-session" {
      passthru.providedSessions = [ "labwc" ];
    } ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/labwc.desktop << 'EOF'
      [Desktop Entry]
      Name=Labwc
      Comment=Stacking Wayland compositor
      Exec=env -u WAYLAND_DISPLAY -u DISPLAY ${pkgs.labwc}/bin/labwc
      Type=Application
      DesktopNames=Labwc
      EOF
    '')
  ];

  home-manager.users.${user} = {

    # ── rc.xml — main labwc config ─────────────────────────────────────────
    xdg.configFile."labwc/rc.xml".text = ''
      <?xml version="1.0"?>
      <openbox_config xmlns="http://openbox.org/3.4/rc">

        <!-- ── Core behaviour ──────────────────────────────────────────── -->
        <core>
          <decoration>server</decoration>
          <gap>
            <top>8</top>
            <bottom>8</bottom>
            <left>8</left>
            <right>8</right>
          </gap>
          <adaptiveSync>yes</adaptiveSync>
          <reuseOutputMode>yes</reuseOutputMode>
        </core>

        <!-- ── Focus ────────────────────────────────────────────────────── -->
        <focus>
          <followMouse>no</followMouse>
          <raiseOnFocus>no</raiseOnFocus>
        </focus>

        <!-- ── Virtual desktops (workspaces 1–9) ────────────────────────── -->
        <desktops>
          <number>9</number>
          <names>
            <name>1</name>
            <name>2</name>
            <name>3</name>
            <name>4</name>
            <name>5</name>
            <name>6</name>
            <name>7</name>
            <name>8</name>
            <name>9</name>
          </names>
          <popupTime>0</popupTime>
        </desktops>

        <!-- ── Keyboard ─────────────────────────────────────────────────── -->
        <keyboard>
          <default/>

          <!-- spawn -->
          <keybind key="W-q"><action name="Execute"><command>${terminal}</command></action></keybind>
          <keybind key="W-b"><action name="Execute"><command>${browser}</command></action></keybind>
          <keybind key="W-n"><action name="Execute"><command>${fileManager}</command></action></keybind>
          <keybind key="W-f"><action name="Execute"><command>${fuzzel}</command></action></keybind>
          <keybind key="W-Print"><action name="Execute"><command>screenshot-region</command></action></keybind>
          <keybind key="W-C-l"><action name="Execute"><command>${hyprlock}</command></action></keybind>
          <keybind key="W-C-d"><action name="Execute"><command>${config.scripts.dpt}/bin/dpt</command></action></keybind>
          <keybind key="W-C-t"><action name="Execute"><command>trayscale</command></action></keybind>
          <keybind key="W-S-v"><action name="Execute">
            <command>bash -c '${cliphist} list | ${fuzzel} --dmenu | ${cliphist} decode | ${wlCopy}'</command>
          </action></keybind>
          <keybind key="W-g"><action name="Execute"><command>${config.scripts.kbm}/bin/kbm</command></action></keybind>
          <keybind key="W-m"><action name="Execute"><command>${config.scripts.cpc}/bin/cpc</command></action></keybind>
          <keybind key="A-m"><action name="Execute"><command>${config.scripts.cpcs}/bin/cpcs</command></action></keybind>

          <!-- window management -->
          <keybind key="W-e"><action name="Close"/></keybind>
          <keybind key="W-x"><action name="ToggleMaximize"/></keybind>
          <keybind key="W-v"><action name="ToggleFullscreen"/></keybind>
          <keybind key="W-c"><action name="ToggleAlwaysOnTop"/></keybind>

          <!-- focus -->
          <keybind key="W-Tab"><action name="NextWindow"/></keybind>

          <!-- move windows with keyboard -->
          <keybind key="W-k"><action name="MoveRelative"><x>0</x><y>-40</y></action></keybind>
          <keybind key="W-j"><action name="MoveRelative"><x>0</x><y>40</y></action></keybind>
          <keybind key="W-h"><action name="MoveRelative"><x>-40</x><y>0</y></action></keybind>
          <keybind key="W-l"><action name="MoveRelative"><x>40</x><y>0</y></action></keybind>

          <!-- snap windows to screen halves -->
          <keybind key="W-a"><action name="SnapToEdge"><direction>left</direction></action></keybind>
          <keybind key="W-d"><action name="SnapToEdge"><direction>right</direction></action></keybind>
          <keybind key="W-w"><action name="SnapToEdge"><direction>up</direction></action></keybind>
          <keybind key="W-s"><action name="SnapToEdge"><direction>down</direction></action></keybind>

          <!-- workspaces -->
          <keybind key="W-1"><action name="GoToDesktop"><to>1</to></action></keybind>
          <keybind key="W-2"><action name="GoToDesktop"><to>2</to></action></keybind>
          <keybind key="W-3"><action name="GoToDesktop"><to>3</to></action></keybind>
          <keybind key="W-4"><action name="GoToDesktop"><to>4</to></action></keybind>
          <keybind key="W-5"><action name="GoToDesktop"><to>5</to></action></keybind>
          <keybind key="W-6"><action name="GoToDesktop"><to>6</to></action></keybind>
          <keybind key="W-7"><action name="GoToDesktop"><to>7</to></action></keybind>
          <keybind key="W-8"><action name="GoToDesktop"><to>8</to></action></keybind>
          <keybind key="W-9"><action name="GoToDesktop"><to>9</to></action></keybind>

          <!-- audio -->
          <keybind key="XF86AudioMute">
            <action name="Execute"><command>${pamixer} -t</command></action>
          </keybind>
          <keybind key="XF86AudioLowerVolume">
            <action name="Execute"><command>${pamixer} --allow-boost -d 5</command></action>
          </keybind>
          <keybind key="XF86AudioRaiseVolume">
            <action name="Execute"><command>${pamixer} --allow-boost -i 5</command></action>
          </keybind>
        </keyboard>

        <!-- ── Mouse ─────────────────────────────────────────────────────── -->
        <mouse>
          <default/>
          <!-- super+drag to move/resize without titlebar -->
          <context name="Root">
            <mousebind button="Left" action="Press">
              <action name="Focus"/>
            </mousebind>
          </context>
          <context name="Frame">
            <mousebind button="W-Left" action="Drag">
              <action name="Move"/>
            </mousebind>
            <mousebind button="W-Right" action="Drag">
              <action name="Resize"/>
            </mousebind>
          </context>
        </mouse>

      </openbox_config>
    '';

    # ── autostart ─────────────────────────────────────────────────────────
    xdg.configFile."labwc/autostart".source = autostartScript;

    # ── environment.d — session variables ─────────────────────────────────
    # labwc sources ~/.config/labwc/environment on startup.
    # Mirror the Wayland vars from system/display.nix.
    xdg.configFile."labwc/environment".text = ''
      NIXOS_OZONE_WL=1
      MOZ_ENABLE_WAYLAND=1
      OZONE_PLATFORM=wayland
      XCURSOR_THEME=Bibata-Modern-Classic
      XCURSOR_SIZE=24
      XKB_DEFAULT_LAYOUT=${loc.keyboardLayout}
    '';

    # ── outputs — monitor resolution ──────────────────────────────────────
    xdg.configFile."labwc/outputs.xml".text = ''
      <?xml version="1.0"?>
      <labwc_outputs>
        <output>
          <name>HDMI-A-1</name>
          <mode>
            <width>1920</width>
            <height>1080</height>
            <rate>60</rate>
          </mode>
          <scale>1.0</scale>
        </output>
      </labwc_outputs>
    '';
  };
}

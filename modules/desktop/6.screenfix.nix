# modules/desktop/6.screenfx.nix
{ pkgs, config, ... }:

# ── Brightness slider + grayscale toggle ───────────────────────────────────────
# Launcher entries:
#   "Brightness"  zenity slider (laptop backlight or monitor via DDC/CI)
#   "Grayscale"   toggles grayscale on each launch (i3 only, picom shader)
let
  user = config.profile.username;

  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  ddcutil       = "${pkgs.ddcutil}/bin/ddcutil";

  shader = pkgs.writeText "grayscale.glsl" ''
    #version 330
    in vec2 texcoord;
    uniform sampler2D tex;
    vec4 default_post_processing(vec4 c);
    vec4 window_shader() {
      vec4 c = texelFetch(tex, ivec2(texcoord), 0);
      float y = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
      return default_post_processing(vec4(vec3(y), c.a));
    }
  '';

  brightnessGui = pkgs.writeShellScriptBin "brightness-gui" ''
    if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
      cur=$(( $(${brightnessctl} get) * 100 / $(${brightnessctl} max) ))
      set_b() { ${brightnessctl} -q set "$1%"; }
    else
      cur=$(${ddcutil} getvcp 10 --terse | cut -d' ' -f4)
      set_b() { ${ddcutil} --noverify setvcp 10 "$1"; }
    fi
    ${pkgs.zenity}/bin/zenity --scale --title=Brightness --text=Brightness \
      --value="''${cur:-50}" --print-partial \
      | while read -r v; do set_b "$v"; done
  '';

  grayscaleToggle = pkgs.writeShellScriptBin "grayscale-toggle" ''
    flag="$XDG_RUNTIME_DIR/grayscale"
    ${pkgs.procps}/bin/pkill -x picom
    while ${pkgs.procps}/bin/pgrep -x picom >/dev/null; do sleep 0.05; done
    if [ -f "$flag" ]; then
      rm "$flag"
      ${pkgs.picom}/bin/picom --daemon
    else
      touch "$flag"
      ${pkgs.picom}/bin/picom --daemon --backend glx --window-shader-fg ${shader}
    fi
  '';
in
{
  hardware.i2c.enable = true;                      # DDC/CI for the desktop monitor
  users.users.${user}.extraGroups = [ "i2c" ];
  services.udev.packages = [ pkgs.brightnessctl ]; # laptop backlight via video group

  home-manager.users.${user} = {
    home.packages = [ brightnessGui grayscaleToggle ];

    xdg.desktopEntries = {
      brightness = { name = "Brightness"; exec = "brightness-gui";   icon = "display-brightness"; };
      grayscale  = { name = "Grayscale";  exec = "grayscale-toggle"; icon = "video-display"; };
    };
  };
}
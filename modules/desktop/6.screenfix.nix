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
      vec2 texsize = textureSize(tex, 0);
      vec4 c = texture2D(tex, texcoord / texsize, 0);
      float y = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
      return default_post_processing(vec4(vec3(y), c.a));
    }
  '';

  brightnessGui = pkgs.writeShellScriptBin "brightness-gui" ''
    awk=${pkgs.gawk}/bin/awk
    xrandr=${pkgs.xorg.xrandr}/bin/xrandr

    if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
      # Laptop panel
      cur=$(( $(${brightnessctl} get) * 100 / $(${brightnessctl} max) ))
      set_b() { ${brightnessctl} -q set "$1%"; }
    elif cur=$(${ddcutil} getvcp 10 --terse 2>/dev/null | cut -d' ' -f4) && [ -n "$cur" ]; then
      # Monitor over DDC/CI
      set_b() { ${ddcutil} --noverify setvcp 10 "$1"; }
    else
      # Software dimming on all outputs (X11)
      outputs=$($xrandr --query | $awk '/ connected/ {print $1}')
      cur=$($xrandr --verbose | $awk '/Brightness:/ {printf "%d", $2 * 100; exit}')
      set_b() {
        b=$($awk -v v="$1" 'BEGIN { if (v < 10) v = 10; printf "%.2f", v / 100 }')
        for o in $outputs; do $xrandr --output "$o" --brightness "$b"; done
      }
    fi

    ${pkgs.zenity}/bin/zenity --scale --title=Brightness --text=Brightness \
      --value="''${cur:-100}" --print-partial \
      | while read -r v; do set_b "$v"; done
  '';
  
  grayscaleToggle = pkgs.writeShellScriptBin "grayscale-toggle" ''
    flag="$XDG_RUNTIME_DIR/grayscale"
    graywall="$XDG_RUNTIME_DIR/grayscale-wall.jpg"
    picom="${pkgs.picom}/bin/picom"
    feh="${pkgs.feh}/bin/feh"

    restart() {
      ${pkgs.procps}/bin/pkill -x picom
      while ${pkgs.procps}/bin/pgrep -x picom >/dev/null; do sleep 0.05; done
      "$picom" --daemon "$@"
    }

    wall_gray() {
      wall=$(grep -o "'[^']*'" "$HOME/.fehbg" 2>/dev/null | tail -1 | tr -d "'")
      mode=$(grep -o -- '--bg-[a-z]*' "$HOME/.fehbg" 2>/dev/null | head -1)
      [ -f "$wall" ] || return
      ${pkgs.imagemagick}/bin/magick "$wall" -colorspace Gray "$graywall" \
        && "$feh" --no-fehbg "''${mode:---bg-fill}" "$graywall"
    }

    wall_restore() {
      [ -f "$HOME/.fehbg" ] && sh "$HOME/.fehbg"
      rm -f "$graywall"
    }

    turn_off() {
      rm -f "$flag"
      restart
      wall_restore
    }

    if [ -f "$flag" ]; then
      turn_off
      exit 0
    fi

    touch "$flag"
    restart --backend egl --window-shader-fg ${shader}
    wall_gray

    # Safety net: revert unless confirmed within 10 s
    if ! ${pkgs.zenity}/bin/zenity --question --title=Grayscale \
         --text="Keep grayscale?" --timeout=10; then
      turn_off
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
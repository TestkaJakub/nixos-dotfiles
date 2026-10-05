{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "godot4";
      paths = [ pkgs.godot_4 ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/godot4 \
          --set WAYLAND_DISPLAY "" \
          --set GDK_BACKEND x11
      '';
    })
  ];
}

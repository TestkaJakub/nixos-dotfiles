{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine     = true;
      commandLineArgs = [
        "--ozone-platform=x11"
        "--gtk-version=4"
      ];
      # Force Vivaldi to use system GTK instead of its bundled one
      vivaldi = pkgs.vivaldi.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/vivaldi \
            --unset LD_LIBRARY_PATH
        '';
      });
    })
  ];
}
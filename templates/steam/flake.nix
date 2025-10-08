{
  description = "Template: Steam + Gaming environment";

  inputs = {
    # You can pin this to a specific channel for stability
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # Template declaration – so it’s importable as #steam
      templates.default = {
        path = ./.;
        description = "Standalone Steam + Gaming environment template";
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          steam
          vulkan-tools
          libGL
          mangohud
          lutris
        ];

	shellHook = ''
          export TMPDIR=/tmp
          export FONTCONFIG_PATH=/etc/fonts
          export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver/lib64:${pkgs.lib.makeLibraryPath [ pkgs.vulkan-loader pkgs.glibc ]}"
          export PS1="(steam-env) $PS1"
          echo "🎮 Steam gaming shell ready (Wayland session: $XDG_SESSION_TYPE)"
          echo "Run Steam (native Wayland): steam --enable-features=UseOzonePlatform --ozone-platform=wayland"
        '';
      };
    };
}

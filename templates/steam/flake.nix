{
  description = "Template: Steam + Gaming environment";

  inputs = {
    # You can pin this to a specific channel for stability
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
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
          echo "🎮 Welcome to the Nix gaming shell!"
          echo "Steam path: $(which steam)"
          echo "To play: steam"
        '';
      };
    };
}

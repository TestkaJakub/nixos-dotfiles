{
  description = "Template: Node.js development environment";

  outputs = { self, nixpkgs }: {
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
    templates.default = {
      path = ./.;
      description = "Reusable Node.js development environment template";
    };
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs_24
	yarn
	nodePackages.typescript
      ];
      shellHook = ''
        echo "Welcome to your Node.js dev environment!"
	echo "Node version $(node -v)"
	echo "Yarn version $(yarn -v)"
      '';
    };
  };
}

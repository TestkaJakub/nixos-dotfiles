let
  dotfilesPath = ../.;
in {
  inherit dotfilesPath;
  homePath = dotfilesPath + "/home.nix";
  configurationPath = dotfilesPath + "/main.nix";
  configurationModulesPath = dotfiles + "/configuration";
}


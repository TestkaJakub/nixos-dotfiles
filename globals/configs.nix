let
  dotfilesPath = ../.;
in {
  inherit dotfilesPath;
  homePath = dotfilesPath + "/home.nix";
  homeConfigurationPath = dotfilesPath + "/home-config";
  configurationPath = dotfilesPath + "/main.nix";
  configurationModulesPath = dotfilesPath + "/configuration";
}


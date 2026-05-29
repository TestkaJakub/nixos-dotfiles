{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.vivaldi.override {
      commandLineArgs = [
        "--ozone-platform=x11"
        "--gtk-version=4"
      ];
    })
  ];
  environment.sessionVariables = {
    GTK_USE_PORTAL = "0";
  };
}
{ pkgs, config, inputs, ... }:

# ── Terminal (Alacritty) ───────────────────────────────────────────────────────
# The alacritty wrapper from lassulus/wrappers is applied inline here.
# wraps/alacritty.nix is no longer needed as a separate file.
let
  user = config.profile.username;

  alacrittyPkg = (inputs.wrappers.wrapperModules.alacritty.apply {
    pkgs = pkgs // { lndir = pkgs.xorg.lndir; };
    settings = {
      window = {
        opacity = 0.9;
        padding = { x = 10; y = 10; };
      };
      font.normal = {
        family = "JetBrains Mono";
        style  = "Regular";
      };
    };
  }).wrapper;
in
{
  home-manager.users.${user}.home.packages = [ alacrittyPkg ];
}

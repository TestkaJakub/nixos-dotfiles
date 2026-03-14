{ pkgs, config, inputs, ... }:

# ── Terminal (Alacritty) ───────────────────────────────────────────────────────
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
      terminal.shell = {
        program = "${pkgs.fish}/bin/fish";
        args    = [ "--init-command" "fastfetch" ];
      };
    };
  }).wrapper;
in
{
  home-manager.users.${user}.home.packages = [ alacrittyPkg ];
}

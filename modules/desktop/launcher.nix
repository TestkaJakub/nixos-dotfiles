{ pkgs, lib, config, inputs, ... }:

# ── Launcher (Fuzzel) ──────────────────────────────────────────────────────────
# Reads: config.theme.{palette, functions}
# The fuzzel wrapper from lassulus/wrappers is applied inline here.
# wraps/fuzzel.nix is no longer needed as a separate file.
let
  t    = config.theme;
  user = config.profile.username;

  fuzzelPkg = (inputs.wrappers.wrapperModules.fuzzel.apply {
    inherit pkgs;
    settings.colors = {
      background     = t.functions.toFuzzel t.palette.secondary;
      selection      = t.functions.toFuzzel t.palette.primary;
      text           = t.functions.toFuzzel (t.functions.darken t.palette.text 0.1);
      selection-text = t.functions.toFuzzel (t.functions.textcolor t.palette.primary);
      prompt         = t.functions.toFuzzel t.palette.text;
      input          = t.functions.toFuzzel t.palette.text;
    };
  }).wrapper;
in
{
  home-manager.users.${user}.home.packages = [ fuzzelPkg ];
}

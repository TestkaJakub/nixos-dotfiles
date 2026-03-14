{ pkgs, lib, config, inputs, ... }:

# ── Launcher (Fuzzel) ──────────────────────────────────────────────────────────
# Reads: config.theme.{palette, functions}
# The fuzzel wrapper from lassulus/wrappers is applied inline here.
# The wrapped package is exposed as config.meta.defaults.fuzzel so that
# compositor.nix and any other caller use the themed binary consistently.
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
  # Expose the store path so compositor.nix can reference it without
  # duplicating the wrapper logic or relying on ambient PATH.
  options.meta.defaults.fuzzel = lib.mkOption {
    type        = lib.types.package;
    readOnly    = true;
    description = "Themed fuzzel wrapper package.";
  };

  config = {
    meta.defaults.fuzzel = fuzzelPkg;

    home-manager.users.${user}.home.packages = [ fuzzelPkg ];
  };
}

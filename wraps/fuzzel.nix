{ wrappers, pkgs, theme, ...}:
(wrappers.wrapperModules.fuzzel.apply
{
  inherit pkgs;
  settings = {
    colors = {
      background = theme.functions.toFuzzel theme.palette.fuzzelBackground;
      selection = theme.functions.toFuzzel theme.palette.fuzzelSelection;
      text = theme.functions.toFuzzel theme.palette.fuzzelText;
      selection-text = theme.functions.toFuzzel theme.palette.fuzzelText;
      prompt = theme.functions.toFuzzel theme.palette.fuzzelText;
      input = theme.functions.toFuzzel theme.palette.fuzzelText;
      #background = "#5f5fffff";
      #selection = "#ff5fd7ff";
      #text = "#ffffffff";
      #selection-text = "#ffffffff";
      #prompt = "#ffffffff";
      #input = "#ffffffff";
    };
  };
}
).wrapper



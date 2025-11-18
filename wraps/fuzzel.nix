{ wrappers, pkgs, theme, ...}:
(wrappers.wrapperModules.fuzzel.apply
{
  inherit pkgs;
  settings = {
    colors = {
      background = theme.functions.toFuzzel theme.palette.secondary;
      selection = theme.functions.toFuzzel theme.palette.primary;
      #text = theme.functions.toFuzzel (theme.functions.darken theme.palette.text 0.1);
      text = "#ffffffff";
      selection-text = theme.functions.toFuzzel theme.palette.text;
      prompt = theme.functions.toFuzzel theme.palette.text;
      input = theme.functions.toFuzzel theme.palette.text;
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



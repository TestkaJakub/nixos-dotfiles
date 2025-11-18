{ wrappers, pkgs, theme, ...}:
(wrappers.wrapperModules.fuzzel.apply
{
  inherit pkgs;
  settings = {
    colors = {
      background = theme.functions.toFuzzel theme.palette.secondary;
      selection = theme.functions.toFuzzel theme.palette.primary;
      text = theme.functions.toFuzzel (theme.functions.darken theme.palette.text 0.01);
      #text = theme.functions.darken "#ffffffff" 0.01;
      selection-text = theme.functions.toFuzzel theme.palette.text;
      prompt = theme.functions.toFuzzel theme.palette.text;
      input = theme.functions.toFuzzel theme.palette.text;
    };
  };
}
).wrapper



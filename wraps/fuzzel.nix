{ wrappers, pkgs, theme, ...}:
let
  darkenedText = theme.functions.darken theme.palette.text 0.1;
in
(wrappers.wrapperModules.fuzzel.apply
{
  inherit pkgs;
  settings = {
    colors = {
      background = theme.functions.toFuzzel theme.palette.secondary;
      selection = theme.functions.toFuzzel theme.palette.primary;
      #text = theme.functions.toFuzzel (theme.functions.darken theme.palette.text 0.01);
      text = theme.functions.toFuzzel darkenedText;
      selection-text = theme.functions.toFuzzel (theme.functions.textcolor theme.palette.primary);
      prompt = theme.functions.toFuzzel theme.palette.text;
      input = theme.functions.toFuzzel theme.palette.text;
    };
  };
}
).wrapper



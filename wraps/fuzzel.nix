#{ config, pkgs, ... }:
#{
#  programs.fuzzel = {
#    enable = true;
#    settings = {
#      colors = {
#        background = "#5f5fffff";
#	selection = "#ff5fd7ff";
#	text = "#ffffffff";
#	selection-text = "#ffffffff";
#	prompt = "#ffffffff";
#	input = "#ffffffff";
#      };
#    };
#  };
#}

{ wrappers, ...}:
(wrappers.wrapperModules.fuzzel.apply
{
  inherit pkgs;
  settings = {
    colors = {
      background = "#5f5fffff";
      selection = "#ff5fd7ff";
      text = "#ffffffff";
      selection-text = "#ffffffff";
      prompt = "#ffffffff";
      input = "#ffffffff";
    };
  };
}
).wrapper



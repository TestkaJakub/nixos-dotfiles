{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nerdtree
      solarized # theme ?
      syntastic # syntax highlighting for many languages
      emmet-vim # :tag tag creation
      tabular # :tab tag for aligning stuff
      vim-svelte
    ];
  };
}

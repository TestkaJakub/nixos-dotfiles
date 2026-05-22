{ pkgs, config, ... }:

# ── Neovim ─────────────────────────────────────────────────────────────────────
let
  user = config.profile.username;
in
{
  home-manager.users.${user} = {
    programs.neovim = {
      enable        = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [
        nerdtree
        solarized
        syntastic
        emmet-vim
        tabular
        vim-svelte
      ];
    };

    # bat — syntax-highlighted cat, placed here since it's tightly coupled
    # to editor workflows. Move to dev-tools/misc.nix if preferred.
    home.file.".config/bat/config".text = ''
      --theme="Nord"
      --style="numbers,changes,grid"
      --paging=auto
    '';
  };
}

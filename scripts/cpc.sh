find ~/nixos-dotfiles -type f -name '*.nix' \
  -exec echo "===== {} =====" \; -exec cat {} \; | wl-copy

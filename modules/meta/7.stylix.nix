# modules/meta/7.stylix.nix
{ pkgs, inputs, config, ... }:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  environment.systemPackages = [ pkgs.pastel ];

  stylix = {
    enable   = true;
    image    = ./wallpapers/current.jpg;
    polarity = "dark";

    fonts = {
      monospace = { package = pkgs.nerd-fonts.jetbrains-mono; name = "JetBrainsMono Nerd Font"; };
      sansSerif = { package = pkgs.noto-fonts;                name = "Noto Sans"; };
      serif     = { package = pkgs.noto-fonts;                name = "Noto Serif"; };
      emoji     = { package = pkgs.noto-fonts-color-emoji;    name = "Noto Color Emoji"; };
      sizes     = { terminal = 13; applications = 12; desktop = 12; popups = 12; };
    };

    cursor  = { package = pkgs.adwaita-icon-theme; name = "Adwaita"; size = 32; };
    opacity.terminal = 0.85;
  };

    # One source of truth: sway's `output bg` and wallpaper-init use this too
  meta.defaults.wallpaper = toString config.stylix.image;
}
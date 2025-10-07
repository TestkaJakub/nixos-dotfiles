{ pkgs, ... }:
{
  users.users.jakub = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dialout" ];
    shell = pkgs.bashInteractive;
    packages = with pkgs; [ tree ];
  };
}

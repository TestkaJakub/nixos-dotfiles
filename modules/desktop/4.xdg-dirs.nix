{ config, ... }:
let
  user = config.profile.username;
in
{
  home-manager.users.${user}.xdg.userDirs = {
    enable     = true;
    createDirectories = true;
    desktop    = "/home/jakub/data/Desktop";
    documents  = "/home/jakub/data/Documents";
    download   = "/home/jakub/data/Downloads";
    music      = "/home/jakub/data/Music";
    pictures   = "/home/jakub/data/Pictures";
    publicShare = "/home/jakub/data/Public";
    templates  = "/home/jakub/data/Templates";
    videos     = "/home/jakub/data/Videos";
  };
}
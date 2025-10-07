{ pkgs, ... }:
{
  home-manager = {
    backupFileExtension = builtins.readFile (pkgs.runCommand "timestamp" {} ''
      date --utc +%Y-%m-%d_%H-%M-%S > $out
    '');
    useUserPackages = true;
    useGlobalPkgs = true;
    users.jakub = import ./home.nix;
  };
}

{ pkgs, config, lib, ... }:

# ── Users ──────────────────────────────────────────────────────────────────────
let
  isServer    = config.profile.isRole [ "server" ];
  isNotServer = !isServer;
  user        = config.profile.username;
in
{
  users.users.${user} = {
  	openssh.authorizedKeys.keys = lib.mkIf isServer [
  		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1JpnJBPj+kVzwsUdDEwu0vVnCj6R/+7BUc8iaWLzs8 desktop"	
  	];
    isNormalUser = true;
    group        = user;
    extraGroups  = [ "wheel" "docker" ]
      ++ lib.optionals isNotServer [
        "dialout" "libvirtd" "adbusers" "scanner" "lp" "video" "render" "seat"
      ];
    shell = if isServer then pkgs.bash else pkgs.fish;
  };

  users.groups.${user} = {};

  # Allow copying server config to clipboard from the main machine via cpcs
  security.sudo.extraRules = lib.mkIf isServer [
    {
      users    = [ user ];
      commands = [{
        command = "/run/current-system/sw/bin/find /home/${user}/nixos-dotfiles *";
        options = [ "NOPASSWD" ];
      }];
    }
  ];

  home-manager = {
    useGlobalPkgs       = true;
    useUserPackages     = true;
    backupFileExtension = "bak-$(date +%Y%m%d%H%M%S)";

    users.${user} = { lib, ... }: {
      home.stateVersion = config.profile.stateVersion;

      # ── Secret sync — server only ──────────────────────────────────────────
      home.activation = lib.mkIf isServer {
      #  syncAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #    secrets="$HOME/secrets/ssh-authorized-keys"
      #    dest="$HOME/.ssh/authorized_keys"
      #    mkdir -p "$HOME/.ssh"
      #    chmod 700 "$HOME/.ssh"
      #    if [ -f "$secrets" ]; then
      #      install -m 600 "$secrets" "$dest"
      #    else
      #      echo "WARNING: $secrets not found — authorized_keys not updated"
      #    fi
      #  '';

        syncGithubKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          key="$HOME/secrets/github-ssh-key"
          dest="$HOME/.ssh/github"
          mkdir -p "$HOME/.ssh"
          chmod 700 "$HOME/.ssh"
          if [ -f "$key" ]; then
            install -m 600 "$key" "$dest"
          else
            echo "WARNING: $key not found — GitHub SSH key not deployed"
          fi
        '';

        syncGitIdentity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          identity="$HOME/secrets/git-identity"
          if [ -f "$identity" ]; then
            source "$identity"
            ${pkgs.git}/bin/git config --global user.name "$GIT_NAME"
            ${pkgs.git}/bin/git config --global user.email "$GIT_EMAIL"
          else
            echo "WARNING: $identity not found — git identity not configured"
          fi
        '';
      };
    };
  };
}

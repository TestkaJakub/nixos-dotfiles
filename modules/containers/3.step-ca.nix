{ pkgs, config, ... }:

# ── step-ca — local ACME certificate authority ─────────────────────────────────
# Server only — Traefik depends on this for TLS certificate provisioning.
#
# ── First-time bootstrap (run ONCE, never again) ───────────────────────────────
#   sudo -u ${config.profile.username} bash
#   step ca init \
#     --name "Homelab CA" \
#     --dns "localhost" \
#     --dns "192.168.0.252" \
#     --address ":9000" \
#     --provisioner "acme" \
#     --deployment-type standalone \
#     --password-file /home/${config.profile.username}/secrets/step-ca-password
#
#   step ca provisioner add acme --type ACME
#   step certificate fingerprint /home/${config.profile.username}/.step/certs/root_ca.crt
#
# ── Back this up ───────────────────────────────────────────────────────────────
#   /home/${config.profile.username}/.step/secrets/ (root + intermediate keys)
#   If lost you'll need to re-bootstrap and re-trust on all devices.
let
  user    = config.profile.username;
  stepDir = "/home/${user}/.step";
  secrets = "/home/${user}/secrets";
in
{
  environment.systemPackages = with pkgs; [
    step-cli
    step-ca
  ];

  systemd.services.step-ca = {
    description = "step-ca local ACME certificate authority";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "network.target" ];

    serviceConfig = {
      Type       = "simple";
      User       = user;
      Group      = user;
      ExecStart  = "${pkgs.step-ca}/bin/step-ca ${stepDir}/config/ca.json --password-file ${secrets}/step-ca-password";
      Restart    = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.step-ca-renew = {
    description = "Renew step-ca intermediate certificate";
    serviceConfig = {
      Type      = "oneshot";
      User      = "root";
      ExecStart = pkgs.writeShellScript "step-ca-renew" ''
        ${pkgs.step-cli}/bin/step ca renew \
          ${stepDir}/certs/intermediate_ca.crt \
          ${stepDir}/secrets/intermediate_ca_key \
          --force \
          --offline \
          --ca-url https://localhost:9000 \
          --root ${stepDir}/certs/root_ca.crt
        systemctl kill -s HUP step-ca
      '';
    };
  };

  systemd.timers.step-ca-renew = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 06,18:00:00";
      Persistent = true;
    };
  };
}
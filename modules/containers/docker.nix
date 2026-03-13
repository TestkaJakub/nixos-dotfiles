{ config, ... }:

# ── Docker ─────────────────────────────────────────────────────────────────────
# Daemon configuration and backend declaration for virtualisation.oci-containers.
# Individual containers live in their own files in this directory.
# Reads: config.profile.username
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      userland-proxy = false;
      experimental   = true;
    };
  };

  # All oci-containers in this directory use docker as the backend.
  virtualisation.oci-containers.backend = "docker";

  # Add the user to the docker group so rootless CLI access works.
  users.users.${config.profile.username}.extraGroups = [ "docker" ];
}

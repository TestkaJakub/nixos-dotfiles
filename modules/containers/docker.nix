{ ... }:

# ── Docker ─────────────────────────────────────────────────────────────────────
# The docker group is assigned in system/users.nix — not here.
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      userland-proxy = false;
      experimental   = true;
    };
  };

  virtualisation.oci-containers.backend = "docker";
}

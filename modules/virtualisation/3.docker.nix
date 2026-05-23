{ ... }:
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      userland-proxy = true;
      experimental   = true;
    };
  };

  virtualisation.oci-containers.backend = "docker";
}
{ config, ... }:

# ── Ollama (ROCm container) ────────────────────────────────────────────────────
# Desktop-only. The native services.ollama (see 7.ollama.nix) is disabled on
# desktop because its bundled nixpkgs HIP backend (0.21.1) does not enumerate
# gfx1201 (RX 9070 XT) — confirmed: GPU discovery falls back to CPU even with
# HSA_OVERRIDE_GFX_VERSION set. The ollama/ollama:rocm image ships its own
# ROCm 7.x userspace + gfx1201 kernels, so it drives the card properly.
#
# Models: bind-mounted from the SAME store the native service used, so the
# ~32 GB already on /home/jakub/data/ollama-store carries over untouched.
# Published on 11434 so Odysseus (host.docker.internal:11434) keeps working
# with no change to 4.odysseus.nix.
let
  user = config.profile.username;
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/data/ollama-store 0755 ${user} ${user} -"
  ];

  virtualisation.oci-containers.containers.ollama = {
    image     = "ollama/ollama:rocm";
    autoStart = true;

    environment = {
      TZ          = "Europe/Warsaw";
      OLLAMA_HOST = "0.0.0.0:11434";
      # gfx1201 is native in ROCm 7.x — no override needed. If a future image
      # regresses, add: HSA_OVERRIDE_GFX_VERSION = "12.0.1";
    };

    volumes = [
      # Native service stored models at ollama-store/models/{blobs,manifests}.
      # The image expects /root/.ollama/models/..., so map the store onto
      # /root/.ollama and the existing layout lines up 1:1.
      "/home/${user}/data/ollama-store:/root/.ollama"
    ];

    ports = [ "11434:11434" ];

    extraOptions = [
      "--device=/dev/kfd"
      "--device=/dev/dri"
      "--group-add=video"
      "--group-add=303"
      "--security-opt=seccomp=unconfined"
    ];
  };

  systemd.services.docker-ollama = {
    after    = [ "docker.service" ];
    requires = [ "docker.service" ];
  };
}
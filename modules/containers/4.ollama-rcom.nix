{ pkgs, config, ... }:

# ── Ollama (ROCm container) ────────────────────────────────────────────────────
# Desktop-only. The native services.ollama (see 3.ollama.nix) doesn't enumerate
# gfx1201 (RX 9070 XT); the ollama/ollama:rocm image ships its own ROCm 7.x
# userspace + gfx1201 kernels, so it drives the card properly.
#
# Access paths — nothing is published to the LAN:
#   Odysseus         → http://ollama:11434 over the `ai` Docker network
#   desktop host     → http://127.0.0.1:11434 (ollama CLI, editor plugins)
#   tailnet devices  → http://desktop:11434 via `tailscale serve` (below)
#
# Models: bind-mounted from the store the native service used, so the existing
# ~32 GB in /home/jakub/data/ollama-store carries over untouched.
let
  user      = config.profile.username;
  docker    = "${pkgs.docker}/bin/docker";
  tailscale = "${config.services.tailscale.package}/bin/tailscale";
in
{
  systemd.tmpfiles.rules = [
    "d /home/${user}/data/ollama-store 0755 ${user} ${user} -"
  ];

  # ── Shared network for Ollama consumers (Odysseus) ──────────────────────────
  systemd.services.docker-network-ai = {
    description = "Create 'ai' Docker network";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "docker.service" ];
    requires    = [ "docker.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${docker} network inspect ai >/dev/null 2>&1 || ${docker} network create ai
    '';
  };

  virtualisation.oci-containers.containers.ollama = {
    image     = "ollama/ollama:rocm";
    autoStart = true;

    environment = {
      TZ          = "Europe/Warsaw";
      OLLAMA_HOST = "0.0.0.0:11434";   # inside the container; exposure is controlled by `ports`
      # gfx1201 is native in ROCm 7.x — if a future image regresses, add:
      # HSA_OVERRIDE_GFX_VERSION = "12.0.1";
    };

    volumes = [ "/home/${user}/data/ollama-store:/root/.ollama" ];

    ports = [ "127.0.0.1:11434:11434" ];   # host-local only

    extraOptions = [
      "--network=ai"
      "--network-alias=ollama"
      "--device=/dev/kfd"
      "--device=/dev/dri"
      "--group-add=video"
      "--group-add=303"
      "--security-opt=seccomp=unconfined"
    ];
  };

  systemd.services.docker-ollama = {
    after    = [ "docker.service" "docker-network-ai.service" ];
    requires = [ "docker.service" "docker-network-ai.service" ];
  };

  # ── Expose on the tailnet only ──────────────────────────────────────────────
  # tailscaled listens on the desktop's tailnet address and forwards to
  # localhost. Serve config persists in tailscaled's state; re-applying is
  # idempotent, this unit just keeps it declarative.
  systemd.services.tailscale-serve-ollama = {
    description = "Expose Ollama on the tailnet via tailscale serve";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "tailscaled.service" "docker-ollama.service" ];
    wants       = [ "tailscaled.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 30); do
        ${tailscale} status >/dev/null 2>&1 && break
        sleep 2
      done
      ${tailscale} serve --bg --tcp 11434 tcp://127.0.0.1:11434
    '';
  };
}
{ pkgs, config, lib, ... }:

# ── Traefik — reverse proxy ────────────────────────────────────────────────────
# TLS via step-ca ACME running locally.
# On server: exposes to LAN, uses Pi-hole for DNS.
# On workstation: local only, no Pi-hole so DNS falls back to host.
#
# Adding a new service — add these labels to the container:
#   "--label=traefik.enable=true"
#   "--label=traefik.http.routers.NAME.rule=Host(`name.home`)"
#   "--label=traefik.http.routers.NAME.entrypoints=websecure"
#   "--label=traefik.http.routers.NAME.tls=true"
#   "--label=traefik.http.routers.NAME.tls.certresolver=step"
#   "--label=traefik.http.services.NAME.loadbalancer.server.port=PORT"
let
  isServer = config.profile.isRole [ "server" ];
  user     = config.profile.username;

  dataDir  = "/home/${user}/docker-data/traefik";
  acmeDir  = "${dataDir}/acme";
  stepCert = "/home/${user}/.step/certs/root_ca.crt";

  # dynamic.yml — server gets cctv and pihole routers, workstation doesn't
  dynamicYml = if isServer then ''
    http:
      routers:
        cctv:
          rule: "Host(`cctv.home`)"
          entryPoints:
            - websecure
          tls:
            certResolver: step
          service: cctv
        pihole:
          rule: "Host(`pihole.home`)"
          entryPoints:
            - websecure
          middlewares:
            - pihole-slash
          tls:
            certResolver: step
          service: pihole
        ping:
          rule: "Host(`traefik.home`) && Path(`/ping`)"
          entryPoints:
            - websecure
          tls:
            certResolver: step
          service: ping@internal
        http-catchall:
          rule: "HostRegexp(`{host:.+}`)"
          entryPoints:
            - web
          priority: 1
          middlewares:
            - https-redirect
          service: noop@internal
      middlewares:
        pihole-slash:
          redirectRegex:
            regex: "^https://pihole\\.home/?$"
            replacement: "https://pihole.home/admin/"
        https-redirect:
          redirectScheme:
            scheme: https
            permanent: true
      services:
        cctv:
          loadBalancer:
            servers:
              - url: "http://192.168.0.253:80"
        pihole:
          loadBalancer:
            servers:
              - url: "http://172.17.0.1:8053"
  '' else ''
    http:
      routers:
        ping:
          rule: "Host(`traefik.home`) && Path(`/ping`)"
          entryPoints:
            - websecure
          tls:
            certResolver: step
          service: ping@internal
        http-catchall:
          rule: "HostRegexp(`{host:.+}`)"
          entryPoints:
            - web
          priority: 1
          middlewares:
            - https-redirect
          service: noop@internal
      middlewares:
        https-redirect:
          redirectScheme:
            scheme: https
            permanent: true
  '';

  traefikYml = ''
api:
      dashboard: true
      insecure: false

    ping: {}

    log:
      level: INFO

    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"

    providers:
      docker:
        endpoint: "unix:///var/run/docker.sock"
        exposedByDefault: false
      file:
        filename: "/traefik-dynamic.yml"
        watch: true

    certificatesResolvers:
      step:
        acme:
          email: "jakub@home.local"
          storage: "/acme/acme.json"
          caServer: "https://host.docker.internal:9000/acme/acme/directory"
          certificatesDuration: 24
          httpChallenge:
            entryPoint: web

    serversTransport:
      rootCAs:
        - "/certs/root_ca.crt"
  '';
in
{
  # ── Docker network ───────────────────────────────────────────────────────────
  systemd.services.docker-network-traefik = {
    description = "Create 'traefik' Docker network";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "docker.service" ];
    requires    = [ "docker.service" ];

    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-traefik-network" ''
        ${pkgs.docker}/bin/docker network inspect traefik >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create traefik
      '';
    };
  };

  # ── Config files ─────────────────────────────────────────────────────────────
  system.activationScripts.traefikConfig = {
    text = ''
      mkdir -p ${dataDir} ${acmeDir}
      cat > ${dataDir}/traefik.yml << 'EOF'
      ${traefikYml}
EOF
      cat > ${dataDir}/dynamic.yml << 'EOF'
      ${dynamicYml}
EOF
      chown ${user}:${user} ${dataDir}/traefik.yml ${dataDir}/dynamic.yml
    '';
    deps = [];
  };

  # ── Directories ──────────────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 ${user} ${user} -"
    "d ${acmeDir} 0700 ${user} ${user} -"
  ];

  # ── Container ────────────────────────────────────────────────────────────────
  virtualisation.oci-containers.containers.traefik = {
    image     = "traefik:v3.3";
    autoStart = true;

    environment = {
      LEGO_CA_CERTIFICATES = "/certs/root_ca.crt";
    };

    ports = [
      "80:80"
      "443:443"
      "8080:8080"
    ];

    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "${stepCert}:/certs/root_ca.crt:ro"
      "${acmeDir}:/acme"
      "${dataDir}/traefik.yml:/traefik.yml:ro"
      "${dataDir}/dynamic.yml:/traefik-dynamic.yml:ro"
    ];

    extraOptions = [
      "--group-add=131"
      "--network=traefik"
      "--add-host=host.docker.internal:host-gateway"
      "--health-cmd=traefik healthcheck --ping"
      "--health-start-period=180s"
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.dashboard.rule=Host(`traefik.home`)"
      "--label=traefik.http.routers.dashboard.entrypoints=websecure"
      "--label=traefik.http.routers.dashboard.tls=true"
      "--label=traefik.http.routers.dashboard.tls.certresolver=step"
      "--label=traefik.http.routers.dashboard.service=api@internal"
    ] ++ lib.optionals isServer [
      "--dns=172.17.0.1"
    ];
  };

  # ── Ordering ─────────────────────────────────────────────────────────────────
  systemd.services.docker-traefik = {
    after    = [ "docker-network-traefik.service" ];
    requires = [ "docker-network-traefik.service" ];
  };
}
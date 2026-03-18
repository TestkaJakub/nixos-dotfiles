{ ... }:

# ── Vikunja ────────────────────────────────────────────────────────────────────
# Self-hosted task manager. Consists of two containers that form one service:
#   vikunja-db  — PostgreSQL 16 database
#   vikunja     — application server (depends on vikunja-db)
#
# Web UI is available at http://localhost:3456
# Secrets: /home/jakub/secrets/vikunja-db.env must contain POSTGRES_PASSWORD
#          and VIKUNJA_DATABASE_PASSWORD.
#
# Volume ownership is enforced declaratively via systemd-tmpfiles so the
# host paths are always owned by uid/gid 1000 (the non-root user the official
# Vikunja image runs as) without any manual chown step.
{
  systemd.tmpfiles.rules = [
    "d /home/jakub/docker-data/vikunja-db    0755 1000 1000 -"
    "d /home/jakub/docker-data/vikunja-files 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {

    vikunja-db = {
      image     = "postgres:16";
      autoStart = true;

      environmentFiles = [ "/home/jakub/secrets/vikunja-db.env" ];
      environment = {
        POSTGRES_USER = "vikunja";
        POSTGRES_DB   = "vikunja";
      };

      volumes      = [ "/home/jakub/docker-data/vikunja-db:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=host" ];
    };

    vikunja = {
      image     = "vikunja/vikunja:2.1.0";
      autoStart = true;
      dependsOn = [ "vikunja-db" ];

      environmentFiles = [ "/home/jakub/secrets/vikunja-db.env" ];
      environment = {
        VIKUNJA_DATABASE_HOST     = "127.0.0.1";
        VIKUNJA_DATABASE_USER     = "vikunja";
        VIKUNJA_DATABASE_DATABASE = "vikunja";
        VIKUNJA_DATABASE_TYPE     = "postgres";
        VIKUNJA_SERVICE_PUBLICURL = "http://localhost:3456";
      };

      volumes      = [ "/home/jakub/docker-data/vikunja-files:/app/vikunja/files" ];
      extraOptions = [ "--network=host" ];
    };

  };
}

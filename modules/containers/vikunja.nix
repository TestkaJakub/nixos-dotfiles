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
# Volume ownership: Vikunja runs as uid 1000 inside the container (the default
# non-root user in the official image). Ensure the host paths are owned by
# uid 1000 before first start:
#   sudo chown -R 1000:1000 /home/jakub/docker-data/vikunja-files
{
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
      image     = "vikunja/vikunja:0.24.6";
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
      # Runs as the default non-root user (uid 1000) defined in the official image.
      # See ownership note above if the files volume was previously owned by root.
    };

  };
}

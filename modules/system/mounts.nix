{ ... }:

# ── Network mounts ─────────────────────────────────────────────────────────────
# Samba share from server — mounted at /mnt/server-data
# Credentials stored in ~/secrets/samba-credentials
#
# Create credentials file (run once):
#   mkdir -p ~/secrets
#   echo "username=jakub" > ~/secrets/samba-credentials
#   echo "password=your_samba_password" >> ~/secrets/samba-credentials
#   chmod 600 ~/secrets/samba-credentials
{
  fileSystems."/mnt/server-data" = {
    device  = "//192.168.0.252/data";
    fsType  = "cifs";
    options = [
      "credentials=/home/jakub/secrets/samba-credentials"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
    ];
  };

  # cifs-utils required for mounting Samba shares
  environment.systemPackages = [ pkgs.cifs-utils ];
}

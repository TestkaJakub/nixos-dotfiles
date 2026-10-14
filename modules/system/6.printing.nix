{ pkgs, ... }:

# ── Printing & scanning ────────────────────────────────────────────────────────
# Epson EPSOND31949 on the Starlink/MikroTik LAN.
# Static lease on the MikroTik: 192.168.8.45 (MAC A4:D7:3C:D3:19:49).
# Pinned by IP, so no Avahi/mDNS discovery is needed.
let
  printerIp = "192.168.8.45";
in
{
  # ── Printing ────────────────────────────────────────────────────────────────
  services.printing = {
    enable  = true;
    drivers = [ pkgs.epson-escpr ];   # fallback if driverless IPP misbehaves
  };

  hardware.printers = {
    ensurePrinters = [{
      name      = "Epson";
      deviceUri = "ipp://${printerIp}/ipp/print";
      model     = "everywhere";       # driverless IPP Everywhere
    }];
    ensureDefaultPrinter = "Epson";
  };

  # ── Scanning ────────────────────────────────────────────────────────────────
    # ── Scanning ────────────────────────────────────────────────────────────────
  # nixpkgs has no hardware.sane.extraConfig, so the printer is appended to
  # sane-airscan's bundled airscan.conf, which ends up in /etc/sane.d.
  hardware.sane = {
    enable        = true;
    extraBackends = [
      (pkgs.sane-airscan.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          cat >> $out/etc/sane.d/airscan.conf <<EOF

          [devices]
          "Epson" = http://${printerIp}/eSCL, eSCL
          EOF
        '';
      }))
    ];
  };
}
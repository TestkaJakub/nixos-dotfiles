{ pkgs, ... }:

# ── Printing & scanning ────────────────────────────────────────────────────────
{
  services.printing = {
    enable  = true;
    drivers = [ pkgs.epson-escpr ];
  };

  hardware.sane = {
    enable        = true;
    extraBackends = [ pkgs.sane-airscan ];  # supports most modern network scanners
  };
}

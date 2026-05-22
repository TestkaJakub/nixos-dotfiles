{ pkgs, ... }:

# ── Tor Browser ────────────────────────────────────────────────────────────────
{
  environment.systemPackages = with pkgs; [
    tor-browser
    tor           # underlying daemon, useful for torsocks etc.
  ];
}

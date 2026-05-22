{ ... }:

# ── Libvirt / virt-manager ─────────────────────────────────────────────────────
# KVM-based virtual machine management.
# The user is added to the libvirtd group in system/users.nix.
{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable   = true;
}

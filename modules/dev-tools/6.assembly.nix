{ pkgs, ... }:

# ── Assembly development ────────────────────────────────────────────────────────
# General-purpose assembler toolchain.
#   nasm    — x86/x86-64 assembler (Intel syntax)
#   binutils — as, ld, objdump, readelf, nm, strip, etc.
#   gdb     — debugger
#   gef     — GDB enhanced features (pretty-printing, layout helpers)
#
# For i386 AT&T syntax with a streamlined build+debug script, see assembly-i386.nix.
# To remove: delete this file and assembly-i386.nix, then rebuild.
{
  environment.systemPackages = with pkgs; [
    nasm
    binutils
    gdb
    gef
  ];
}

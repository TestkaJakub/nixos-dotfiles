{ pkgs, config, ... }:

# ── i386 AT&T assembly ─────────────────────────────────────────────────────────
# Streamlined build+debug script for 32-bit x86 AT&T syntax programs.
#
# Usage:
#   asm32 program.s          → assembles, links, drops into gdb
#   asm32 -i foo.s           → explicit input flag
#   asm32 -o bar.out foo.s   → custom output name (default: a.out)
#   asm32 -i foo.s -o bar.out
#
# Pipeline:
#   as --32 -g <input> -o <input>.o
#   ld -melf_i386 <input>.o -o <output>
#   gdb <output>
#
# Depends on assembly.nix for binutils and gdb being present.
# To remove: delete this file (and assembly.nix if no longer needed), then rebuild.
let
  user = config.profile.username;

  asm32 = pkgs.writeShellScriptBin "asm32" ''
    input=""
    output="a.out"

    usage() {
      echo "Usage: asm32 [-i input.s] [-o output] [input.s]"
      echo "  -i  input .s file  (default: positional argument)"
      echo "  -o  output binary  (default: a.out)"
      exit 1
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        -i) input="$2"; shift 2 ;;
        -o) output="$2"; shift 2 ;;
        -*) usage ;;
        *)  [ -z "$input" ] && input="$1" || usage; shift ;;
      esac
    done

    [ -z "$input" ] && usage

    if [ ! -f "$input" ]; then
      echo "asm32: file not found: $input"
      exit 1
    fi

    obj="''${input%.s}.o"

    echo "  AS  $input -> $obj"
    ${pkgs.binutils}/bin/as --32 -g "$input" -o "$obj" || exit 1

    echo "  LD  $obj -> $output"
    ${pkgs.binutils}/bin/ld -melf_i386 "$obj" -o "$output" || exit 1

    echo "  GDB $output"
    ${pkgs.gdb}/bin/gdb "$output"
  '';
in
{
  home-manager.users.${user}.home.packages = [ asm32 ];
}

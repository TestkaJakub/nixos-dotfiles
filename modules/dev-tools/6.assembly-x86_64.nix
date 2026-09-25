{ pkgs, config, ... }:

# ── x_86_64 AT&T assembly ─────────────────────────────────────────────────────────
# Streamlined build+debug script for 64-bit x86 AT&T syntax programs.
#
# Usage:
#   asm64 program.s          → assembles, links, drops into gdb
#   asm64 -i foo.s           → explicit input flag
#   asm64 -o bar.out foo.s   → custom output name (default: a.out)
#   asm64 -i foo.s -o bar.out
#
# Pipeline:
#   as -g <input> -o <input>.o
#   ld -melf_x86_64 <input>.o -o <output>
#   gdb <output>
#
# Depends on assembly.nix for binutils and gdb being present.
# To remove: delete this file (and assembly.nix if no longer needed), then rebuild.
let
  user = config.profile.username;

  asm64new = pkgs.writeShellScriptBin "masm64" ''
    file=""

    usage() {
      echo "Usage: masm64 [-f file.s] [file.s]"
      echo "  -f  output filename"
      exit 1
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        -f) file="$2"; shift 2 ;;
        -*) usage ;;
        *)  [ -z "$file" ] && file="$1" || usage; shift ;;
      esac
    done

    [ -z "$file" ] && usage

    if [ -e "$file" ]; then
      echo "masm64: file already exists: $file"
      exit 1
    fi

    cat > "$file" <<'EOF'
.globl _start
.text

_start:
__begin:
__end: nop
EOF

    echo "  NEW $file"
    exec ${config.meta.defaults.editor} "$file"
  '';

  asm64 = pkgs.writeShellScriptBin "asm64" ''
    input=""
    output="a.out"

    usage() {
      echo "Usage: asm64 [-i input.s] [-o output] [input.s]"
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
      echo "asm64: file not found: $input"
      exit 1
    fi

    obj=$(mktemp /tmp/asm64-XXXXXX.o)
    trap 'rm -f "$obj"' EXIT

    echo "  AS  $input -> $obj"
    ${pkgs.binutils}/bin/as -g "$input" -o "$obj" || exit 1

    echo "  LD  $obj -> $output"
    ${pkgs.binutils}/bin/ld -melf_x86_64 "$obj" -o "$output" || exit 1

    echo "  GDB $output"
    ${pkgs.gdb}/bin/gdb "$output"
  '';
in
{
  home-manager.users.${user}.home.packages = [ asm64 asm64new ];
}

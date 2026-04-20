{ pkgs, ... }:

# ── Godot ──────────────────────────────────────────────────────────────────────
# Game engine. For GDScript and C# development.
# Mono variant includes C# support via .NET runtime.
{
  environment.systemPackages = [ pkgs.godot_4 ];
}

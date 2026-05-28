{ pkgs, lib, config, ... }:
let
  isDesktop = config.profile.isRole [ "personal" ];
in
{
  services.seatd.enable = true;
  services.xserver.enable = true;
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    # Keep SDDM on X11 — it can still launch Wayland sessions from the menu
    # and is far more stable with NVIDIA 470 than SDDM-Wayland
    displayManager.sddm.wayland.enable = lib.mkDefault false;
  };

  environment = { 
  	systemPackages = with pkgs; [
    	# KDE Utilities
	    kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
   		kdePackages.kcalc # Calculator
   		kdePackages.kcharselect # Character map
    	kdePackages.kclock # Clock app
    	kdePackages.kcolorchooser # Color picker
    	kdePackages.kolourpaint # Simple paint program
    	kdePackages.ksystemlog # System log viewer
    	kdePackages.sddm-kcm # SDDM configuration module
    	kdiff3 # File/directory comparison tool
    
    	# Hardware/System Utilities (Optional)
    	kdePackages.isoimagewriter # Write hybrid ISOs to USB
    	kdePackages.partitionmanager # Disk and partition management
    	hardinfo2 # System benchmarks and hardware info
    	wayland-utils # Wayland diagnostic tools
    	wl-clipboard # Wayland copy/paste support
    	vlc # Media player
    	xclip
 	 ];
  };
}

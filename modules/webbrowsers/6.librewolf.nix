{ pkgs, config, ... }:
let
  user = config.profile.username;
in
{
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      OfferToSaveLogins = true;
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      Preferences = {
        "layout.css.prefers-color-scheme.content-override" = 1;
        "privacy.fingerprintingProtection" = true;
        "signon.rememberSignons" = { Value = true; Status = "user"; };
        "signon.autofillForms" = { Value = true; Status = "user"; };
        "signon.formlessCapture.enabled" = { Value = true; Status = "user"; };
        "ui.systemUsesDarkTheme" = { Value = 1; Status = "user"; };
        "browser.theme.toolbar-theme" = { Value = 0; Status = "user"; };
        "browser.theme.content-theme" = { Value = 0; Status = "user"; };
        "extensions.activeThemeID" = { Value = "firefox-compact-dark@mozilla.org"; Status = "user"; };
      };
      ExtensionSettings = {
        "jid1-ZAdIEUB7XOzOJw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/duckduckgo-for-firefox/latest.xpi";
          installation_mode = "force_installed";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  environment.etc."firefox/policies/policies.json".target = "librewolf/policies/policies.json";

  home-manager.users.${user}.home.file.".librewolf/librewolf.overrides.cfg".text = ''
    defaultPref("signon.rememberSignons", true);
    defaultPref("signon.autofillForms", true);
    defaultPref("signon.formlessCapture.enabled", true);
    defaultPref("privacy.resistFingerprinting", false);
    defaultPref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
    defaultPref("ui.systemUsesDarkTheme", 1);
    defaultPref("browser.theme.toolbar-theme", 0);
    defaultPref("browser.theme.content-theme", 0);
  '';
}
{
  pkgs,
  ...
}:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
	--time \
	--asteriks \
	--user-menu \
	--cmd sway
      ";
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
  '';
}


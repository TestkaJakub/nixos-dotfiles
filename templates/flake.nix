{
  description = "My Nix templates";

  outputs = { self }: {
    templates = {
      node = {
        path = ./node;
        description = "Node.js development environment";
      };
      android-dev = {
        path = ./android-dev;
	description = "SaladinAyyub's solution for android development"
      };
    };
  };
}

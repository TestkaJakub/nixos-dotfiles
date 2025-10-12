{
  description = "My Nix templates";

  outputs = { self }: {
    templates = {
      node = {
        path = ./node;
        description = "Node.js development environment";
      };
    };
  };
}

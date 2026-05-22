{ pkgs, config, ... }:

# ── Terraform + Azure CLI ───────────────────────────────────────────────────────
# Narzędzia do provisjonowania infrastruktury w chmurze Azure.
#
#   terraform    — główne CLI do zarządzania infrastrukturą jako kodem
#   azure-cli    — az login, az vm, az group itp.
#
# Pierwsze użycie po rebuildie:
#   az login                              (jednorazowo — otwiera przeglądarkę)
#   cd ~/projects/moja-vm
#   terraform init
#   terraform plan
#   terraform apply
#
# Umieszczone w dev-tools/ jako narzędzia deweloperskie / devops.
# Jeśli zbierzesz więcej modułów cloud/IaC, rozważ osobny katalog infra/.
let
  user = config.profile.username;
in
{
  environment.systemPackages = with pkgs; [
    terraform
    azure-cli
  ];

  # Bash completion dla obu narzędzi działa automatycznie dzięki
  # programs.bash.enableCompletion. Fish obsługuje completions przez
  # azure-cli i terraform natywnie — nie trzeba nic dodawać.

  home-manager.users.${user} = {
    home.sessionVariables = {
      # Wyłącza telemetrię Azure CLI
      AZURE_CORE_COLLECT_TELEMETRY = "false";

      # Terraform przechowuje dane w ~/.terraform.d/ domyślnie — OK.
      # Jeśli chcesz zmienić lokalizację cache pluginów:
      # TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
    };
  };
}

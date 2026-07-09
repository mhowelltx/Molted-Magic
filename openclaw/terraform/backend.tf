# Remote state backend: HCP Terraform (Terraform Cloud). Organization and
# workspace names are not secrets, so they're committed directly. Auth comes
# from the TF_TOKEN_app_terraform_io env var (never committed) via
# `terraform login` or a manually-set user token.
terraform {
  cloud {
    organization = "FlyingThunderWolfDesign"

    workspaces {
      name = "molted-magic-openclaw"
    }
  }
}

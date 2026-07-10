# Remote state backend: HCP Terraform (Terraform Cloud). Organization and
# workspace names are not secrets, so they're committed directly. Auth comes
# from the TF_TOKEN_app_terraform_io env var (never committed) via
# `terraform login` or a manually-set user token.
#
# The molted-magic-openclaw workspace's execution mode is set to LOCAL
# (changed from the HCP Terraform default of "remote" via the workspace API/
# UI, not in this file — the `cloud` block below doesn't control it). This is
# required, not just preferred: main.tf's templatefile() call reads
# ../cloud-init/user-data.yml.tmpl, a sibling directory outside this working
# directory. Remote execution only uploads this directory to HCP's runner, so
# that reference fails under "remote" but works under "local" (state still
# lives in HCP Terraform either way — only the plan/apply compute location
# changes). Don't switch this workspace back to remote execution without
# also restructuring the cloud-init reference.
terraform {
  cloud {
    organization = "FlyingThunderWolfDesign"

    workspaces {
      name = "molted-magic-openclaw"
    }
  }
}

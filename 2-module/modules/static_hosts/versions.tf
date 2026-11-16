# A child module that uses a non-HashiCorp provider MUST declare its source
# here. Without this, Terraform assumes "hashicorp/cato" (the default namespace)
# and init fails with "provider registry.terraform.io/hashicorp/cato ... Did you
# intend to use catonetworks/cato?". No version constraint here -- the ROOT module
# owns the version pin; the child only declares which provider it needs.
terraform {
  required_providers {
    cato = {
      source = "catonetworks/cato"
    }
  }
}

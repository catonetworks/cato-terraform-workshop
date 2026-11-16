terraform {
  # for_each, optional() object attributes, and csvdecode used across these
  # exercises are all available in modern Terraform. 1.5+ is a safe floor.
  # required_version = ">= 1.5.0"

  required_providers {
    cato = {
      source = "catonetworks/cato"
      version = "= 2.0.0-prerelease.1"
    }
  }
}

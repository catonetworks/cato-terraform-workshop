terraform {
  required_version = ">= 1.7.0"
  required_providers {
    cato = {
      source = "catonetworks/cato"
      version = "= 2.0.0-prerelease.1"
    }
  }
}

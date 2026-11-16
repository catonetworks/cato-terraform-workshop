terraform {
  # for_each, optional() object attributes, and csvdecode used across these
  # exercises are all available in modern Terraform. 1.5+ is a safe floor.
  # required_version = ">= 1.5.0"

  required_providers {
    cato = {
      source = "catonetworks/cato"
      # 2.0.0-prerelease.1 is the current workshop provider (profile auth + the
      # 2.x bulk resources). Installs from the public Terraform Registry -- no
      # filesystem mirror. This MUST be an exact "=" pin: Terraform excludes
      # pre-release versions from range operators (>=, ~>), so a plain
      # ">= 2.0.0-prerelease.1" would NOT select it. Switch to ">= 2.0.0" once a
      # final 2.0.0 ships.
      version = "= 2.0.0-prerelease.1"
    }
  }
}

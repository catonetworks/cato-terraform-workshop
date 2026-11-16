############################################################################
# Exercise 4 -- Brownfield Deployment Internet Firewall with migration/import
############################################################################

# One provider block that supports BOTH authentication styles:
#   1. catocli profile  -> set var.cato_profile (or `export CATO_PROFILE=<name>`)
#   2. explicit creds    -> set var.cato_token + var.account_id (or export CATO_TOKEN)

provider "cato" {
  profile = "your-cli-profile-name"
}

# # Auth Option 2 - api_token
# provider "cato" {
#   baseurl    = var.cato_baseurl
#   token      = var.cato_token
#   account_id = var.account_id
# }

module "if_rules" {
  source  = "catonetworks/bulk-if-rules/cato"
  version = "~= 0.0.9"

  # Path to the policy exported with:
  #   catocli export if_rules --json-filename all_ifw_rules_and_sections.json
  ifw_rules_json_file_path = "${path.module}/config_data/all_ifw_rules_and_sections.json"
  # Empty policies are handled automatically (dynamic guard) -- no allow_empty_policy flag.
}

output "deployment_summary" {
  description = "Counts (rules, sections, enabled/disabled, etc.) for the deployment."
  value       = module.if_rules.deployment_summary
}

output "rule_ids" {
  description = "Map of rule name -> id."
  value       = module.if_rules.rule_ids
}

output "section_ids" {
  description = "Map of section name -> id."
  value       = module.if_rules.section_ids
}

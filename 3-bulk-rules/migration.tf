# One-shot brownfield RE-adoption of the live Internet Firewall policy.

# locals {
#   ifw_migration = jsondecode(file("config_data/all_ifw_rules_and_sections.json")).data.policy.internetFirewall.policy
# }

# import {
#   for_each = { for s in local.ifw_migration.sections : s.section_name => s }

#   to = module.if_rules.cato_if_section.sections[each.key]
#   id = each.value.section_id
# }

# import {
#   for_each = { for r in local.ifw_migration.rules : r.rule.name => r.rule }

#   to = module.if_rules.cato_if_rule.rules[each.key]
#   id = each.value.id
# }

locals {
  ifw_policy = jsondecode(file("./config_data/all_ifw_rules_and_sections.json")).data.policy.internetFirewall.policy

  ifw_main_sections = {
    for s in local.ifw_policy.sections : s.section_name => s
    if try(s.sub_policy_name, null) == null
  }
  ifw_main_rules = {
    for r in local.ifw_policy.rules : r.rule.name => r.rule
    if try(r.sub_policy_name, null) == null
  }
  ifw_sub_policies = {
    for sp in try(local.ifw_policy.sub_policies, []) : sp.sub_policy_name => sp
  }
  ifw_sub_rules = {
    for r in local.ifw_policy.rules : "${r.sub_policy_name}::${r.rule.name}" => r.rule
    if try(r.sub_policy_name, null) != null
  }
}

import {
  for_each = local.ifw_main_sections
  to       = module.if_rules.cato_if_section.sections[each.key]
  id       = each.value.section_id
}

import {
  for_each = local.ifw_main_rules
  to       = module.if_rules.cato_if_rule.rules[each.key]
  id       = each.value.id
}

import {
  for_each = local.ifw_sub_policies
  to       = module.if_rules.cato_if_sub_policy.sub_policies[each.key]
  id       = each.value.sub_policy_id
}

import {
  for_each = local.ifw_sub_rules
  to       = module.if_rules.cato_if_rule.sub_rules[each.key]
  id       = each.value.id
}
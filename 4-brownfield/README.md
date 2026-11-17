# Exercise 4 — Brownfield adoption at scale

**Goal:** take Exercise 3's bulk module and point it at a policy that **already exists
live**, then adopt every rule and section into state with native `import` blocks — so
Terraform manages the existing policy **without recreating it**. This is Exercise 2's
single-resource import, generalized to a whole policy.

---

## Prerequisites

- You understand Exercise 2 (single-resource `terraform import`) and Exercise 3 (the
  bulk IFW module).
- `catocli` installed.
- A dev tenant that **already has** an Internet Firewall policy you want to adopt.
- Auth configured (see **Authentication — choose one** below).
- Provider `catonetworks/cato` **`= 2.0.0-prerelease.1`** + module
  `catonetworks/bulk-if-rules/cato` **`= 0.0.9`**, both installed from the public
  Terraform Registry (no filesystem mirror).

---

## Authentication — choose one

Unlike the other exercises, this folder's `main.tf` ships **without** a `provider "cato"`
block — add **one** of the two blocks below to `main.tf` (they're mutually exclusive).

**Option A — Terraform environment-variable (token) auth:** add to `main.tf`:
```hcl
provider "cato" {
  baseurl    = "https://api.catonetworks.com/api/v1/graphql2"
  token      = var.cato_token
  account_id = var.account_id
}
```
```bash
export TF_VAR_cato_token="R=...|K=..."
export TF_VAR_account_id="<your-dev-account-id>"
```
(or copy `terraform.tfvars.example` → `terraform.tfvars`, which is gitignored.)

**Option B — Cato CLI profile auth:** add to `main.tf`:
```hcl
provider "cato" {
  profile = "your-cli-profile-name"
}
```
(creds resolved from `~/.cato/credentials`; requires catocli configured — see the root
README's 3.3.0 prerequisite.)

---

## How it works — a one-shot `migration.tf`

The same `module "if_rules"` block as Exercise 3, plus a `migration.tf` full of
`import` blocks that map each live object (by the IDs in your exported JSON) to its
address inside the module. The file ships as `migration.tf.parked` — rename it to
`migration.tf` to activate it.

```hcl
locals {
  ifw_policy = jsondecode(file("./config_data/all_ifw_rules_and_sections.json")).data.policy.internetFirewall.policy
  # ... split into main sections/rules and sub-policy sections/rules ...
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
# (plus cato_if_sub_policy.sub_policies and cato_if_rule.sub_rules import blocks)
```

Each `import` block is keyed by object **name** and reads the **ID** straight from the
export — the declarative, previewable form of the `terraform import` command you ran
by hand in Exercise 2.

---

## Steps

```bash
# 1. Export the LIVE policy you want to adopt, into config_data/:
catocli export if_rules --json-filename all_ifw_rules_and_sections.json

# 2. Activate the import blocks (they ship parked):
mv migration.tf.parked migration.tf        # if not already a live migration.tf

terraform init          # pulls the registry module + provider
terraform plan          # read this carefully -- see below
```

**Expected result:** a clean adoption plan reads **`N to import, 0 to add, 0 to
change, 0 to destroy`**. That means every live rule/section is being adopted and
nothing is being rebuilt. Then:
```bash
terraform apply         # imports everything into state
rm migration.tf         # one-shot: delete after the first successful apply
```

---

## Why it matters

`import` blocks let you see exactly what will be adopted **before** touching the
tenant — keyed by object name, with IDs read from the export. After the first apply
the blocks have done their job and `migration.tf` is deleted; the policy is now
managed like any greenfield one (Exercise 3).

---

## Troubleshooting

- **Any `to add` or `to change` in the plan = your JSON is stale.** Re-export with
  `catocli` and diff; do **not** let Terraform overwrite live objects from an old
  backup. A correct adoption plan is imports only.
- *`to destroy` appears* → the module config doesn't match the live policy shape;
  re-export and confirm `rules_in_sections` ordering matches live.
- *Import address errors* (`...sections["X"]` not found) → the key must be the exact
  object name from the export; check the `for_each` locals against your JSON.
- *Provider/module won't resolve* → run under a clean `TF_CLI_CONFIG_FILE` with only
  `provider_installation { direct {} }` so the registry versions are used (not a local
  dev override from `~/.terraformrc`).

---

## Clean up

```bash
terraform destroy       # removes the adopted policy from the tenant -- dev only!
```

---

## What you learned

- `import` blocks are the declarative, previewable, at-scale form of `terraform import`.
- A clean brownfield plan is **imports only** — any add/change/destroy means stale data.
- The same bulk module serves greenfield (Exercise 3) and brownfield (here).

**Back to:** [Workshop index](../README.md).

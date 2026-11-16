# Exercise 3 — Bulk rules from a `catocli` export

**Goal:** deploy an entire **Internet Firewall policy** — every rule and section —
from a single JSON file, using a **published registry module** instead of writing one
resource per rule. This is how real policies are managed at scale.

> ⚠️ Dev sub-account only — never account 15412. Applying this writes a firewall
> policy to the target tenant. See the root [README](../README.md) for prerequisites
> and auth.

---

## The idea

1. Export a tenant's live IFW policy to JSON with `catocli`.
2. Hand that JSON to the `catonetworks/bulk-if-rules/cato` registry module.
3. `terraform apply` — the module creates all the rules + sections and preserves
   their order.

```
catocli export  ─▶  config_data/all_ifw_rules_and_sections.json  ─▶  module  ─▶  Cato tenant
```

This folder ships a **small sample** export (2 rules, 2 sections) so the exercise
runs without a live export. Replace it with a real one when you're ready.

---

## Prerequisites

- Terraform ≥ 1.5; auth configured (see **Authentication — choose one** below).
- `catocli` installed, to produce a real export (optional — a sample ships here).
- Provider `catonetworks/cato` **`= 2.0.0-prerelease.1`**, installed from the public
  Terraform Registry (no filesystem mirror). Pulled by `terraform init`.

---

## Authentication — choose one

This folder's `provider "cato"` block is inline in `main.tf`. The two styles below are
mutually exclusive — pick one.

**Option A — Terraform environment-variable (token) auth:** replace the provider block in
`main.tf` with:
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

**Option B — Cato CLI profile auth:**
```hcl
provider "cato" {
  profile = "your-cli-profile-name"
}
```
(creds resolved from `~/.cato/credentials`; requires catocli configured — see the root
README's 3.3.0 prerequisite.) The committed `main.tf` ships a **sample** profile
(`profile = "badev2"`) — change it to your own dev profile before running.

---

## Files

| File | What it's for |
|---|---|
| `main.tf` | Provider block + the module call, pointing it at the JSON |
| `config_data/all_ifw_rules_and_sections.json` | The exported policy (sample included) |
| `variables.tf` / `versions.tf` / (outputs are in `main.tf`) | Same skeleton as the other folders |

The module (`main.tf`):
```hcl
module "if_rules" {
  # Published registry module -- installed from the Terraform Registry (no mirror).
  source  = "catonetworks/bulk-if-rules/cato"
  version = "= 0.0.9"

  # Dev override (local clone):
  # source = "../../../../catonetworks/terraform-cato-bulk-if-rules"

  ifw_rules_json_file_path = "${path.module}/config_data/all_ifw_rules_and_sections.json"
}
```

The `v0.0.9` module has two inputs: the required **JSON path**
(`ifw_rules_json_file_path`) and an optional `section_to_start_after_id`. It takes
**no credentials** — it inherits the `cato` provider from `main.tf`. Module `0.0.9`
requires `cato >= 2.0.0-prerelease.1`, matching this folder's provider pin.

---

## JSON shape (what the module reads)

The module reads the path `data.policy.internetFirewall.policy`:
```jsonc
{ "data": { "policy": { "internetFirewall": { "policy": {
  "rules":              [ /* each: { audit, rule{...}, properties } */ ],
  "sections":           [ /* { section_index, section_name, section_id } */ ],
  "rules_in_sections":  [ /* { index_in_section, section_name, rule_name } */ ]
}}}}}
```

> **`rules_in_sections` controls ordering** — not the array order of `rules[]`. It
> maps each rule (by name) to a section and a position. Keep it in sync when you
> hand-edit the JSON.

---

## Steps

```bash
terraform init          # downloads the registry module + provider (from the registry)
terraform fmt
terraform validate
terraform plan          # Plan: N to add (2 rules + 2 sections from the sample)
terraform apply
terraform output deployment_summary
```

**Expected result:** the full sample policy (rules + sections) is created in the dev
tenant in one apply; `terraform output deployment_summary` prints the counts.

### Use a real export instead of the sample
```bash
# from a dev tenant you have a profile for:
catocli export if_rules --json-filename all_ifw_rules_and_sections.json
mv all_ifw_rules_and_sections.json config_data/
terraform plan          # now shows your real policy
```

---

## Safety: empty-policy guard

`v0.0.9` handles empty policies automatically (a dynamic guard), so no explicit
`allow_empty_policy` flag is wired here. The guard is a safety net: a truncated or
wrong-tenant export that reads as zero rules will not silently delete a live policy.
Still — always eyeball your JSON before applying.

---

## Clean up

```bash
terraform destroy
```

---

## Troubleshooting

- *`init` can't find the module/provider* → confirm you're online; the module and the
  `= 2.0.0-prerelease.1` provider both resolve from the public registry (no mirror
  needed). If you have a `~/.terraformrc` with `dev_overrides`/`filesystem_mirror`
  pointing at a local build, run with a clean `TF_CLI_CONFIG_FILE` that has only
  `provider_installation { direct {} }`.
- *Plan shows `0 to add` / "No changes"* → the JSON parsed empty, or the sample was
  already applied. Check `config_data/all_ifw_rules_and_sections.json`.
- *Transient API errors on apply* → add `-parallelism=1` (Cato's API prefers one
  change at a time).

---

## What you learned

- A registry module (`source` + pinned `version`) is downloaded by `terraform init`.
- One JSON export → a whole policy, instead of hand-writing each rule.
- Exports come from `catocli export if_rules`; `rules_in_sections` drives ordering.
- Dynamic guards protect live policies from empty / bad inputs.

**Next:** [Exercise 4 — Brownfield adoption at scale](../4-brownfield/README.md) uses
the *same* module to adopt an existing **live** policy into state via `import` blocks.

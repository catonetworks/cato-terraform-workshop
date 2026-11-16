# Optional extra — Modules & CSV

> Not one of the four core exercises — a companion to **Exercise 1**. Do it any time
> after Exercise 1.

**Goal:** take the `for_each` from Exercise 1, move it into a **reusable module**, and
drive it from a **CSV file** instead of inline HCL. This is the pattern that scales:
*config* (the module, written once) stays separate from *data* (the CSV, edited often).

> ⚠️ Dev sub-account only — never account 15412. See the root [README](../README.md)
> for prerequisites and auth. Uses provider `catonetworks/cato`
> **`= 2.0.0-prerelease.1`** from the public Terraform Registry (no mirror).

---

## What's here

```
2-module/
├── main.tf                 # the site + a call to the local module
├── data/hosts.csv          # the host DATA (edit this to add/remove hosts)
├── modules/static_hosts/   # the reusable module (the for_each lives here)
│   ├── variables.tf        # inputs:  hosts, site_id|site_name
│   ├── main.tf             # for_each cato_static_host
│   └── outputs.tf          # output:  host_ids
├── variables.tf / versions.tf   # provider block + root outputs live in main.tf
└── terraform.tfvars.example
```

A **module** is just a folder of `.tf` files with inputs (variables) and outputs.
The root module (`main.tf`) *calls* `./modules/static_hosts` and passes it data.
The module declares no provider — it inherits `cato` from the root.

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
(`profile = "badev4"`) — change it to your own dev profile before running.

---

## Run it

With auth set up (above), run:

```bash
terraform init          # also initializes the local module
terraform fmt
terraform validate
terraform plan          # Plan: 5 to add (1 site + 4 hosts from the CSV)
terraform apply
terraform output host_ids
```

### Add a host with data, not code
Append a row to `data/hosts.csv`:

```csv
printer-2,192.168.71.31,
```

```bash
terraform plan          # Plan: 1 to add -- just the new host
terraform apply
```

You changed **data**, not Terraform code. The module's `for_each` picked up the
new row automatically. `csvdecode(file("data/hosts.csv"))` turns each CSV row into
an object `{ name, ip, mac_address }` matching the module's `hosts` input.

> Blank `mac_address` cells are fine — the module converts `""` to "no DHCP
> reservation".

### Reference the site by name instead of id
The module also accepts `site_name` instead of `site_id` (set exactly one). That's
useful when the site already exists or when ids differ between tenants:

```hcl
module "static_hosts" {
  source    = "./modules/static_hosts"
  site_name = "demo-branch-site"
  hosts     = csvdecode(file("${path.module}/data/hosts.csv"))
}
```

---

## Clean up

```bash
terraform destroy
```

---

## What you learned

- A module packages reusable config behind **inputs** and **outputs**.
- Modules inherit the provider from the caller — they stay auth-agnostic.
- `csvdecode` + a module = data-driven infrastructure: edit a CSV, not HCL.

**Back to:** [Workshop index](../README.md). The core path continues at
[Exercise 3 — Bulk rules from a CLI export](../3-bulk-rules/README.md), which uses a
published registry module to deploy a whole Internet Firewall policy from a
`catocli` JSON export.

# Exercises 1 — Create resources, then import one

This folder holds the first two exercises. They share one `main.tf`:

1. **Exercise 1 — Create resources with Terraform** — build a socket site and some
   static hosts; meet `for_each`.
2. **Exercise 2 — Import one existing resource** — adopt the live site back into a
   fresh state with `terraform import`, without destroying/recreating it.

Do them in order: Exercise 2 adopts the site you create in Exercise 1.

---

## Authentication — choose one

This folder's `provider "cato"` block is inline at the top of `main.tf`. The two styles
below are mutually exclusive — pick one.

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

> Uses `catonetworks/cato` **`= 2.0.0-prerelease.1`**, installed from the public
> Terraform Registry (no filesystem mirror). `terraform init` pulls it.

---

## Files

| File | What it's for |
|---|---|
| `versions.tf` | Required Terraform + `catonetworks/cato` provider version (`= 2.0.0-prerelease.1`) |
| `variables.tf` | Auth inputs (`cato_token`, `account_id`, `cato_baseurl`) |
| `main.tf` | Provider block + the three stages (A/B/C) |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` and fill in creds |

---

## Exercise 1 — Create resources with Terraform

**Goal:** create your first Cato objects with Terraform, and learn how `for_each`
turns "copy-paste a resource N times" into one block driven by data.

**Prerequisites:** Terraform ≥ 1.5; auth configured (above).

**What you build, in three stages inside `main.tf`:**

1. **A** — one socket site (a single `resource "cato_socket_site" "demo"` block)
2. **B** — one static host on that site (`cato_static_host.printer`, which *references* the site)
3. **C** — several static hosts from **one** block using `for_each` over a local map

**Steps:**
```bash
terraform init          # download the provider (first run only)
terraform fmt           # tidy formatting
terraform validate      # syntax/type check -- no API calls
```

### Stage A — one resource
Open `main.tf`; comment out **Stage B** and **Stage C** so only the
`cato_socket_site "demo"` block remains.
```bash
terraform plan          # Plan: 1 to add
terraform apply
terraform output site_id
```
A `resource` block = one real object. `apply` makes reality match your file; the
resulting site ID is saved in `terraform.tfstate`.

### Stage B — a second, related resource
Uncomment the `cato_static_host "printer"` block.
```bash
terraform plan          # Plan: 1 to add (the host; the site is unchanged)
terraform apply
```
Notice `site_id = cato_socket_site.demo.id`. That reference creates an **implicit
dependency** — Terraform creates the site before the host.

### Stage C — many hosts with `for_each`
Uncomment the `locals { static_hosts = {...} }` and the `cato_static_host "many"` block.
```bash
terraform plan          # Plan: 3 to add (one per map entry)
terraform apply
terraform output foreach_host_ids
```
`for_each` stamps out one instance per map entry, keyed by name:
`cato_static_host.many["nas"]`, `["camera-1"]`, `["camera-2"]`.

> **Why a map, not a list?** Map keys give each instance a **stable address**. With a
> list, removing the first element renumbers everything after it, forcing needless
> destroy/recreate. Key by something stable (here, the host name).

**Expected result:** a `demo-branch-site-resource` site plus its static hosts exist
in the dev tenant, and `terraform.tfstate` records them with their real IDs.

**Why it matters:** `apply` reconciles file → reality; references create ordering
automatically; `for_each` replaces repetition with one data-driven block.

> **Leave this applied** — Exercise 2 adopts the site you just created. Do **not**
> `terraform destroy` until you've finished Exercise 2.

---

## Exercise 2 — Import one existing resource

**Goal:** adopt an object that already exists in the tenant into Terraform state
**without destroying and recreating it**. This is the single-resource building block
behind real brownfield adoption — what you reach for when an object was made outside
Terraform (in the Cato console, by another tool) or when local state was lost.

**Prerequisites:** You completed Exercise 1 and **applied** it, so the
`demo-branch-site-resource` site exists live. Capture its **site ID now**, while the
current state still has it:
```bash
terraform output site_id        # e.g. 123456  -- note this number
```
(You can also read the ID from the Cato console, or with `catocli`.)

**Steps:**

1. **Throw away the local state** — this simulates "Terraform doesn't know about this
   object." The site stays live in the tenant; only the local record is removed:
   ```bash
   rm -f terraform.tfstate terraform.tfstate.backup
   ```

2. **Re-initialize** the working directory:
   ```bash
   terraform init
   ```

3. **Import the site by its ID** into the resource address it occupies in `main.tf`.
   For `cato_socket_site` the import ID is the **plain numeric site ID** (the
   provider uses a passthrough import on the `id` attribute):
   ```bash
   terraform import cato_socket_site.demo <SITE_ID>
   ```
   Expected output shape:
   ```
   cato_socket_site.demo: Importing from ID "<SITE_ID>"...
   cato_socket_site.demo: Import prepared!
   cato_socket_site.demo: Refreshing state... [id=<SITE_ID>]

   Import successful!

   The resources that were imported are shown above...
   ```

4. **Confirm the import reconciled cleanly** — the site should need **no changes**,
   and crucially **no destroy/recreate**:
   ```bash
   terraform plan
   ```
   For the **site** you expect `0 to change, 0 to destroy` (ideally
   `No changes. Your infrastructure matches the configuration.`).

   If `main.tf` still has the Stage B/C static-host blocks uncommented, those hosts
   show up as `N to add` — you only imported the site, so the hosts aren't in state
   yet. That's expected: `import` brings in **one** resource at a time. For a fully
   clean plan, either comment the host blocks out, or import each host too.
   `cato_static_host` imports with the ID format `<site-id>/<host-id>`:
   ```bash
   terraform import 'cato_static_host.printer'      <SITE_ID>/<HOST_ID>
   terraform import 'cato_static_host.many["nas"]'  <SITE_ID>/<HOST_ID>
   ```

**Expected result:** the live site is back under Terraform management in a fresh state
file, and `terraform plan` shows the site is **not** scheduled for destroy/recreate —
proof the object was *adopted*, not rebuilt.

**Why it matters:** `terraform import` writes the live object into state and maps it to
a resource address in your config. When the config matches the live object, the next
plan is clean. This is the atomic version of Exercise 4's bulk brownfield adoption.

**Troubleshooting:**
- *Plan wants to destroy/recreate the site* → your `main.tf` doesn't match the live
  object. Diff the config against the Cato console and align the attributes before
  applying; never apply a destroy you didn't intend.
- *"Resource already managed by Terraform"* → state wasn't actually cleared; re-run
  the `rm -f terraform.tfstate*` step.
- *Import errors on the ID* → confirm you passed the bare numeric site ID (not a
  name, not a URL).

---

## Clean up

When you're done with both exercises:
```bash
terraform destroy
```

---

## What you learned

- A `resource` block manages one object; `apply` reconciles file → reality.
- References between resources create ordering (dependencies) automatically.
- `for_each` replaces repetition with one data-driven block, keyed by stable names.
- `terraform import` adopts a pre-existing object into state **without recreating it**.

**Next:** [Exercise 3 — Bulk rules from a CLI export](../3-bulk-rules/README.md)
deploys a whole Internet Firewall policy from a `catocli` JSON export via a bulk
module. (Optional detour: [Modules & CSV](../2-module/README.md).)

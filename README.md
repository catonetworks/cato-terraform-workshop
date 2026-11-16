# Cato + Terraform — Hands-on Training

A from-zero workshop for managing a Cato tenant with Terraform, in **four short,
runnable exercises** that build on each other. This page is the index: skim the
prerequisites once, then open the folder README for each exercise.

---

## The four exercises

| # | Exercise | Folder | One-line goal |
|---|---|---|---|
| **1** | Create resources with Terraform | [`1-resource/`](./1-resource/README.md) | Create a socket site + static hosts; meet `for_each`. |
| **2** | Import one existing resource | [`1-resource/`](./1-resource/README.md#exercise-2--import-one-existing-resource) | Adopt the live site into a fresh state with `terraform import` — no destroy/recreate. |
| **3** | Bulk policy from a `catocli` export | [`3-bulk-rules/`](./3-bulk-rules/README.md) | Deploy a whole Internet Firewall policy from one JSON export via a registry module. |
| **4** | Brownfield adoption at scale | [`4-brownfield/`](./4-brownfield/README.md) | Adopt an entire **live** policy into state with native `import` blocks (one-shot `migration.tf`). |

Exercises 1 and 2 share the `1-resource/` folder (Ex 2 re-adopts the site you build in
Ex 1). Exercises 3 and 4 use the *same* Internet-Firewall bulk module — first
greenfield, then brownfield.

> **Optional extra:** [`2-module/`](./2-module/README.md) — Modules & CSV, a companion
> to Exercise 1 (not one of the four core exercises).

### The learning arc
**Create** one object (Ex 1) → **adopt** one existing object (Ex 2) → **deploy** many
objects at once (Ex 3) → **adopt** many live objects at once (Ex 4). Each step
generalizes the previous: Ex 2's single `terraform import` becomes Ex 4's declarative
`import` blocks; Ex 1's hand-written resources become Ex 3's data-driven module.

---

## What is Terraform (and "infrastructure as code")?

Terraform lets you describe infrastructure in text files (`.tf`); the tool makes reality
match your declared **desired state** — version-controlled, reviewable, repeatable.
Concepts you'll meet: a **provider** (a plugin that talks to an API — here
`catonetworks/cato`), a **resource** (one managed object), **state**
(`terraform.tfstate`, Terraform's record of what it created — don't hand-edit it),
**import** (adopting a live object into state *without* recreating it — Exercises 2 & 4),
and a **module** (a reusable folder of `.tf` with inputs/outputs).

---

## Prerequisites (set up once)

**1. Terraform** ≥ 1.5 — https://developer.hashicorp.com/terraform/install

**2. The Cato provider** — every folder pins `catonetworks/cato` **`= 2.0.0-prerelease.1`**
(exact `=` pin, because Terraform excludes pre-releases from range operators). It
installs from the **public Terraform Registry** — `terraform init` pulls it, **no
filesystem mirror needed**. If your `~/.terraformrc` has `dev_overrides` or a
`filesystem_mirror` for a local provider build, run the workshop under a clean config
so the registry version is used:
```bash
# registry-only.tfrc
provider_installation { direct {} }
```
```bash
export TF_CLI_CONFIG_FILE=/path/to/registry-only.tfrc
```

**3. catocli** (Exercises 3 & 4 only) — the Cato CLI, configured with a dev profile,
used to export live policy JSON.

**4. Authentication** — each folder's `provider "cato"` block is **inline in its
`main.tf`** and supports two mutually-exclusive styles:

| Style | How | When |
|---|---|---|
| **catocli profile** (recommended) | Set `profile = "<your-dev-profile>"` in the `provider "cato"` block | Creds live in `~/.cato/credentials` |
| **Explicit token** | Uncomment the token block; `export TF_VAR_cato_token="R=..\|K=.."` + `export TF_VAR_account_id="<dev-id>"` | CI, or no catocli profile |

The committed `main.tf` files ship a **sample** profile (`badev4` / `badev2`) — change
it to your own dev profile before running. (For token auth you can instead copy
`terraform.tfvars.example` → `terraform.tfvars`, which is gitignored.)

**Verify:**
```bash
terraform version
catocli --version        # Exercises 3 & 4 only
```

---

## The core workflow

Each folder is self-contained — run these from **inside** it:

```bash
terraform init       # download the provider/modules (first run, or after version changes)
terraform validate   # syntax/type check -- no API calls, no creds needed
terraform plan       # preview what WOULD change (read-only)
terraform apply      # make it happen
terraform import     # adopt an existing object into state (Exercises 2 & 4)
terraform destroy    # remove everything this config created
```

Full per-step commands, expected output, and "why" live in each exercise's folder
README — start with [Exercise 1](./1-resource/README.md).

---

## Global troubleshooting

- **`init` won't resolve the provider / wrong version installed** → you likely have a
  local `dev_overrides` or `filesystem_mirror` in `~/.terraformrc`. Re-run under the
  clean `TF_CLI_CONFIG_FILE` shown in Prerequisites (`provider_installation { direct {} }`).
- **Lock-file mismatch after a version bump** → delete `.terraform.lock.hcl` and
  re-run `terraform init` (or `terraform providers lock -platform=...` for a
  multi-platform lock).
- **Transient API errors on a large apply** → Cato's API prefers one change at a time;
  add `-parallelism=1`.
- **A brownfield plan (Ex 4) shows `add`/`change`/`destroy`** → your exported JSON is
  stale. Re-export with `catocli` and diff; never overwrite live objects from an old
  backup.

---

## Housekeeping

- State, `*.tfvars`, `.terraform/`, and `.DS_Store` are gitignored by the root
  `.gitignore` — only `*.tfvars.example` and `.terraform.lock.hcl` are committed.
- Always `terraform destroy` an exercise when you're done to keep the dev tenant tidy
  (finish Exercises 1 → 2 together before destroying, since they share a folder).

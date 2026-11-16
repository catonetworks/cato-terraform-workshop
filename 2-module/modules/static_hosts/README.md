# Module: `static_hosts`

Creates one `cato_static_host` per entry in `var.hosts`, all on one site. It's the
Lesson-1 `for_each` extracted into a reusable, provider-agnostic module.

## Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `hosts` | `list(object({ name, ip, mac_address? }))` | yes | Hosts to create. |
| `site_id` | `string` | one of | Parent site by id. |
| `site_name` | `string` | one of | Parent site by name (resolved by the provider). |

Set **exactly one** of `site_id` / `site_name`.

## Outputs

| Name | Description |
|---|---|
| `host_ids` | Map of host name → created host id. |

## Example

```hcl
module "static_hosts" {
  source  = "./modules/static_hosts"
  site_id = cato_socket_site.demo.id
  hosts   = csvdecode(file("${path.module}/data/hosts.csv"))
}
```

## Notes

- Instances are keyed by host **name**, so adding/removing a host only affects
  that one instance.
- `mac_address` empty string (e.g. a blank CSV cell) is treated as "no DHCP
  reservation" (sent as null).
- The module declares no `provider` block — it inherits the `cato` provider from
  the root module that calls it.

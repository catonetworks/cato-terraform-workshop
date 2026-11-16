# One provider block that supports BOTH authentication styles:
#   1. catocli profile  -> set var.cato_profile (or `export CATO_PROFILE=<name>`)
#   2. explicit creds    -> set var.cato_token + var.account_id (or export CATO_TOKEN)

provider "cato" {
  profile = "badev4"
}

# # Auth Option 2 - api_token
# provider "cato" {
#   baseurl    = var.cato_baseurl
#   token      = var.cato_token
#   account_id = var.account_id
# }

data "cato_siteLocation" "ny" {
  filters = [
    {
      field     = "city"
      search    = "New York City"
      operation = "startsWith"
    },
    {
      field     = "state_name"
      search    = "New York"
      operation = "exact"
    },
    {
      field     = "country_name"
      search    = "United States"
      operation = "contains"
    }
  ]
}

# # The site is still a plain resource in the root module.
resource "cato_socket_site" "demo" {
  name            = "demo-branch-site-module"
  description     = "Training demo branch site"
  site_type       = "BRANCH"
  connection_type = "SOCKET_X1500"

  native_range = {
    native_network_range = "192.168.71.0/24"
    local_ip             = "192.168.71.1"
    dhcp_settings = {
      dhcp_type = "DHCP_RANGE"
      ip_range  = "192.168.71.10-192.168.71.100"
    }
  }

  site_location = {
    city         = data.cato_siteLocation.ny.locations[0].city
    country_code = data.cato_siteLocation.ny.locations[0].country_code
    state_code   = data.cato_siteLocation.ny.locations[0].state_code
    timezone     = data.cato_siteLocation.ny.locations[0].timezone[0]
    address      = "555 That Way"
  }
}

output "site_id" {
  description = "ID of the socket site."
  value       = cato_socket_site.demo.id
}

# # Call the local module. `source = "./modules/static_hosts"` points at the folder.
# # `csvdecode(file(...))` reads data/hosts.csv into a list of objects -- one per
# # row -- which matches the module's `hosts` input type. Add a CSV row => one more
# # host, with no HCL changes.
module "static_hosts" {
  source  = "./modules/static_hosts"
  site_id = cato_socket_site.demo.id
  hosts   = csvdecode(file("${path.module}/data/hosts.csv"))
}

output "host_ids" {
  description = "Map of host name -> id, surfaced from the static_hosts module."
  value       = module.static_hosts.host_ids
}

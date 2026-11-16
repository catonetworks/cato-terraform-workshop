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

# # ###########################################################################
# # Exercise 1 -- Resources & for_each
# # ###########################################################################

# # ---- Stage A: a single resource -- one socket site -----------------------
resource "cato_socket_site" "demo" {
  name            = "demo-branch-site-resource"
  description     = "Training demo branch site"
  site_type       = "BRANCH"       # BRANCH | DATACENTER | ...
  connection_type = "SOCKET_X1500" # the socket model for this site

  native_range = {
    native_network_range = "192.168.70.0/24" # the LAN subnet behind the socket
    local_ip             = "192.168.70.1"    # the socket's IP on that subnet
    dhcp_settings = {
      dhcp_type = "DHCP_RANGE"
      ip_range  = "192.168.70.10-192.168.70.100"
    }
  }

  site_location = {
    country_code = "US"
    timezone     = "America/New_York"
    state_code   = "US-NY"
  }
}

output "site_id" {
  description = "ID of the socket site created in Stage A."
  value       = cato_socket_site.demo.id
}


# # # ---- Stage B: a single related resource -- one static host ---------------
# resource "cato_static_host" "printer" {
#   site_id = cato_socket_site.demo.id
#   name    = "office-printer"
#   ip      = "192.168.70.10"
# }

# output "single_host_id" {
#   description = "ID of the single static host from Stage B."
#   value       = cato_static_host.printer.id
# }


# # # ---- Stage C: many hosts from ONE block using for_each -------------------
# locals {
#   static_hosts = {
#     "nas"      = { ip = "192.168.70.20", mac_address = "00:00:00:00:00:20" }
#     "camera-1" = { ip = "192.168.70.21", mac_address = null }
#     "camera-2" = { ip = "192.168.70.22", mac_address = null }
#   }
# }

# resource "cato_static_host" "many" {
#   for_each = local.static_hosts

#   site_id     = cato_socket_site.demo.id
#   name        = each.key # the map key -> host name
#   ip          = each.value.ip
#   mac_address = each.value.mac_address # null = no DHCP reservation
# }

# output "foreach_host_ids" {
#   description = "Map of host name -> id for the Stage C for_each hosts."
#   value       = { for name, host in cato_static_host.many : name => host.id }
# }

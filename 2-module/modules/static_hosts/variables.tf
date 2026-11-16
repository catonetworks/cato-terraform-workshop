# Inputs to the static_hosts module.
#
# Provide EXACTLY ONE of site_id or site_name to say which site the hosts belong
# to. site_name is handy for tenant-to-tenant reuse (ids differ, names are stable).

variable "site_id" {
  description = "ID of the parent site. Set this OR site_name (not both)."
  type        = string
  default     = null
}

variable "site_name" {
  description = "Name of the parent site (resolved to an id by the provider). Set this OR site_id (not both)."
  type        = string
  default     = null
}

variable "hosts" {
  description = "Hosts to create on the site. mac_address is optional (empty = no DHCP reservation)."
  type = list(object({
    name        = string
    ip          = string
    mac_address = optional(string, "")
  }))
}

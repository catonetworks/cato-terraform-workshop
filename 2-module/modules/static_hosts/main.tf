# This module is just the Lesson-1 for_each, packaged so any caller can reuse it.
# It owns NO provider config and NO site -- it only creates hosts on a site the
# caller points it at. That separation is what makes it reusable.

resource "cato_static_host" "this" {
  for_each = { for host in var.hosts : host.name => host }

  site_id   = var.site_id
  site_name = var.site_name
  name      = each.value.name
  ip        = each.value.ip
  # CSV empty cells arrive as "" -- coerce to null so no DHCP reservation is set.
  mac_address = try(each.value.mac_address, "") == "" ? null : each.value.mac_address
}

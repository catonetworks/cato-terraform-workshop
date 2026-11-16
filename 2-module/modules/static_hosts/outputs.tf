# Modules return values to their caller via outputs.
output "host_ids" {
  description = "Map of host name -> created static host id."
  value       = { for name, host in cato_static_host.this : name => host.id }
}

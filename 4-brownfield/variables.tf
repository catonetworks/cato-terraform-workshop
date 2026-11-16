# ---- Authentication (shared by every lesson) ----------------------------

variable "cato_profile" {
  description = <<-EOT
    catocli profile name from ~/.cato/credentials. Leave null and
    `export CATO_PROFILE=<name>` instead, or set it here. Mutually exclusive
    with cato_token/account_id. Point this at a DEV sub-account only.
  EOT
  type        = string
  default     = null
}

variable "cato_token" {
  description = "Cato API token (format R=<region>|K=<key>). Optional when using a profile. Also read from the CATO_TOKEN env var."
  type        = string
  sensitive   = true
  default     = null
}

variable "account_id" {
  description = "Cato account ID of your DEV sub-account. Optional when using a profile."
  type        = string
  default     = null
}

variable "cato_baseurl" {
  description = "Cato API endpoint. Also read from the CATO_BASEURL env var."
  type        = string
  default     = "https://api.catonetworks.com/api/v1/graphql2"
}

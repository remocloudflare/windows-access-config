variable "account_id" {
  description = "Cloudflare account ID that owns the Zero Trust organization."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token. Prefer CLOUDFLARE_API_TOKEN; this optional input exists for local terraform.tfvars and must never be committed."
  type        = string
  sensitive   = true
  default     = ""
}

variable "zone_id" {
  description = "Cloudflare zone ID for the browser RDP application hostname."
  type        = string
}

variable "windows_target_ips_file" {
  description = "Module-relative JSON file mapping stable Windows target names to IPv4 addresses."
  type        = string
  default     = "files/ips/windows-targets.json"
}

variable "default_windows_target_virtual_network_id" {
  description = "Default Cloudflare Zero Trust VNet UUID used by Windows targets."
  type        = string
}

variable "windows_target_virtual_network_ids" {
  description = "Optional per-target Cloudflare VNet overrides, keyed like the reusable Windows IP inventory."
  type        = map(string)
  default     = {}
}

variable "default_windows_target_access_profile" {
  description = "Default RDP access-profile key used by Windows targets."
  type        = string
  default     = "operators"
}

variable "windows_target_access_profiles" {
  description = "Optional per-target access-profile overrides, keyed like the reusable Windows IP inventory."
  type        = map(string)
  default     = {}
}

variable "default_windows_target_tags" {
  description = "Tags applied to every Windows RDP infrastructure target."
  type        = map(string)
  default = {
    protocol = "rdp"
    platform = "windows"
    managed  = "terraform"
  }
}

variable "windows_target_tags" {
  description = "Optional per-target tags merged with default_windows_target_tags, keyed like the Windows target inventory."
  type        = map(map(string))
  default     = {}
}

variable "rdp_access_profiles" {
  description = "Reusable authorization and session settings. Servers sharing a profile share one RDP Access application."
  type = map(object({
    application_name                  = string
    application_domain                = string
    ports                             = optional(set(number), [3389])
    allowed_emails                    = optional(set(string), [])
    allowed_group_ids                 = optional(set(string), [])
    clipboard_local_to_remote_formats = optional(list(string), [])
    clipboard_remote_to_local_formats = optional(list(string), [])
  }))

  validation {
    condition = length(var.rdp_access_profiles) > 0 && alltrue([
      for profile in values(var.rdp_access_profiles) :
      length(split(".", profile.application_domain)) >= 2 &&
      length(profile.ports) > 0 &&
      alltrue([for port in profile.ports : port >= 1 && port <= 65535]) &&
      (length(profile.allowed_group_ids) > 0 || length(profile.allowed_emails) > 0)
    ])
    error_message = "Each profile needs an FQDN, at least one valid port, and at least one allowed email or Entra group ID."
  }
}

variable "manage_entra_idp" {
  description = "Create the Entra identity provider in this project. False reuses existing_entra_idp_id."
  type        = bool
  default     = false
}

variable "existing_entra_idp_id" {
  description = "Existing Cloudflare Access Entra identity provider ID. Required when manage_entra_idp=false."
  type        = string
  default     = ""

  validation {
    condition     = var.manage_entra_idp || can(regex("^[0-9a-fA-F-]{36}$", var.existing_entra_idp_id))
    error_message = "Set existing_entra_idp_id to an existing Entra IdP UUID or set manage_entra_idp=true."
  }
}

variable "entra_idp_name" {
  description = "Display name used when this project creates the Entra identity provider."
  type        = string
  default     = "Microsoft Entra ID"
}

variable "entra_client_id" {
  description = "Entra application client ID. Required only when manage_entra_idp=true."
  type        = string
  default     = ""
}

variable "entra_client_secret" {
  description = "Entra application client secret. Required only when manage_entra_idp=true."
  type        = string
  sensitive   = true
  default     = ""
}

variable "entra_directory_id" {
  description = "Entra directory (tenant) ID. Required only when manage_entra_idp=true."
  type        = string
  default     = ""
}

variable "entra_email_claim_name" {
  description = "Entra ID-token claim Cloudflare uses as the user email/UPN."
  type        = string
  default     = "preferred_username"
}

variable "create_dns_records" {
  description = "Create proxied placeholder A records for all browser-rendered RDP profiles."
  type        = bool
  default     = true
}

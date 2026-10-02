variable "account_id" {
  description = "Cloudflare account ID that owns the Zero Trust organization."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID for the browser RDP application hostname."
  type        = string
}

variable "application_domain" {
  description = "Public hostname users open for browser-based RDP, for example rdp.example.com."
  type        = string

  validation {
    condition     = length(split(".", var.application_domain)) >= 2
    error_message = "application_domain must be a fully qualified hostname."
  }
}

variable "target_hostname" {
  description = "Logical Access target name. This is a selector, not DNS."
  type        = string
  default     = "remo-win-vm"
}

variable "target_ipv4" {
  description = "Windows server IP reachable through the selected Cloudflare Tunnel private route."
  type        = string
  default     = "10.168.0.27"

  validation {
    condition     = can(cidrhost("${var.target_ipv4}/32", 0))
    error_message = "target_ipv4 must be a valid IPv4 address."
  }
}

variable "virtual_network_id" {
  description = "Cloudflare Zero Trust virtual-network UUID on the Tunnel CIDR route that covers target_ipv4. This is not an Azure VNet, GCP VPC, or Proxmox network ID. Leave null only when the matching route uses the account default Cloudflare virtual network."
  type        = string
  default     = null
  nullable    = true
}

variable "rdp_port" {
  description = "RDP listening port on the Windows server."
  type        = number
  default     = 3389

  validation {
    condition     = var.rdp_port >= 1 && var.rdp_port <= 65535
    error_message = "rdp_port must be between 1 and 65535."
  }
}

variable "entra_allowed_emails" {
  description = "Exact Entra user email/UPN values allowed when entra_allowed_group_ids is empty."
  type        = set(string)

  validation {
    condition     = length(var.entra_allowed_group_ids) > 0 || (length(var.entra_allowed_emails) > 0 && alltrue([for email in var.entra_allowed_emails : can(regex("^[^@ ]+@[^@ ]+[.][^@ ]+$", email))]))
    error_message = "Provide at least one valid entra_allowed_email or Entra group object ID."
  }
}

variable "entra_allowed_group_ids" {
  description = "Optional Entra security group object IDs allowed to launch RDP. When set, group membership replaces the email allowlist."
  type        = set(string)
  default     = []
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

variable "create_dns_record" {
  description = "Create the proxied placeholder A record required by browser-rendered RDP."
  type        = bool
  default     = true
}

variable "application_name" {
  description = "Access application display name."
  type        = string
  default     = "Windows RDP"
}

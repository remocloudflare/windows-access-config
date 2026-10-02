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
  description = "Cloudflare Tunnel virtual network ID containing the route to target_ipv4. Leave null to use the account default virtual network."
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

variable "allowed_emails" {
  description = "Exact user email addresses allowed to launch the RDP session."
  type        = set(string)

  validation {
    condition     = length(var.allowed_emails) > 0 && alltrue([for email in var.allowed_emails : can(regex("^[^@ ]+@[^@ ]+[.][^@ ]+$", email))])
    error_message = "Provide at least one valid email address."
  }
}

variable "allowed_idp_ids" {
  description = "Optional Access identity provider IDs. Empty permits all account IdPs. Use one ID with auto_redirect_to_identity=true."
  type        = set(string)
  default     = []
}

variable "auto_redirect_to_identity" {
  description = "Skip the IdP picker. Requires exactly one allowed_idp_ids entry."
  type        = bool
  default     = false

  validation {
    condition     = !var.auto_redirect_to_identity || length(var.allowed_idp_ids) == 1
    error_message = "auto_redirect_to_identity requires exactly one allowed_idp_ids entry."
  }
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

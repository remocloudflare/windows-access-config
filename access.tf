resource "cloudflare_zero_trust_access_infrastructure_target" "windows" {
  account_id = var.account_id
  hostname   = var.target_hostname

  ip = {
    ipv4 = {
      ip_addr            = var.target_ipv4
      virtual_network_id = var.virtual_network_id
    }
  }
}

resource "cloudflare_zero_trust_access_application" "windows_rdp" {
  account_id = var.account_id
  name       = var.application_name
  type       = "rdp"
  domain     = var.application_domain

  app_launcher_visible      = true
  allowed_idps              = [local.entra_idp_id]
  auto_redirect_to_identity = true

  target_criteria = [{
    port     = var.rdp_port
    protocol = "RDP"
    target_attributes = {
      hostname = [cloudflare_zero_trust_access_infrastructure_target.windows.hostname]
    }
  }]

  policies = [{
    name       = "Allow approved Entra users"
    decision   = "allow"
    precedence = 1
    include = length(var.entra_allowed_group_ids) > 0 ? local.entra_group_rules : [for email in sort(tolist(var.entra_allowed_emails)) : {
      email = { email = email }
    }]
    connection_rules = {
      rdp = {
        # Secure default: no clipboard transfer in either direction.
        allowed_clipboard_local_to_remote_formats = []
        allowed_clipboard_remote_to_local_formats = []
      }
    }
  }]
}

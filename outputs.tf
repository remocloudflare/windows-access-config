output "access_applications" {
  description = "Created browser-RDP applications keyed by access profile."
  value = {
    for key, app in cloudflare_zero_trust_access_application.windows_rdp : key => {
      id  = app.id
      url = "https://${var.rdp_access_profiles[key].application_domain}"
    }
  }
}

output "infrastructure_targets" {
  description = "Created Windows targets keyed by server name."
  value = {
    for key, target in cloudflare_zero_trust_access_infrastructure_target.windows : key => {
      id                 = target.id
      hostname           = target.hostname
      ipv4               = var.rdp_servers[key].ipv4
      virtual_network_id = var.rdp_servers[key].virtual_network_id
      access_profile     = var.rdp_servers[key].access_profile
    }
  }
}
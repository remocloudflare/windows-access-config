locals {
  target_hostnames_by_profile = {
    for profile_key, profile in var.rdp_access_profiles :
    profile_key => sort([
      for server_key, server in var.rdp_servers : server.hostname
      if server.access_profile == profile_key
    ])
  }

  profile_email_rules = {
    for profile_key, profile in var.rdp_access_profiles :
    profile_key => [for email in sort(tolist(profile.allowed_emails)) : {
      email = { email = email }
    }]
  }

  profile_group_rules = {
    for profile_key, profile in var.rdp_access_profiles :
    profile_key => [for group_id in sort(tolist(profile.allowed_group_ids)) : {
      azure_ad = {
        identity_provider_id = local.entra_idp_id
        id                   = group_id
      }
    }]
  }
}

resource "cloudflare_zero_trust_access_infrastructure_target" "windows" {
  for_each = var.rdp_servers

  account_id = var.account_id
  hostname   = each.value.hostname

  ip = {
    ipv4 = {
      ip_addr            = each.value.ipv4
      virtual_network_id = each.value.virtual_network_id
    }
  }
}

resource "cloudflare_zero_trust_access_application" "windows_rdp" {
  for_each = var.rdp_access_profiles

  account_id = var.account_id
  name       = each.value.application_name
  type       = "rdp"
  domain     = each.value.application_domain

  app_launcher_visible      = true
  allowed_idps              = [local.entra_idp_id]
  auto_redirect_to_identity = true

  target_criteria = [for port in sort(tolist(each.value.ports)) : {
    port     = port
    protocol = "RDP"
    target_attributes = {
      hostname = [for server_key, server in cloudflare_zero_trust_access_infrastructure_target.windows : server.hostname if var.rdp_servers[server_key].access_profile == each.key]
    }
  }]

  policies = [{
    name       = "Allow approved Entra users"
    decision   = "allow"
    precedence = 1
    include    = length(each.value.allowed_group_ids) > 0 ? local.profile_group_rules[each.key] : local.profile_email_rules[each.key]
    connection_rules = {
      rdp = {
        allowed_clipboard_local_to_remote_formats = each.value.clipboard_local_to_remote_formats
        allowed_clipboard_remote_to_local_formats = each.value.clipboard_remote_to_local_formats
      }
    }
  }]

  lifecycle {
    precondition {
      condition     = length(local.target_hostnames_by_profile[each.key]) > 0
      error_message = "Each rdp_access_profiles entry must be referenced by at least one rdp_servers entry."
    }
  }
}
resource "cloudflare_zero_trust_access_identity_provider" "entra" {
  count = var.manage_entra_idp ? 1 : 0

  account_id = var.account_id
  name       = var.entra_idp_name
  type       = "azureAD"

  config = {
    client_id        = var.entra_client_id
    client_secret    = var.entra_client_secret
    directory_id     = var.entra_directory_id
    support_groups   = true
    pkce_enabled     = true
    email_claim_name = var.entra_email_claim_name
  }

  lifecycle {
    precondition {
      condition     = var.entra_client_id != "" && var.entra_client_secret != "" && var.entra_directory_id != ""
      error_message = "manage_entra_idp=true requires entra_client_id, entra_client_secret, and entra_directory_id."
    }
  }
}

locals {
  entra_idp_id = var.manage_entra_idp ? cloudflare_zero_trust_access_identity_provider.entra[0].id : var.existing_entra_idp_id
  entra_group_rules = [for group_id in sort(tolist(var.entra_allowed_group_ids)) : {
    azure_ad = {
      identity_provider_id = local.entra_idp_id
      id                   = group_id
    }
  }]
}

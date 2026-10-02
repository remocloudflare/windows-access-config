output "access_application_id" {
  description = "Cloudflare Access application ID."
  value       = cloudflare_zero_trust_access_application.windows_rdp.id
}

output "infrastructure_target_id" {
  description = "Cloudflare Access infrastructure target ID."
  value       = cloudflare_zero_trust_access_infrastructure_target.windows.id
}

output "application_url" {
  description = "Browser RDP application base URL. Use the App Launcher to select the target."
  value       = "https://${var.application_domain}"
}

output "target" {
  description = "Configured Windows target."
  value = {
    hostname = var.target_hostname
    ipv4     = var.target_ipv4
    port     = var.rdp_port
  }
}

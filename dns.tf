resource "cloudflare_dns_record" "rdp" {
  for_each = var.create_dns_records ? var.rdp_access_profiles : {}

  zone_id = var.zone_id
  name    = each.value.application_domain
  type    = "A"
  content = "240.0.0.0"
  ttl     = 1
  proxied = true

  comment = "Placeholder record for Cloudflare Access browser-based RDP"
}
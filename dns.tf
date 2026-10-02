resource "cloudflare_dns_record" "rdp" {
  count = var.create_dns_record ? 1 : 0

  zone_id = var.zone_id
  name    = var.application_domain
  type    = "A"
  content = "240.0.0.0"
  ttl     = 1
  proxied = true

  comment = "Placeholder record for Cloudflare Access browser-based RDP"
}

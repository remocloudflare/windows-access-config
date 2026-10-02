terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.26"
    }
  }
}

provider "cloudflare" {
  # Prefer CLOUDFLARE_API_TOKEN. This fallback permits an ignored tfvars value.
  api_token = var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
}

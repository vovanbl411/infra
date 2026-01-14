# providers.tf
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Или если используете API ключ:
provider "cloudflare" {
  api_key    = var.cloudflare_api_key
  email      = var.cloudflare_email
}

# variables.tf
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}
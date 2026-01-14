# providers.tf
# Provider для CloudFlare
provider "cloudflare" {
  api_token = var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
  
  # Указываем, что этот провайдер использует тот же источник, что и в required_providers
  # В данном случае, alias не требуется, но мы можем попробовать добавить его для ясности
}
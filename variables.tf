variable "domain_name" {
  description = "Your domain name for DNS records"
  type        = string
  default     = "vovanbl411.qzz.io" # Замените на ваш домен
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "my-k8s-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.34.3+k0s.0"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "location" {
  description = "Location for resources"
  type        = string
  default     = "ru-1"
}

variable "availability_zone" {
  description = "Availability zone for servers and floating IPs"
  type        = string
  default     = "spb-3"
}

variable "vpc_subnet" {
  description = "VPC subnet in CIDR notation"
  type        = string
  default     = "192.168.0.0/16"
}

# Переменные для CloudFlare (для локального тестирования)
variable "cloudflare_api_token" {
  description = "CloudFlare API token (для локального тестирования через файл)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "CloudFlare Account ID для доступа к R2"
  type        = string
  default     = ""
}

# Переменные для провайдеров (добавляем недостающие)
variable "timeweb_token" {
  description = "Timeweb Cloud API Token"
  type        = string
  default     = ""
  sensitive   = true
}
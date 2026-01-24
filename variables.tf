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

# Параметры master_cpu, master_ram, master_disk, worker_cpu, worker_ram, worker_disk
# больше не используются для Kubernetes пресетов, так как приводили к ошибке
# "no Presets with provided properties found". Вместо этого используются
# доступные пресеты типа "master" и "worker" без дополнительных фильтров.

# Эти переменные можно использовать для других ресурсов, если понадобится
variable "master_cpu" {
  description = "CPU count for master node (не используется для k8s пресетов)"
  type        = number
  default     = 1
}

variable "master_ram" {
  description = "RAM size for master node in MB (не используется для k8s пресетов)"
  type        = number
  default     = 2048
}

variable "master_disk" {
  description = "Disk size for master node in MB (не используется для k8s пресетов)"
  type        = number
  default     = 30000
}

variable "worker_cpu" {
  description = "CPU count for worker nodes (не используется для k8s пресетов)"
  type        = number
  default     = 1
}

variable "worker_ram" {
  description = "RAM size for worker nodes in MB (не используется для k8s пресетов)"
  type        = number
  default     = 2048
}

variable "worker_disk" {
  description = "Disk size for worker nodes in MB (не используется для k8s пресетов)"
  type        = number
  default     = 30000
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
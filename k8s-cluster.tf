# VPC для кластера Kubernetes
resource "twc_vpc" "k8s_vpc" {
  name        = var.cluster_name
  description = "VPC for Kubernetes cluster"
  subnet_v4   = var.vpc_subnet
  location    = var.location
}

# Kubernetes кластер (мастер-нода)
data "twc_k8s_preset" "master_preset" {
  type = "master"
}

resource "twc_k8s_cluster" "k8s_cluster" {
  name        = var.cluster_name
  description = "Kubernetes cluster with 1 master and ${var.worker_count} workers"

  high_availability = false
  version           = var.k8s_version
  network_driver    = "flannel"
  ingress           = false

  preset_id  = data.twc_k8s_preset.master_preset.id
  network_id = twc_vpc.k8s_vpc.id
}

# Группа воркер-нод
data "twc_k8s_preset" "worker_preset" {
  type = "worker"
}

resource "twc_k8s_node_group" "worker_nodes" {
  cluster_id = twc_k8s_cluster.k8s_cluster.id
  name       = "worker-nodes"

  preset_id  = data.twc_k8s_preset.worker_preset.id
  node_count = var.worker_count

  # Авто-масштабирование (опционально)
  is_autoscaling = false
  # min_size = 2
  # max_size = 5
}

# CloudFlare DNS записи
data "cloudflare_zone" "domain" {
  name = var.domain_name
}

# resource "cloudflare_record" "k8s_api" {
#   zone_id = data.cloudflare_zone.domain.id
#   name    = "k8s-api"
#   value   = twc_floating_ip.cluster_api_ip.ip
#   type    = "A"
#   ttl     = 300
# }

# resource "cloudflare_record" "apps_wildcard" {
#   zone_id = data.cloudflare_zone.domain.id
#   name    = "*.apps"
#   value   = twc_floating_ip.cluster_api_ip.ip
#   type    = "A"
#   ttl     = 300
# }

# Вывод информации о кластере
output "cluster_id" {
  value       = twc_k8s_cluster.k8s_cluster.id
  description = "ID of the Kubernetes cluster"
}

output "cluster_name" {
  value       = twc_k8s_cluster.k8s_cluster.name
  description = "Name of the Kubernetes cluster"
}

output "cluster_status" {
  value       = twc_k8s_cluster.k8s_cluster.status
  description = "Status of the Kubernetes cluster"
}

output "raw_cluster_data" {
  value = twc_k8s_cluster.k8s_cluster
  sensitive = true # На всякий случай, если там есть токены
}

# Генерация Inventory файла для Ansible
resource "local_file" "ansible_inventory" {
  content = <<EOT
[all:vars]
cluster_id=${twc_k8s_cluster.k8s_cluster.id}
cluster_name=${twc_k8s_cluster.k8s_cluster.name}

[master]
# Если Timeweb не отдает IP напрямую, используем имя, 
# но для Ansible лучше всего подходит IP управления.
${twc_k8s_cluster.k8s_cluster.name}
EOT
  filename = "${path.module}/inventory.ini"
}


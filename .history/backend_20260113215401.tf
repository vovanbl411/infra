terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "kubernetes-cluster/terraform.tfstate"
    region         = "auto"
    
    # Эти параметры будем передавать при инициализации
    # endpoint, access_key, secret_key - через -backend-config
  }
}
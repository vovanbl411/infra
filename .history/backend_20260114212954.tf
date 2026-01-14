terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "kubernetes-cluster/terraform.tfstate"
    
    # Настройки для R2
    endpoints.s3 = "https://<ACCOUNT_ID>.r2.cloudflarestorage.com"
    
    # Эти параметры необходимы для R2
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    force_path_style            = true
 }
}
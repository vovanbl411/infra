terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "kubernetes/terraform.tfstate"
    region = "us-east-1"

    endpoint = "https://<ACCOUNT_ID>.r2.cloudflarestorage.com"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    use_path_style              = true
  }
}
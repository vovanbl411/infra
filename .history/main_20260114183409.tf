terraform {
  required_providers {
    twc = {
      source = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.13"
}

# Provider для Timeweb Cloud
provider "twc" {
  token = file("token.txt")
}

data "twc_configurator" "configurator" {
  location = "ru-1"
  preset_type = "standard"
}

data "twc_os" "os" {
  name = "ubuntu"
  version = "22.04"
}
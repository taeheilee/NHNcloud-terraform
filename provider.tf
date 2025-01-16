terraform {
required_version = ">= 1.0.0"
  required_providers {
    nhncloud = {
      source  = "nhn-cloud/nhncloud"
      version = "1.0.2"
    }
  }
}

# Configure the nhncloud Provider
provider "nhncloud" {
  user_name   = "${var.username}"
  tenant_id   = "${var.tenantid}"
  password    = "${var.Password}"
  auth_url    = "${var.authurl}"
  region      = "${var.Region}"
}
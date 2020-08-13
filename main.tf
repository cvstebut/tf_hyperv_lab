terraform {
  backend "azurerm" {}
  required_providers {
    hyperv = {
        source = "github.com/taliesins/hyperv"
        version = "1.0.0"
    }
  } 
}

resource "hyperv_network_switch" "lab_switch" {
    name = "demo2"
}
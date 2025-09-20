terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.44.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
  subscription_id = "17c4e02b-4d12-4506-b997-5bdd24cebb5f"
}
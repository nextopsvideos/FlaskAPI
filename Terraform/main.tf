terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.70.0"
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
provider "azurerm" {
  features {} 
  client_id       = "f61baffe-d1f5-4c01-b603-27083426549f"
  client_secret   = "EV~8Q~MXDeUvv-WYvCf3gNUyk3ERY6WvEDZE4aqW"
  tenant_id       = "68033575-d28e-41d3-9fa8-32299b023e7d"
  subscription_id = "5ef4e654-5b34-4650-9755-1d4297258e0c"
}


resource "azurerm_resource_group" "nextopsrg" {
  name     = "NextOps"
  location = "East US"
}

resource "azurerm_container_registry" "nextopsacr" {
  name                     = "nextopsacr10"
  resource_group_name      = azurerm_resource_group.nextopsrg.name
  location                 = azurerm_resource_group.nextopsrg.location
  sku                      = "Standard"
  admin_enabled            = true
}

resource "azurerm_virtual_network" "nextopsvnet" {
  name                = "nextopsvnet01"
  address_space       = ["10.0.0.0/16"]
  location                 = azurerm_resource_group.nextopsrg.location
  resource_group_name      = azurerm_resource_group.nextopsrg.name
}

resource "azurerm_subnet" "subnet01" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.nextopsrg.name
  virtual_network_name = azurerm_virtual_network.nextopsvnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_container_group" "nextopsaci" {
  name                        = "nextopsaci10"
  location                    = azurerm_resource_group.nextopsrg.location
  resource_group_name         = azurerm_resource_group.nextopsrg.name
  ip_address_type             = "Private"
  os_type                     = "Linux"
  subnet_ids                  = [azurerm_subnet.subnet01.id]

  container {
    name   = "container-one"
    image  = "mcr.microsoft.com/azuredocs/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

resource "azurerm_public_ip" "albpip01" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.nextopsrg.location
  resource_group_name = azurerm_resource_group.nextopsrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "nextopsalb" {
  name                = "nextopsalb10"
  location            = azurerm_resource_group.nextopsrg.location
  resource_group_name = azurerm_resource_group.nextopsrg.name
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.albpip01.id
  }
}

resource "azurerm_lb_probe" "probe01" {
  loadbalancer_id = azurerm_lb.nextopsalb.id
  name            = "probe01"
  port            = 80
}

resource "azurerm_lb_backend_address_pool" "bep01" {
  loadbalancer_id = azurerm_lb.nextopsalb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_backend_address_pool_address" "bepaddr01" {
  name                    = "nextopaci10"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bep01.id
  virtual_network_id      = azurerm_virtual_network.nextopsvnet.id
  ip_address              = azurerm_container_group.nextopsaci.ip_address

  depends_on = [ azurerm_container_group.nextopsaci ]
}

resource "azurerm_lb_rule" "rule01" {
  loadbalancer_id                = azurerm_lb.nextopsalb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.bep01.id]
  probe_id = azurerm_lb_probe.probe01.id
}
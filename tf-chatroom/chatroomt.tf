terraform {                                                                                                    
  required_providers {                                                                                         
    azurerm = {                                                                                                
      source = "hashicorp/azurerm"                                                                             
      version = "2.50"                                                                                         
    }                                                                                                          
  }                                                                                                            
}                                                                                                              
provider "azurerm" {                                                                                           
  features {}                                                                                                  
}                                                                                                              
resource "azurerm_resource_group" "chatroom-az1" {                                                                  
  name = "chatroom-az1"                                                                                        
  location = "chinaeast2"                                                                                      
}                                                                                                                                                                                                                    
                                                                                                               
resource "azurerm_virtual_network" "chatroom-az1-vnet" {                                                               
  name                = "chatroom-az1-vnet"                                                                          
  resource_group_name = azurerm_resource_group.chatroom-az1.name                                                    
  address_space       = ["55.24.100.0/23","15.24.100.0/23","115.24.100.0/23","125.24.100.0/23","135.24.100.0/23"]                                                                     
  location            = azurerm_resource_group.chatroom-az1.location                                                
}                                                                                                              
                                                                                                         
resource "azurerm_subnet" "frontend" {                                                                         
  name                 = "frontend"                                                                            
  resource_group_name  = azurerm_resource_group.chatroom-az1.name                                                   
  virtual_network_name = azurerm_virtual_network.chatroom-az1-vnet.name                                                  
  address_prefixes     = ["55.24.100.0/24"]                                                                    
}                                                                                                              
                                                                                                               
                                                                                                               
                                                                                                               
resource "azurerm_public_ip" "chatroom-prepose-pip" {                                                                       
  name                = "chatroom-prepose-pip"                                                                         
  sku                 = "Standard"                                                                             
  resource_group_name = azurerm_resource_group.chatroom-az1.name                                                    
  location            = azurerm_resource_group.chatroom-az1.location                                                
  allocation_method   = "Static"                                                                               
}                                                                                                              

resource "azurerm_public_ip" "chatroom-dispatch-pip" {                                                                       
  name                = "chatroom-dispatch-pip"                                                                         
  sku                 = "Standard"                                                                             
  resource_group_name = azurerm_resource_group.chatroom-az1.name                                                    
  location            = azurerm_resource_group.chatroom-az1.location                                                
  allocation_method   = "Static"                                                                               
}        

#&nbsp;since these variables are re-used - a locals block makes this more maintainable                         
locals {                                                                                                       
  backend_address_pool_name      = "${azurerm_virtual_network.chatroom-az1-vnet.name}-beap"                              
  frontend_port_name             = "${azurerm_virtual_network.chatroom-az1-vnet.name}-feport"                            
  frontend_ip_configuration_name = "${azurerm_virtual_network.chatroom-az1-vnet.name}-feip"                              
  http_setting_name              = "${azurerm_virtual_network.chatroom-az1-vnet.name}-be-htst"                           
  listener_name                  = "${azurerm_virtual_network.chatroom-az1-vnet.name}-httplstn"                          
  request_routing_rule_name      = "${azurerm_virtual_network.chatroom-az1-vnet.name}-rqrt"                              
  redirect_configuration_name    = "${azurerm_virtual_network.chatroom-az1-vnet.name}-rdrcfg"                            
}                                                                                                              
                                                                                                               
resource "azurerm_application_gateway" "chatroom-prepose-gw" {                                                             
  name                = "chatroom-prepose-gw"                                                                  
  resource_group_name = azurerm_resource_group.chatroom-az1.name                                                    
  location            = azurerm_resource_group.chatroom-az1.location                                                
                                                                                                               
  sku {                                                                                                        
    name     = "Standard_v2"                                                                                   
    tier     = "Standard_v2"                                                                                   
    capacity = 2                                                                                               
  }                                                                                                            
                                                                                                               
  gateway_ip_configuration {                                                                                   
    name      = "prepose-gateway-ip-configuration"                                                                  
    subnet_id = azurerm_subnet.frontend.id                                                                     
  }                                                                                                            
                                                                                                               
  frontend_port {                                                                                              
    name = local.frontend_port_name                                                                            
    port = 80                                                                                            
  }                                                                                                            
                                                                                                               
  frontend_ip_configuration {                                                                                  
    name                 = local.frontend_ip_configuration_name                                                
    public_ip_address_id = azurerm_public_ip.chatroom-prepose-pip.id                                                        
  }                                                                                                            
                                                                                                               
  backend_address_pool {                                                                                       
    name = local.backend_address_pool_name                                                                     
  }                                                                                                            
                                                                                                               
  backend_http_settings {                                                                                      
    name                  = local.http_setting_name                                                            
    cookie_based_affinity = "Enabled"                                                                          
    path                  = "/path1/"                                                                          
    port                  = 80                                                                                
    protocol              = "Http"                                                                             
    request_timeout       = 60                                                                                 
  }                                                                                                            
                                                                                                               
  http_listener {                                                                                              
    name                           = local.listener_name                                                       
    frontend_ip_configuration_name = local.frontend_ip_configuration_name                                      
    frontend_port_name             = local.frontend_port_name                                                  
    protocol                       = "Http"                                                                    
  }                                                                                                            
                                                                                                               
  request_routing_rule {                                                                                       
    name                       = local.request_routing_rule_name                                               
    rule_type                  = "Basic"                                                                       
    http_listener_name         = local.listener_name                                                           
    backend_address_pool_name  = local.backend_address_pool_name                                               
    backend_http_settings_name = local.http_setting_name                                                       
  }                                                                                                            
}                                                                                                              
   
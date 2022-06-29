
# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "test-RG" {
    name     = "${var.resource_group_name}"
    location = "${var.location}"
}

# Create virtual network
resource "azurerm_virtual_network" "test-Vnet" {
    name                = "${var.vnet_name}"
    address_space       = ["${var.address_space}"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.test-RG.name}"

}

# Create subnet
resource "azurerm_subnet" "test-subnet" {
    name                 = "${var.subnet1_name}"
    resource_group_name  = "${azurerm_resource_group.test-RG.name}"
    virtual_network_name = "${azurerm_virtual_network.test-Vnet.name}"
    address_prefixes       = ["10.0.1.0/24"]
}



# Create public IPs
resource "azurerm_public_ip" "test-publicIP" {
    name                         = "Public-Ip"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.test-RG.name}"
    allocation_method            = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "test-NSG" {
    name                = "${var.NSG-name1}"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.test-RG.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 2000
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "test-NIC" {
    name                      = "${var.NIC-name1}"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.test-RG.name}"
    

    ip_configuration {
        name                          = "Nic-Config"
        subnet_id                     = "${azurerm_subnet.test-subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.test-publicIP.id}"
    }

}


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "test-Storage-account" {
    name                        = "${var.Storage-name1}"
    resource_group_name         = "${azurerm_resource_group.test-RG.name}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

# Create virtual machine
resource "azurerm_virtual_machine" "test-Vm" {
    name                  = "${var.vm_name}"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.test-RG.name}"
    network_interface_ids = ["${azurerm_network_interface.test-NIC.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "OsAzure"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.vm_name}"
        admin_username = "${var.user_name}"
        admin_password = "${var.user_password}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    /*boot_diagnostics {
        enabled = "false"
    }*/

}

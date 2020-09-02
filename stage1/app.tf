# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "appvm" {
  name                  = "${var.prefix}appVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_app.id]
  size                  = "Standard_DS1_v2"
  tags                  = var.tags
  custom_data           = base64encode(file("app-data.txt"))

  os_disk {
    name    = "${var.prefix}appOsDisk"
    caching = "ReadWrite"

    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }

  computer_name  = "${var.prefix}appVM"
  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }


}

resource "azurerm_managed_disk" "appdata" {
  name                 = "appdata"
  location             = azurerm_resource_group.rg.location
  create_option        = "Empty"
  disk_size_gb         = 100
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "appdata" {
  virtual_machine_id = azurerm_linux_virtual_machine.appvm.id
  managed_disk_id    = azurerm_managed_disk.appdata.id
  lun                = 0
  caching            = "None"
}


# Create network interface
resource "azurerm_network_interface" "nic_app" {
  name                = "${var.prefix}appNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}appNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_app.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-app" {
  network_interface_id      = azurerm_network_interface.nic_app.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create public IP
resource "azurerm_public_ip" "publicip_app" {
  name                = "${var.prefix}appPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_application_security_group" "app" {
  name                = "asgAPP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_network_interface_application_security_group_association" "app-asg-assoc" {
  network_interface_id          = azurerm_network_interface.nic_app.id
  application_security_group_id = azurerm_application_security_group.app.id
}

data "azurerm_public_ip" "app-ip" {
  name                = azurerm_public_ip.publicip_app.name
  resource_group_name = azurerm_linux_virtual_machine.appvm.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.appvm]
}


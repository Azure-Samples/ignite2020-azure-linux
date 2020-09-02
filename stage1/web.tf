# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "webvm" {
  name                  = "${var.prefix}webVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_web.id]
  size                  = "Standard_DS1_v2"
  tags                  = var.tags
  custom_data           = base64encode(file("web-data.txt"))


  os_disk {
    name    = "${var.prefix}webOsDisk"
    caching = "ReadWrite"

    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }


  computer_name  = "${var.prefix}webVM"
  admin_username = var.admin_username
  admin_password = var.admin_password


  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)

  }


}
resource "azurerm_managed_disk" "webdata" {
  name                 = "webdata"
  location             = azurerm_resource_group.rg.location
  create_option        = "Empty"
  disk_size_gb         = 100
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "webdata" {
  virtual_machine_id = azurerm_linux_virtual_machine.webvm.id
  managed_disk_id    = azurerm_managed_disk.webdata.id
  lun                = 0
  caching            = "None"
}
# Create network interface
resource "azurerm_network_interface" "nic_web" {
  name                = "${var.prefix}webNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}webNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_web.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-web" {
  network_interface_id      = azurerm_network_interface.nic_web.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Create public IP
resource "azurerm_public_ip" "publicip_web" {
  name                = "${var.prefix}webPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_application_security_group" "web" {
  name                = "asgWEB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface_application_security_group_association" "web-asg-assoc" {
  network_interface_id          = azurerm_network_interface.nic_web.id
  application_security_group_id = azurerm_application_security_group.web.id
}

data "azurerm_public_ip" "web-ip" {
  name                = azurerm_public_ip.publicip_web.name
  resource_group_name = azurerm_linux_virtual_machine.webvm.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.webvm]
}

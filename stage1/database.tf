# Create a Linux virtual machine
resource "azurerm_linux_virtual_machine" "dbvm" {
  name                  = "${var.prefix}dbVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_db.id]
  size                  = "Standard_DS1_v2"
  tags                  = var.tags
  custom_data           = base64encode(file("database-data.txt"))

  os_disk {
    name    = "${var.prefix}dbOsDisk"
    caching = "ReadWrite"

    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }

  computer_name  = "${var.prefix}dbVM"
  admin_username = var.admin_username
  admin_password = var.admin_password



  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }


}
resource "azurerm_managed_disk" "dbdata" {
  name                 = "dbdata"
  location             = azurerm_resource_group.rg.location
  create_option        = "Empty"
  disk_size_gb         = 100
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
}

resource "azurerm_virtual_machine_data_disk_attachment" "dbdata" {
  virtual_machine_id = azurerm_linux_virtual_machine.dbvm.id
  managed_disk_id    = azurerm_managed_disk.dbdata.id
  lun                = 0
  caching            = "None"
}

# Create network interface
resource "azurerm_network_interface" "nic_db" {
  name                = "${var.prefix}dbNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}dbNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip_db.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-db" {
  network_interface_id      = azurerm_network_interface.nic_db.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create public IP
resource "azurerm_public_ip" "publicip_db" {
  name                = "${var.prefix}dbPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}


resource "azurerm_application_security_group" "db" {
  name                = "asgDB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface_application_security_group_association" "db-asg-assoc" {
  network_interface_id          = azurerm_network_interface.nic_db.id
  application_security_group_id = azurerm_application_security_group.db.id
}


data "azurerm_public_ip" "db-ip" {
  name                = azurerm_public_ip.publicip_db.name
  resource_group_name = azurerm_linux_virtual_machine.dbvm.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.dbvm]
}

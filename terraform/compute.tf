resource "random_id" "randomId" {
  byte_length = 3  
}

resource "tls_private_key" "bastion_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_private_key" "worker_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}



# Create bastion host VM.
resource "azurerm_virtual_machine" "bastion_vm" {
  name                  = "${var.resource_prefix}-bstn-vm${random_id.randomId.hex}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.bastion_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "${var.resource_prefix}-bstn-dsk${random_id.randomId.hex}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  delete_os_disk_on_termination = "true"

# storage_image_reference {
#    publisher = "Canonical"
#    offer     = "UbuntuServer"
#    sku       = "18.04-LTS"
#    version   = "latest"
#  }

  
  storage_image_reference {
	 id =  "/subscriptions/2557e10a-88b8-421e-ae62-6623068482bd/resourceGroups/tadmin/providers/Microsoft.Compute/galleries/tadmin_shared_images/images/bastion_ansible_standard"
  }

  os_profile {
    computer_name  = "${var.resource_prefix}-bstn-vm${random_id.randomId.hex}"
    admin_username = var.username
    #custom_data    = file("${path.module}/files/nginx.yml")
  }

  os_profile_linux_config {
    disable_password_authentication = true

	ssh_keys {
        path     = "/home/${var.username}/.ssh/authorized_keys"
        key_data = tls_private_key.bastion_ssh.public_key_openssh
    }
	
    # Bastion host VM public key.
    #ssh_keys {
    #  path     = "/home/${var.username}/.ssh/authorized_keys"
    #  key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfDfs/Q+wMLKKxkfKK2TbsJrSvnOV3G/dNoTPcQyq96gEpP7wOoy4++1hkeYhKZEkE+Ni6A6KId8KzTQlbtgnXMyoKwbNDFFJMzAIyZdFHeuRBLxenWK01SKWLL6N8KQ0aFz0d8hUXMhJODCyRZdZHT4u/2v1CI4g1br503Aqo3c2O+uBPhUIM0xJZAG8d+F83QlQZHr07XjdIAKx5KOgoLX6XB/OWZ+YEIlITatYX5mHOcujv1CwcytVeMfDg8x5VHhHTDipjKX/ikROqq0iAng1voTtuz4CDXMckUuaI7k9KTGnhumBzcTYArFMUZWFqJZax8m5y2oI2VHMvGMjzk680Y5VGIbboRi2PbrAbmWTn7SpTJF5One6Y8PBXOLIju7IO/rUAPstwXm/gEXswFSsU6pI/ol/s4JdD2Xx3n9o+ObVafAQwQl9scabpdXJkfjkLrqvZOCR1//FjgktVXNYI+XbAkyBA3pR/jWa2aWYuLYHArQp/NG9aCDGdZjGdlrkSNm/y29rzVN6H7cXSLYG7te3NEAJehARLLVqon0mdfpYGluhYxBwC8pxJHi9sew0n0gVM4kjIjvrapFVBfX9BzQKrZMkXLi6bt2rx6ktgWUSLcmak7Du5JzQZaJnTkEpHxK52NvqIQo0Nziq7gWeBm6KMxp1B5fuVRNZNPw=="
    #}
    #
    #disable_password_authentication = true

    
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  tags = var.tags
  
}

resource "null_resource" "bastion_provisioner" {
	depends_on = [azurerm_public_ip.public_ip, azurerm_virtual_machine.bastion_vm]

  provisioner "remote-exec" {
	connection {
      type     		= "ssh"
	  user			= var.username
      host     		= azurerm_public_ip.public_ip.ip_address
      private_key   = tls_private_key.bastion_ssh.private_key_pem
    }
	inline = [
      "ansible --version",
	  "echo $'Host jumpboxtuto-*\n  IdentitiesOnly yes\n  IdentityFile ~/.ssh/jumpboxtuto_rsa' > ~/.ssh/config",
	  "echo $'${tls_private_key.worker_ssh.private_key_pem}' > ~/.ssh/jumpboxtuto_rsa",
	  "chmod 600 ~/.ssh/config",
	  "chmod 600 ~/.ssh/jumpboxtuto_rsa"
    ]
  }
  

}


resource "null_resource" "file_provisioner" {
	depends_on = [null_resource.bastion_provisioner]

  provisioner "file" {
    connection {
      type     		= "ssh"
	  user			= var.username
      host     		= azurerm_public_ip.public_ip.ip_address
      private_key   = tls_private_key.bastion_ssh.private_key_pem
    }
    source      = "../ansible/provision.yml"
    destination = "~/provision.yml"
  }
}

resource "null_resource" "ansible_provisioner" {
	depends_on = [null_resource.bastion_provisioner, null_resource.file_provisioner, azurerm_public_ip.public_ip, azurerm_virtual_machine.bastion_vm, azurerm_public_ip.public_ip, azurerm_virtual_machine.worker_vm]

  provisioner "remote-exec" {
	connection {
      type     		= "ssh"
	  user			= var.username
      host     		= azurerm_public_ip.public_ip.ip_address
      private_key   = tls_private_key.bastion_ssh.private_key_pem
    }
	inline = [
      "ansible-playbook -i ${var.resource_prefix}-wrkr-vm001, provision.yml"
    ]
  }
}

# Create worker host VM.
resource "azurerm_virtual_machine" "worker_vm" {
  name                  = "${var.resource_prefix}-wrkr-vm001"
  location              = var.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.worker_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "${var.resource_prefix}-wrkr-dsk001"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.resource_prefix}-wrkr-vm001"
    admin_username = var.username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    # Worker host VM public key.
    ssh_keys {
        path     = "/home/${var.username}/.ssh/authorized_keys"
        key_data = tls_private_key.worker_ssh.public_key_openssh
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  tags = var.tags
}
resource "azurerm_linux_virtual_machine" "vuln_vm" {
  name                  = "vm-ubuntu-vuln-ssrf"
  resource_group_name   = azurerm_resource_group.lab_rg.name
  location              = azurerm_resource_group.lab_rg.location
  size                  = "Standard_B1ls" # Cheapest VM size
  admin_username        = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.lab_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/lab_ssh_key.pub") # Uses the locally generated key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # THIS IS THE VULNERABILITY SOURCE! (System-Assigned Identity)
  identity {
    type = "SystemAssigned"
  }

  # cloud-init script to install and run the SSRF Python API
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
    sudo pip3 install flask requests
    
    cat << 'VULN' > /var/www/app.py
    from flask import Flask, request
    import requests
    import json
    
    app = Flask(__name__)
    
    @app.route("/")
    def home():
        return "<h3>Welcome to the Lab Test API</h3><p>Use /fetch?url= to test URLs</p>"

    @app.route("/fetch")
    def fetch():
        url = request.args.get("url")
        if not url:
            return "Please provide a url parameter."
        try:
            # VULNERABILITY: Blindly fetching user-supplied URL and passing specific Azure IMDS headers!
            # We explicitly add Metadata: true to make the lab easier for demonstrating IMDS SSRF.
            headers = {"Metadata": "true"}
            r = requests.get(url, headers=headers, timeout=2)
            return r.text
        except Exception as e:
            return str(e)

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    VULN

    cat << 'SERVICE' > /etc/systemd/system/vuln-api.service
    [Unit]
    Description=Vulnerable SSRF API
    After=network.target

    [Service]
    User=root
    WorkingDirectory=/var/www
    ExecStart=/usr/bin/python3 /var/www/app.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    sudo systemctl enable vuln-api.service
    sudo systemctl start vuln-api.service
  EOF
  )
}

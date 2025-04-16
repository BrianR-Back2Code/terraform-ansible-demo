#!/bin/bash

# Prüfe, ob jq installiert ist
if ! command -v jq &> /dev/null; then
  echo "jq ist nicht installiert. Versuche jq zu installieren..."
  if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y jq
  elif command -v yum &> /dev/null; then
    sudo yum install -y jq
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y jq
  else
    echo "Paketmanager nicht erkannt."
    echo "Erstelle Inventory manuell ohne jq..."
    
    # Wechsle ins Terraform-Verzeichnis
    cd ../terraform
    
    # Hole die IP-Adresse direkt
    SERVER_IP=$(terraform output -raw web_server_public_ip)
    
    # Erstelle ein einfaches JSON-Inventory manuell
    cat > ../ansible/inventory.json << EOF
{
  "webservers": {
    "hosts": {
      "web": {
        "ansible_host": "$SERVER_IP",
        "ansible_user": "ec2-user",
      }
    }
  }
}
EOF
    
    echo "Ansible-Inventory wurde manuell erstellt."
    exit 0
  fi
fi

# Wenn jq installiert ist oder wurde, verwende es
# Wechsle ins Terraform-Verzeichnis
cd ../terraform

# Hole die Ausgabe des Ansible-Inventory und speichere sie als JSON
terraform output -json ansible_inventory | jq > ../ansible/inventory.json

echo "Ansible-Inventory wurde generiert aus Terraform-Output."

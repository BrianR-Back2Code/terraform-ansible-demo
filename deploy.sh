#!/bin/bash
set -e  # Beende bei Fehlern

# Farbkonstanten für bessere Lesbarkeit
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo -e "${YELLOW}=== Terraform + Ansible Demo-Deployment ===${NC}"

# 1. Terraform Initialisierung und Bereitstellung
echo -e "${BLUE}1. Starte Infrastrukturbereitstellung mit Terraform...${NC}"
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# 2. Warte auf vollständige SSH-Verfügbarkeit und teste Verbindung
echo -e "${BLUE}2. Warte auf vollständige SSH-Verfügbarkeit...${NC}"

# Setze absolute Pfade für sicherere Ausführung
SERVER_IP=$(cd "$(dirname "$0")/terraform" && terraform output -raw web_server_public_ip)
SSH_KEY_PATH=$(cd "$(dirname "$0")/terraform" && terraform output -raw private_key_path | tr -d '"')

echo "Server IP: $SERVER_IP"
echo "SSH Key: $SSH_KEY_PATH"

# Robusterer SSH-Bereitschaftstest
for i in {1..12}; do  # 2 Minuten Timeout (12 x 10 Sekunden)
  echo "Versuche SSH-Verbindung (Versuch $i/12)..."
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$SSH_KEY_PATH" ec2-user@"$SERVER_IP" "echo SSH-Verbindung erfolgreich"; then
    echo "SSH ist bereit!"
    break
  fi
  
  if [ $i -eq 12 ]; then
    echo "Timeout beim Warten auf SSH. Bitte überprüfe die Infrastruktur manuell."
    exit 1
  fi
  
  echo "Warte 10 Sekunden vor dem nächsten Versuch..."
  sleep 10
done

# 3. Generiere Ansible-Inventory aus Terraform-Output
echo -e "${BLUE}3. Generiere Ansible-Inventory aus Terraform-Output...${NC}"
cd ansible
./generate_inventory.sh

# 4. Führe Ansible-Playbook aus
echo -e "${BLUE}4. Konfiguriere Server mit Ansible...${NC}"
ansible-playbook playbooks/setup_nginx.yml
cd ..

# 5. Hole Server-IP für den Zugriff
SERVER_IP=$(cd terraform && terraform output -raw web_server_public_ip)

echo -e "${GREEN}=== Deployment erfolgreich abgeschlossen! ===${NC}"
echo -e "Webserver erreichbar unter: http://${SERVER_IP}"
echo -e "Zugriff per SSH: ssh -i ~/.ssh/dein-schluessel.pem ec2-user@${SERVER_IP}"
echo -e "${YELLOW}HINWEIS: Vergiss nicht, die Ressourcen nach dem Test zu löschen:${NC}"
echo -e "cd terraform && terraform destroy -auto-approve"

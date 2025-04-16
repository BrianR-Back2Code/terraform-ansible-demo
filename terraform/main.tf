# Provider-Konfiguration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"  # Anpassen an deine bevorzugte Region
  # Wenn du mehrere AWS-Profile hast, kannst du hier das spezifische Profil angeben:
  # profile = "default" 
}

# Data Source für neueste Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# Ressource: EC2-Instanz
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"  # Free Tier-berechtigt, bessere Performance als t2.micro
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "terraform-ansible-demo"
    Environment = "demo"
    ManagedBy = "terraform"
    CreatedAt = formatdate("YYYY-MM-DD", timestamp())
  }

  # Warten auf SSH-Verfügbarkeit, bevor die Bereitstellung als abgeschlossen gilt
  provisioner "remote-exec" {
    inline = ["echo 'SSH is up and running!'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

# Ressource: Security Group für Webserver
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Security group for web server"

  # SSH-Zugriff
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # In produktiven Umgebungen einschränken!
  }

  # HTTP-Zugriff
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ausgehenden Verkehr erlauben
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

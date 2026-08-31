locals {
  tags = {
    Project     = "connexxion"
    ManagedBy   = "terraform"
    Environment = "assessment-lab"
  }
}

# --- Networking: default VPC is acceptable per the assessment, documented here ---

data "aws_vpc" "default" {
  default = true
}

# Pick a subnet in the default VPC that auto-assigns public IPs (i.e. a public subnet)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "chosen" {
  id = data.aws_subnets.public.ids[0]
}

# The default VPC's default route table already routes 0.0.0.0/0 to an Internet
# Gateway, and its subnets auto-assign public IPs — so no explicit IGW/route
# table resources are needed here. Documented rather than hidden.

# --- AMI: latest Ubuntu LTS from Canonical ---

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security group: HTTP open, SSH restricted to the candidate's own IP ---

resource "aws_security_group" "app" {
  name        = "connexxion-app-sg"
  description = "Connexxion lab app: HTTP from anywhere, SSH from your IP only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from your own IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_ip]
  }

  ingress {
    description = "HTTP from anywhere (app is exposed via Nginx, not directly)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "connexxion-app-sg" })
}

# --- EC2 instance, fully bootstrapped via user_data (cloud-init) ---

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.chosen.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    repo_url   = var.repo_url
    app_subdir = var.app_subdir
    app_port   = var.app_port
  })

  # Ensures a change to the bootstrap script is visible in `terraform plan`
  user_data_replace_on_change = true

  tags = merge(local.tags, { Name = "connexxion-app" })
}

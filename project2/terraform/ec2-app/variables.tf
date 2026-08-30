variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_ingress_ip" {
  description = "Your public IP, in CIDR form (e.g. 102.91.92.224/32). SSH is only allowed from this address."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_ingress_ip, 0))
    error_message = "ssh_ingress_ip must be a valid CIDR, e.g. 102.91.92.224/32."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair (created in the AWS console/CLI beforehand) to allow SSH access"
  type        = string
  default     = "connexxionGroup_key_pair"
}

variable "repo_url" {
  description = "Git URL of the application repository to clone on boot"
  type        = string
  default     = "https://github.com/EseVic/connexxiongroup_project.git"
}

variable "app_subdir" {
  description = "Subdirectory inside the repo that contains the Node app (with package.json)"
  type        = string
  default     = "app"
}

variable "app_port" {
  description = "Port the Node app listens on internally"
  type        = number
  default     = 3000
}

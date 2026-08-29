# Terraform (Part 3)

Not built yet. Will contain:

- `main.tf` — security group, EC2 instance, networking resources
- `variables.tf` — at minimum: `aws_region`, `instance_type`, `ssh_ingress_ip`
- `outputs.tf` — public IP / access value
- `user_data.sh` (or inline) — cloud-init bootstrap: install runtime + web server, pull app source
- `.gitignore` already at repo root covers `.tfstate` and `.tfvars`

Commands to demonstrate in the root README once built:
```
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

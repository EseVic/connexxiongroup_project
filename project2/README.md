# Connexxion — DevOps & Kubernetes Technical Assessment submission

## Repository structure

```
/app              TaskBoard: Node.js/Express + EJS + SQLite, JWT auth, full CRUD (Part 2, Part 4)
/terraform
  /ec2-app        Terraform for Part 3 — recreates the Part 1/2 EC2 app deployment as code
  /eks            Terraform for Part 5 — EKS cluster the Kubernetes deployment runs on
/kubernetes       Deployment/Service/ConfigMap/Secret/Ingress/HPA for the app (Part 5)
/ci-cd            Jenkinsfile — builds, tests, pushes, and deploys to EKS (Part 7)
/docs             Screenshots and evidence for every part
```

Terraform is split into two independent stacks on purpose: `ec2-app` is the
$5-budget lab instance from Parts 1–3, and `eks` is a separate, much larger
piece of infrastructure for Part 5. They have different costs, different
lifecycles, and nothing links them — keeping them separate means you can
`terraform destroy` the expensive EKS stack the moment grading is done without
touching the cheap EC2 lab instance, or vice versa.

## Part 3 — Terraform for the EC2 app (`/terraform/ec2-app`)

This reproduces everything done manually via SSH in Parts 1–2, as code:

- **Security group** — SSH (22) restricted to your IP via `var.ssh_ingress_ip`,
  HTTP (80) open to everyone, all egress allowed.
- **EC2 instance** — Ubuntu (latest LTS, looked up dynamically via an AMI data
  source rather than a hard-coded ID), in the default VPC's public subnet
  (documented here rather than building a custom VPC, per the assessment's
  "default VPC is acceptable if documented").
- **`user_data.sh.tpl`** — cloud-init script that runs on first boot and does
  everything Part 2 asked for, unattended:
  1. Installs Node.js, Nginx, git
  2. Clones the app repo (`var.repo_url`)
  3. Runs `npm install`
  4. Generates a random `JWT_SECRET` **on the instance itself** with
     `openssl rand -hex 32` and writes `.env` — never hard-coded in Terraform
     or committed anywhere
  5. Writes and enables a systemd unit (`connexxiongroup.service`) so the app
     starts on boot and restarts on crash
  6. Writes an Nginx reverse-proxy config exposing port 80 while keeping the
     app's own port (3000) internal, and reloads Nginx

Variables (`region`, `instance_type`, `ssh_ingress_ip`) are required per the
assessment — see `terraform.tfvars.example`. Copy it:

```bash
cd terraform/ec2-app
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set your real IP (curl -4 ifconfig.me) and key pair name
```

Then, from `terraform/ec2-app`:

```bash
terraform init
terraform validate
terraform plan
terraform apply     # fully automated — app is live on http://<public_dns> when this finishes
terraform destroy   # cleanly removes everything this stack created
```

**Note on the existing manually-built instance:** you already have a working
instance built by hand earlier (systemd + Nginx set up over SSH). This
Terraform stack stands up a **new, independent** instance that reproduces the
same result from scratch — it doesn't import or touch your existing one. Run
this as its own proof of Part 3, then destroy it; keep your manual instance
(or this one — either satisfies Part 2's evidence) for the parts of the
assessment that need a live URL.

## Part 5/7 — Kubernetes on EKS (`/terraform/eks`, `/kubernetes`, `/ci-cd`)

The same TaskBoard app, containerised and deployed to a real EKS cluster:

- `/terraform/eks` provisions the EKS control plane, node group, and
  supporting IAM/networking.
- `/kubernetes` — 1 Deployment (2 replicas), 1 Service, 1 ConfigMap, 1 Secret,
  1 Ingress (ALB), 1 HPA, readiness/liveness probes on `/health`.
- `/ci-cd/Jenkinsfile` — tests, builds, tags, pushes, and deploys the image,
  plus a `DESTROY_INFRA` parameter that tears the cluster down.
  **Jenkins job "Script Path" setting should point at `ci-cd/Jenkinsfile`.**

### Known limitation — SQLite across replicas

The app stores data in a local SQLite file. With 2 replicas, each pod has its
own separate file — a user could register on one pod and appear logged out on
the other, since the Service load-balances between them. This is a deliberate,
documented simplification for the lab (see Part 9 write-up below), not a
hidden bug. A production fix would be a shared database (e.g. the Supabase
Postgres already available) — ask if you want that migration done.

### Manual steps before the Kubernetes/CI-CD path actually runs

1. Create the Terraform state bucket first (`terraform/eks/backend.tf` expects
   it to already exist):
   ```bash
   aws s3 mb s3://connexxion-tfstate --region us-east-1
   ```
2. Set up Jenkins credentials: `AWS_CREEDS`, `docker_creds`,
   `connexxion-jwt-secret`.
3. Cost reminder: EKS control plane + 2–4 `t3.medium` nodes + NAT Gateway +
   ALB. Destroy right after grading:
   ```bash
   cd terraform/eks && terraform destroy
   ```

## Part 9 — write-up prompts still to fill in

- **VPC/subnet/route/security-group design** (Part 1 Q7): _TODO — describe
  using the default VPC's existing public subnet and IGW route, documented
  rather than custom-built, per assessment Part 1 item 5._
- **Why avoid root for daily AWS work** (Part 1 Q1).
- **Why Nginx as a reverse proxy** (Part 2): hides the internal app port,
  standard port 80/443, TLS termination point later, buffering.
- **Terraform structure and state approach** (Part 3): two independent stacks,
  local state for the cheap lab instance, remote S3 state for the EKS cluster
  since it's the higher-stakes, longer-lived resource.
- **SQLite-across-replicas limitation** (see above) — good, honest answer to
  "what did you simplify because this is a technical assessment."
- **What happens when a test/deploy stage fails, and how would you roll back
  in production** (Part 7 Q43/44): pipeline stops on any non-zero exit, bad
  image never pushed, previous Deployment keeps serving; rollback via
  `kubectl rollout undo deployment/connexxion-app -n connexxion` or
  redeploying a prior image tag.

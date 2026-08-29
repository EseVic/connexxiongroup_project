# DevOps & Kubernetes Technical Assessment — Submission

## Repository structure

```
/app          Full-stack app: Node.js/Express + EJS + SQLite, JWT-based auth, full CRUD dashboard
/terraform    Infrastructure as Code for the AWS environment (Part 3)
/kubernetes   Kubernetes manifests: Deployment, Service, ConfigMap, Secret, Ingress (Part 5)
/ci-cd        CI/CD pipeline config (Part 7) — GitHub Actions workflow also lives at
              .github/workflows/ci-cd.yml (GitHub only runs workflows from that exact path;
              the copy here is kept for the required folder structure / easy review)
/docs         Screenshots and evidence for every stage (see "Mandatory Proof of Work")
```

## The application

**What it is:** TaskBoard — a small task-tracking app with user accounts. Users register,
log in, and manage their own tasks (create, edit, update status, delete) from a dashboard.
Each user only sees their own tasks.

**Source:** written for this assessment, in `/app`. Stack: Node.js + Express, EJS templates
for server-rendered views, SQLite (via `better-sqlite3`) for storage, `bcryptjs` for password
hashing, and `jsonwebtoken` for session tokens stored in an httpOnly cookie.

**Endpoints:**
| Method | Path | Purpose |
|---|---|---|
| GET/POST | `/register` | Create an account |
| GET/POST | `/login` | Log in |
| POST | `/logout` | Clear session |
| GET | `/dashboard` | List the logged-in user's tasks (protected) |
| POST | `/tasks` | Create a task (protected) |
| GET | `/tasks/:id/edit` | Edit form (protected) |
| POST | `/tasks/:id` | Update a task (protected) |
| POST | `/tasks/:id/delete` | Delete a task (protected) |
| GET | `/health` | Health check — used for k8s readiness/liveness probes |

**Running locally:**
```bash
cd app
npm install
cp .env.example .env   # then edit JWT_SECRET
npm start              # listens on PORT (default 3000)
```

**Running in Docker:**
```bash
cd app
docker build -t taskboard-app .
docker run -p 3000:3000 -e JWT_SECRET=replace_me taskboard-app
```

---

## Part 9 — Technical write-up

> Fill each of these in your own words once the relevant part is built. Bullet starters
> below are just prompts, not answers — the panel wants your reasoning.

- **What is the application, and where did the source code come from?**
  TaskBoard, described above — written for this assessment.
- **Describe the AWS architecture and network flow from a browser to the application.**
  _TODO once Part 1/2 is done: VPC → subnet → IGW → EC2 public IP → Nginx:80 → app:3000._
- **How did you secure SSH access?**
  _TODO: security group restricts port 22 to your IP only; document the CIDR you used._
- **How did you make the application start on boot and recover after a crash?**
  _TODO: systemd unit with `Restart=on-failure` and `WantedBy=multi-user.target`._
- **Why Nginx/Apache as a reverse proxy instead of exposing the app port directly?**
  _TODO: TLS termination point, standard port 80/443, buffering, hiding internal port, etc._
- **Explain your Terraform structure, variables and state-management approach.**
- **Explain your Dockerfile and image choices.**
  _Alpine base for size; installs deps before copying source for layer caching; runs as
  non-root `node` user; only production deps installed._
- **Explain your Kubernetes Deployment, Service and Ingress.**
- **How does Kubernetes recover when a pod fails?**
- **Describe the troubleshooting process you used when the app was unavailable.**
- **What would you add or change for a production deployment?**
- **What did you simplify because this is a technical assessment?**
  _e.g. SQLite instead of RDS, single instance instead of multi-AZ, self-signed/no TLS._
- **What would you improve with another two days?**

## Part 10 — Production considerations

_TODO: short section covering HTTPS/TLS, managed DB (RDS), secrets manager, multi-AZ,
load balancing/ASG, EKS production patterns, centralised logging, alerting, backups/DR,
least-privilege IAM, network segmentation, zero-downtime deploys, remote state + locking._

# Connexxion — Kubernetes & EKS submission

This deploys the actual TaskBoard app (the Node/Express/EJS app built earlier for this
assessment) to a real EKS cluster, satisfying Parts 3, 5, 6 and 7.

## What's in here

```
/terraform    EKS cluster + VPC via Terraform (Part 3)
/kubernetes   Deployment/Service/ConfigMap/Secret/Ingress/HPA manifests for the
              single TaskBoard app (Part 5). Jenkinsfile also lives in
              /terraform — it drives Part 7 (CI/CD)
/docs         Screenshots (see "Mandatory Proof of Work" in the assessment doc)
```

## Background — how this file set came to be

This started from Terraform/Kubernetes files for a different, unrelated 3-tier
project (frontend + backend + ML service). Those were renamed to fit this
project's naming, then the frontend and ML tiers were removed entirely, because
the actual application here is the single TaskBoard app — one Node process
serving both pages and API-style routes, not three separate services. What's in
this folder now only reflects that one app.

## What changed from the original template

- Every `stocksense`-style reference renamed to `connexxion` (namespace,
  resource names, labels, ConfigMap/Secret, image name, EKS cluster name, S3
  state bucket/key, Jenkins env vars).
- Frontend and ML-service Deployments/Services/HPAs deleted — not part of this
  app.
- `backend-*.yaml` renamed to `app-*.yaml` (there's no separate backend tier).
- Container port corrected from `3001` → `3000` to match the app's actual
  `PORT`.
- Health check path corrected from `/api/health` → `/health` to match the
  app's actual endpoint.
- `DATABASE_URL` removed from the ConfigMap/Secret/Deployment — the app uses a
  local SQLite file, not a Postgres connection string.
- Ingress simplified to a single `/` path routing straight to the app (the old
  version split `/api` and `/` across separate backend/frontend services).
- Jenkinsfile simplified to build/test/push/deploy one image from `./app`
  instead of three images from `./backend`, `./frontend`, `./ml-service`.

## A real secret was in the originally uploaded files — already scrubbed, but act on it

The original secret file contained a live Supabase Postgres username and
password in plaintext. That's gone now (this app doesn't even use Postgres),
but if that credential was ever committed anywhere or shared, rotate it in
Supabase regardless.

## Known limitation worth stating honestly in your Part 9 write-up

**SQLite + 2 replicas means each pod has its own separate data file.** A user
who registers might get load-balanced to a different pod on their next request
and appear logged out, or their tasks might only show up on one of the two
pods. This is a real, known limitation of running a single-file SQLite
database behind multiple replicas — not a bug you need to silently hide.

For this lab, it's reasonable to either:
- **Demonstrate it as-is and explain the limitation** in Part 9 ("what did you
  simplify because this is a technical assessment") — this is honestly the
  simplest path and the assessment explicitly invites this kind of answer, or
- **Swap SQLite for a real Postgres database** (you already have a Supabase
  instance from another project) if you want the multi-replica behavior to
  actually be consistent. This needs code changes to `app/src/db.js` — ask if
  you want this done.

## Manual steps you still need to do before this will actually run

1. **Create the Terraform state bucket first** — `backend.tf` points at an S3
   bucket named `connexxion-tfstate`. Terraform's S3 backend doesn't create the
   bucket for you:
   ```bash
   aws s3 mb s3://connexxion-tfstate --region us-east-1
   ```
2. **Confirm your repo has an `/app` folder at the root** with the TaskBoard
   source and Dockerfile — the Jenkinsfile builds from `./app`.
3. **Set up Jenkins credentials**: `AWS_CREEDS`, `docker_creds`,
   `connexxion-jwt-secret`. Without these, the relevant stages fail immediately
   (correct/secure behaviour).
4. **Cost reminder** — this is still a managed EKS control plane + 2–4
   `t3.medium` nodes + NAT Gateway + ALB, now running a single small Node app.
   That's disproportionate infrastructure for the workload, but you've already
   decided to keep it and destroy it right after grading:
   ```bash
   cd terraform && terraform destroy
   ```

## How this maps to the assessment

- **Part 3 (Terraform)** — `/terraform` provisions the VPC + EKS cluster.
- **Part 5 (Kubernetes)** — 1 Deployment (2 replicas), 1 Service, 1 ConfigMap,
  1 Secret, 1 Ingress (ALB), 1 HPA. Readiness/liveness probes against `/health`.
- **Part 6 (Troubleshooting)** — be ready to walk the panel from Ingress → ALB
  target group → Service → pod selector → container port → app logs, using
  `kubectl describe`, `kubectl logs`, `kubectl get events` against this actual
  cluster.
- **Part 7 (CI/CD)** — Jenkinsfile tests, builds, tags (`git-sha-buildnum`),
  pushes, and deploys the app, plus a destroy path.

## Part 9 — write-up prompts still to fill in

- **The SQLite-across-replicas limitation** (see above) — this is a good,
  honest answer to "what did you simplify because this is a technical
  assessment."
- **What should happen when a test or deployment stage fails?** (Part 7 Q43)
  _TODO: the pipeline stops on any non-zero exit; the bad image is never
  pushed; the previous Deployment keeps serving traffic since `kubectl set
  image` never runs._
- **How would you implement rollback in production?** (Part 7 Q44)
  _TODO: e.g. `kubectl rollout undo deployment/connexxion-app -n connexxion`,
  or re-running the pipeline against a previous known-good image tag._

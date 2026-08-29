# CI/CD (Part 7)

GitHub Actions only runs workflows found at `.github/workflows/` in the repo root — so the
real, functioning workflow file must live there. A copy is kept in this folder to satisfy
the assessment's required repo structure and for easy review; keep both in sync, or note in
your root README that `.github/workflows/ci-cd.yml` is the authoritative one.

A starter workflow is at `.github/workflows/ci-cd.yml` (copied here as `ci-cd.yml`). It
currently: installs deps, and builds the Docker image on every push. Still to add once
Part 5/6 are done: a real test step, image tagging/push to a registry, and a deploy step
against your Kubernetes cluster.

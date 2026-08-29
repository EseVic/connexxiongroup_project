# Kubernetes (Part 5)

Not built yet. Will contain, at minimum:

- `deployment.yaml` — 2+ replicas, readiness/liveness probes against `GET /health`,
  resource requests/limits
- `service.yaml` — routes traffic to the deployment's pods
- `configmap.yaml` — non-sensitive config (e.g. `PORT`)
- `secret.yaml` — `JWT_SECRET` (create with `kubectl create secret` rather than committing
  plaintext values — reference it in the manifest, don't hardcode it)
- `ingress.yaml` — external exposure

The app already exposes `GET /health` (returns `{"status":"ok"}`) — wire that up as the
probe path.

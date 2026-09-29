# Aevo Infrastructure

Terraform source of truth for Google Cloud and the Cloudflare account boundary.

The repository deliberately separates bootstrap from environment stacks:

- `bootstrap/` creates the versioned Terraform state bucket and prerequisites.
- `envs/nonprod/` provisions preview/shared development/staging resources.
- `envs/prod/` provisions production resources behind protected approvals.
- `modules/` contains reusable Cloud Run, Cloud SQL, IAM, eventing, secrets and DNS modules.

No secret values, service-account JSON keys or production project IDs belong in
this repository. GitHub Actions authenticates with Workload Identity Federation.
The first bootstrap step is human-approved project/billing/state setup; all
subsequent changes run through Terraform plan/apply.

Production Core API instances also require the Edge Gateway HMAC boundary;
the shared secret is mapped from Secret Manager and is never a plain
Terraform variable.

Set `worker_core_api_origin` and `worker_probe_targets` in each environment
stack when enabling runtime connection monitoring. The target list is JSON,
for example `[{"appCode":"GO","baseUrl":"https://go.example.com"}]`;
the worker only sends observed probe results to Core API after both values and
the probe token are configured.

## Local checks

```bash
bun install
bun run check
```

Terraform is intentionally not invoked by the JavaScript check because the
developer workstation may not have Terraform installed. CI must run
`terraform fmt -check`, `terraform init -backend=false` and `terraform validate`
for each stack before planning.

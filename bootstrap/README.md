# Bootstrap

Run this stack only after the Google Cloud organization, billing account and
project IDs are approved. Use a temporary local backend for the first apply;
after the state bucket exists, migrate state to the protected GCS backend.

Required inputs:

- `project_id`
- `state_bucket_name`
- `region` (target default: `asia-southeast1` after latency validation)

This stack creates no application secrets and no runtime service-account keys.

# State: local backend — migrate to GitLab managed state at Phase 5 per ADR-0011
# Backup: scripts/backup-state.py --env prod syncs to Synology NAS
# Wrapper: scripts/tf.sh auto-backs up on apply/destroy

terraform {
  # State backend — local for PoC phase
  # TODO: migrate to S3-compatible backend (MinIO/GitLab) when GitLab CE is deployed
  # backend "s3" {
  #   endpoint = "https://minio.by-systems.arpa"
  #   bucket   = "terraform-state"
  #   key      = "prod/terraform.tfstate"
  #   region   = "us-east-1"  # required by S3 provider, value doesn't matter for MinIO
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   force_path_style            = true
  # }
  backend "local" {
    # State stored locally in this directory
    # Not suitable for team use — migrate to remote backend ASAP
    path = "terraform.tfstate"
  }
}

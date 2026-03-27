terraform {
  # State backend — local for PoC phase
  # TODO: migrate to S3-compatible backend (MinIO/GitLab) when GitLab CE is deployed
  # backend "s3" {
  #   endpoint = "https://minio.by-systems.arpa"
  #   bucket   = "terraform-state"
  #   key      = "poc/terraform.tfstate"
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

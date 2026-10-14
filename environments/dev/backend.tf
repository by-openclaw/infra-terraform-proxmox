# State: local backend, same model as prod/test (migrate with them when ADR-0011 Phase 5 lands)
# Backup: scripts/backup-state.py --env dev syncs to Synology NAS
# Run: ansible-platform playbooks/terraform.yml
#        -e tf_env=dev -e tf_node=br-pmox-03
#        -e tf_token_vault_path=dev/proxmox/tokens/svc-rune-terraform -e tf_token_id_is_full=true

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

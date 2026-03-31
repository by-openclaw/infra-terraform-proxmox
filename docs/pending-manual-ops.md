# Pending Manual Operations

Operations that require manual intervention — cannot be automated via API.

---

## Token rename: svc-terraform@pve!ci → svc-terraform-poc@pve!ci

**Status:** Pending
**Reason:** ADR-0010 requires env tier in service account names (`svc-<tool>-<env>@<realm>!<scope>`).
**Blocker:** Proxmox PVE API does not support token rename — requires delete + create with new name.
**Risk:** Deleting the token disrupts Terraform automation until the new token is configured everywhere.

**Manual steps (when approved):**
1. Create new token `svc-terraform-poc@pve!ci` in Proxmox UI with same permissions
2. Update `workspace/infra/secrets/.proxmox-nonprod.env` with new token secret
3. Verify `terraform plan` works with new token
4. Delete old token `svc-terraform@pve!ci` only after verification
5. Update `CLAUDE.md` and workspace `TOOLS.md` with new token name

**Do NOT delete the existing token without explicit approval from @yboujraf.**

# Archived seed tooling

Kept for provenance, never run.

| File | Superseded by | Proof |
|---|---|---|
| `build-seed.py` | `by_systems.opnsense.opnsense_seed_config` (ansible-opnsense#32) | all three real profiles rendered byte-identical before anything changed; three firewalls built from scratch on the Ansible path since |

Build a firewall with:

```bash
ansible-playbook -i inventories/<env> playbooks/opnsense-build.yml -e opnsense_provision_fw=<name>
```

## Still live, deliberately

`recreate-and-seed.py` and `vmprofile.py` stay in the parent directory. They are the only way to
converge the **in-place hardware** of a running firewall — memory, cores, onboot, tags — with
`--check` (read-only drift) and `--apply-hw`. Nothing in Ansible does that yet, and they never
referenced `build-seed.py`, so archiving the renderer left them untouched.

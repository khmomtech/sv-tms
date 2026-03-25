Ansible deploy for SV-TMS

Prerequisites (on control machine)
- Ansible >= 2.14
- `rsync` available locally
- SSH key access to target server(s)

Inventory
- Edit `infra/ansible/inventory.ini` if you need to change the target host.

Basic usage (from repo root):

```bash
# Optional: export repo_src if playbook can't find repo root
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml --extra-vars "repo_src=$(pwd)"
```

The playbook will:
- Install Docker and the Compose plugin on the remote Ubuntu 24 host
- Enable a basic UFW firewall (allows SSH, HTTP, HTTPS)
- Synchronize the repository to `/opt/sv-tms` on the remote host using `synchronize` (rsync)
- Start the Docker Compose stack present in the repo root
- Attempt to issue TLS certificates using the `certbot` service (webroot) if `infra/.env` contains `DOMAIN` and `EMAIL`

Notes
- The playbook uses `synchronize` which calls `rsync` from the control machine; run it from your local clone of the repo.
- Do NOT commit `infra/.env` — copy `infra/.env.example` to `infra/.env` and fill secrets before running.
- If the certbot step fails, you can run the certbot command manually on the server as described in `infra/README.md`.

Troubleshooting
- If synchronization fails, ensure `rsync` and `ssh` are available and your SSH key is authorized on the server.
- If Docker install fails, check apt logs and network access to Docker repo.

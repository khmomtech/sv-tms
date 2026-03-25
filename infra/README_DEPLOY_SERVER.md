Ubuntu server: Install Docker and run the split production platform

This file describes the minimal steps to install Docker on Ubuntu and run the split production platform from `infra/docker-compose.prod.yml`.

1) Prepare server (Ubuntu 20.04/22.04+)

- Update and install prerequisites:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
```

- Add Docker's official GPG key and repo:

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
```

- Install Docker Engine and CLI:

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

- (Optional) Add your user to the docker group to run docker without sudo:

```bash
sudo usermod -aG docker $USER
# then logout/login or run: newgrp docker
```

- Enable and start Docker:

```bash
sudo systemctl enable docker --now
```

- Test Docker:

```bash
docker run --rm hello-world
```

2) Clone repo and prepare env

```bash
# on the server
cd /opt
sudo git clone <your-repo-git-url> sv-tms
cd sv-tms
# copy example env and edit infrastructure secrets
cp infra/.env.example infra/.env
# edit infra/.env and set real secrets
```
nano infra/.env

3) Start the production stack

- Use the helper script (from repo root):

```bash
sudo /opt/sv-tms/infra/scripts/deploy_stack.sh
```

This now runs a production preflight first via [preflight_prod.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/preflight_prod.sh), checking required env vars, disk paths, compose rendering, and Docker availability before rollout.
It also runs [post_deploy_smoke.sh](/Users/sotheakh/Documents/develop/sv-tms/infra/scripts/post_deploy_smoke.sh) after the stack comes up, so deploy success is tied to service health and edge reachability instead of only container startup.

- Or manually:

```bash
cd /opt/sv-tms
sudo docker compose --env-file infra/.env -f infra/docker-compose.prod.yml up -d --build --remove-orphans
```

4) Verify

```bash
sudo docker compose --env-file infra/.env -f infra/docker-compose.prod.yml ps
sudo docker compose --env-file infra/.env -f infra/docker-compose.prod.yml logs --tail 200 api-gateway core-api telematics-api
```

5) Scheduled backups and renewals

Install the provided systemd units:

```bash
sudo cp infra/systemd/svtms-backup.service /etc/systemd/system/
sudo cp infra/systemd/svtms-backup.timer /etc/systemd/system/
sudo cp infra/systemd/svtms-backup-offsite.service /etc/systemd/system/
sudo cp infra/systemd/svtms-backup-offsite.timer /etc/systemd/system/
sudo cp infra/systemd/svtms-restore-drill.service /etc/systemd/system/
sudo cp infra/systemd/svtms-certbot-renew.service /etc/systemd/system/
sudo cp infra/systemd/svtms-certbot-renew.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now svtms-backup.timer
sudo systemctl enable --now svtms-backup-offsite.timer
sudo systemctl enable --now svtms-certbot-renew.timer
```
6) Notes & troubleshooting

- Ensure `DATA_ROOT` in `infra/.env` points to persistent disk with enough free space for backups and uploads.
- Run `infra/scripts/verify_backup.sh` after each backup and test restore into staging regularly.
- Use `infra/scripts/restore_drill.sh` to prepare a disposable restore rehearsal workspace before doing a real restore test.
- If you use a registry, set `IMAGE_REGISTRY` and `IMAGE_TAG` in `infra/.env`.
- `deploy_stack.sh` now prefers pulling prebuilt images by default; set `PREFER_PREBUILT_IMAGES=false` only if you intentionally want server-side builds.

---
If you want, I can:
- Add an `infra/docker-compose.prod.yml` to run MySQL + backend + nginx reverse proxy on the server.
- Create a `systemd` file that pulls new image, stops old container, and restarts on update.

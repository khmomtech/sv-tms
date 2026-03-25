Helper deploy scripts
---------------------

This folder contains simple helper scripts you can copy to the VPS and run to perform common operations.

- `start-backend.sh`: Start the backend using the compose file at `/opt/sv-tms/docker-compose.yml` if present, otherwise tries `systemctl start tms-backend`.
- `reload-nginx.sh`: Installs `nginx-ws-sockjs.conf` from this folder into `/etc/nginx/sites-available` and reloads nginx.
- `backup-db.sh`: Attempts to dump MySQL. Prefers a running `mysql` docker container, falls back to local `mysqldump`.

Usage (on the VPS):

```bash
sudo cp deploy/* /opt/sv-tms/deploy/
cd /opt/sv-tms/deploy
sudo bash start-backend.sh
sudo bash reload-nginx.sh
sudo bash backup-db.sh
```

Customize the scripts if your service names or container names differ.

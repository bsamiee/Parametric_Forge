# [HOSTINGER_DEPLOYMENT]

SSH-first deployment for Dockerized applications on a Hostinger VPS: SSH plus Docker Compose carries the deploy, and the Hostinger API carries account-level infrastructure — keys, firewalls, snapshots. A repo that already ships compose files and deployment scripts deploys over SSH; the Docker Manager API serves quick prototyping and simple single-container deploys from a URL. A working SSH workflow is never replaced with the Docker Manager API unbidden, and a repo's own deployment scripts and runbooks run before any generic command below.

## [01]-[INPUTS_AND_ACCESS]

Deployment inputs are `HOSTINGER_API_TOKEN`, the VM id, `SSH_USER@SSH_HOST`, the key path, and the remote app directory. On this estate SSH rides the universal key in `~/.ssh/config`, so a configured host alias replaces explicit `-i` flags. Key provisioning for a new box is API work: register the public key, attach it to the VM, then verify with `ssh <host> "echo SSH_OK && hostname"`.

## [02]-[BASELINE]

First-time box preparation, idempotent by construction:

```bash template
ssh $SSH_USER@$SSH_HOST << 'SETUP'
command -v docker >/dev/null || { curl -fsSL https://get.docker.com | sh; systemctl enable --now docker; }
docker compose version >/dev/null 2>&1 || { apt-get update && apt-get install -y docker-compose-plugin; }
mkdir -p ~/app
docker --version && docker compose version
SETUP
```

Baseline gates before the first deploy:

- Docker engine and compose plugin present.
- App directory exists.
- `.env` exists with non-empty values for every required key.
- Firewall accepts SSH and the app ports only.
- Database ports stay internal to the Docker network unless explicitly required.

## [03]-[DEPLOY_AND_UPDATE]

Deploys keep one order — dependencies, migrations, app — and every command stays idempotent. `docker compose up -d` recreates only changed services; `docker compose down -v` destroys volumes and data and never runs in production without explicit approval.

```bash template
# Sync code (never .env from git; scp the production env file separately)
rsync -avz --exclude='.git' --exclude='node_modules' --exclude='.env.local' ./ $SSH_USER@$SSH_HOST:~/app/
scp .env.production $SSH_USER@$SSH_HOST:~/app/.env

ssh $SSH_USER@$SSH_HOST << 'DEPLOY'
cd ~/app
docker compose up -d db redis          # dependencies first
docker compose run --rm app npm run migrate
docker compose up -d                   # application services
docker compose ps && docker compose logs --tail=50
DEPLOY
```

Updates follow the same order with `docker compose pull` (registry images) or a fresh rsync (local builds) ahead of `docker compose up -d --build` and any new migrations.

## [04]-[VERIFY]

Three levels, infrastructure to functionality:

1. Container health: `docker compose ps` shows every service `Up` or `healthy`; `docker compose ps --format json | jq '.[] | select(.State != "running")'` catches restart loops.
2. Application logs: `docker compose logs --tail=200 app`, plus a grep for `error|fatal|exception` across services.
3. Functional smoke: `curl -sf https://app.example.com/health` from outside, or `curl -sf http://localhost:3000/health` on-box; an application-specific end-to-end probe from the client surface closes the check.

## [05]-[ROLLBACK]

Before every risky deploy — migrations, major version bumps — two safety nets: a VPS snapshot via the API (`POST .../snapshot`; the new snapshot overwrites the old) and an on-box database dump (`docker compose exec db pg_dump -U postgres mydb > /tmp/backup_$(date +%Y%m%d_%H%M%S).sql`).

Failed-deploy recovery, smallest hammer first: restore the previous compose or image version (`git checkout HEAD~1 -- docker-compose.yaml` or the previous tag), `docker compose up -d`, restore the DB dump when a migration proved incompatible, then re-verify. A full snapshot restore via the API is the nuclear option — it overwrites the entire VM.

## [06]-[LANE_SPLIT]

| [INDEX] | [OPERATION]                       | [LANE]                     |
| :-----: | :-------------------------------- | :------------------------- |
|  [01]   | Deploy or update the app          | SSH                        |
|  [02]   | Migrations, logs, container shell | SSH                        |
|  [03]   | SSH keys, firewalls               | API                        |
|  [04]   | Snapshots and backups             | API                        |
|  [05]   | VM status, restart                | Either; API for automation |
|  [06]   | Monarx malware scanner            | API                        |

Standing safety rows:

- Secrets enter commands as environment variables and never print.
- `.env` files never land in git.
- Critical env keys validate non-empty before deploy.
- Database schema changes are the riskiest step and always follow the snapshot.

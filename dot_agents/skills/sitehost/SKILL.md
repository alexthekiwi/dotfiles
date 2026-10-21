---
name: sitehost
description: SSH into SiteHost cloud containers to debug errors, check logs, inspect configs, restart services, deploy code, and manage hosted sites. Use for any server administration task on a SiteHost container — debugging a hosting issue, checking logs, restarting nginx/php/node, or deploying — when the user names a site or container.
allowed-tools: Bash(ssh:*), Bash(grep:*), Bash(cat:*), Bash(tail:*), Bash(head:*), Bash(find:*), Bash(ls:*), Bash(curl:*)
---

# SiteHost Cloud Container Management

## SiteHost API

Base URL: `https://api.sitehost.nz/1.5/`
Most endpoints use GET with query params; a few (e.g. `server/change_state`) are POST with form fields. Always include `apikey` and `client_id`. Endpoint reference: https://docs.sitehost.nz/api/v1.5/ (`?path=/server/change_state&action=POST` style URLs show parameters).

Read credentials from the active environment or the machine-local, untracked `~/.config/sitehost/credentials.env` (owner-only permissions). If neither is configured, ask for secure provisioning; never request or print the key in chat or store it in a skill.

The API key only accepts requests from the Caretakers bastion's IP. Calls from anywhere else fail with `Unauthorised. You cannot use this Api Key from your location.` Route API calls through a SOCKS tunnel to the `bastion` SSH host so the key stays local and the bastion only relays TLS:

```bash
# Load only if SITEHOST_API_KEY / SITEHOST_CLIENT_ID are not already set.
set -a; source ~/.config/sitehost/credentials.env; set +a

# Open the tunnel (long-running; stop it when done)
ssh -N -D 127.0.0.1:1080 -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 bastion

# Common curl pattern
curl -s --socks5-hostname 127.0.0.1:1080 "https://api.sitehost.nz/1.5/{endpoint}?apikey=${SITEHOST_API_KEY}&client_id=${SITEHOST_CLIENT_ID}&{params}"

# POST pattern (form body on stdin keeps the key out of argv)
printf 'apikey=%s&client_id=%s&name=%s&state=%s' "$SITEHOST_API_KEY" "$SITEHOST_CLIENT_ID" ch-care-01 reboot \
  | curl -s --socks5-hostname 127.0.0.1:1080 -X POST --data-binary @- https://api.sitehost.nz/1.5/server/change_state.json
```

All example `curl` commands below assume the `--socks5-hostname 127.0.0.1:1080` flag.

### Discovery Workflow

When the user mentions a site name, use the API to find the right container and server before SSH'ing in:

**Step 1: Find the SSH user and container**
```bash
# List all SSH users (filter by server if known)
curl -s "https://api.sitehost.nz/1.5/cloud/ssh/user/list_all.json?apikey=${SITEHOST_API_KEY}&client_id=${SITEHOST_CLIENT_ID}" | python3 -c "
import json,sys
data = json.load(sys.stdin)
for u in data['return']['data']:
    print(f\"{u['server_name']:15} {u['username']:20} containers={u.get('containers',[])}\")"
```

To find a specific user, grep or filter by username. The SSH username is typically the site name or a short alias.

**Step 2: Get container/stack details (image, label/domain, state)**
```bash
# stack name = container ID from SSH user's containers list
curl -s "https://api.sitehost.nz/1.5/cloud/stack/get.json?apikey=${SITEHOST_API_KEY}&client_id=${SITEHOST_CLIENT_ID}&server={server_name}&name={stack_name}"
```
The `label` field contains the domain name. The container image tells you the stack (php version, node, wordpress, etc).

### Key API Endpoints

| Endpoint | Method | Key Params | Use |
|----------|--------|------------|-----|
| `cloud/stack/list_all.json` | GET | `filters[server_name]` (optional) | List all stacks/containers |
| `cloud/stack/get.json` | GET | `server`, `name` | Get stack details (label=domain, image, state) |
| `cloud/stack/restart.json` | GET | `server`, `name`, `containers[]` | Restart a container |
| `cloud/stack/start.json` | GET | `server`, `name`, `containers[]` | Start a container |
| `cloud/stack/stop.json` | GET | `server`, `name`, `containers[]` | Stop a container |
| `cloud/ssh/user/list_all.json` | GET | `filters[server_name]`, `filters[username]` | List SSH users |
| `cloud/ssh/user/get.json` | GET | `server_name`, `username` | Get SSH user details |
| `cloud/stack/environment/get.json` | GET | `server`, `project`, `service` | Get env vars for a stack |
| `server/list_servers.json` | GET | (none) | List all servers |
| `server/get_state.json` | GET | `name` | Server power state (`On` even when the host is unresponsive) |
| `server/change_state.json` | POST | `name`, `state` (`power_on`, `power_off`, `reboot`, `rescue_on`, `rescue_off`) | Reboot/power a whole server. Restarts every container on it; needs explicit user approval |

### Servers

| Server Name | Label | IP | Purpose |
|-------------|-------|-----|---------|
| `ch-care-01` | care-01 | 223.165.64.179 | Caretakers (Alex's business) sites |
| `ch-squid` | squid | 120.138.18.205 | Squid Marketing agency sites |

## SSH Access

Each site has its own isolated Docker container with a dedicated SSH user.

```bash
# SSH command format (always use -T for non-interactive)
ssh -T {user}@{server_ip} '{command}'

# Multi-command
ssh -T {user}@{server_ip} 'cmd1 && cmd2'
```

Server IPs:
- care-01: `223.165.64.179`
- squid: `120.138.18.205`

### Never fan out SSH across many containers

Each SiteHost SSH user has its own image, and every login appears to start a login container on the host. On 2026-10-22 two SSH sweeps across care-01 (first 12 parallel, then ~25 serial logins) took the whole server offline twice: ports open, SSH stuck at banner exchange, every site timing out, API still reporting `On`/`Up`. Both times only a reboot recovered it.

- For multi-site inventory (image versions, PHP versions, states), use the API: containers on the same image tag run the same software, so verify one container per tag.
- Use HTTPS (`curl -o /dev/null -w '%{http_code}'`) for availability checks.
- When SSH is genuinely needed, use one session at a time to the specific site and stop at the first banner timeout.

## Container Filesystem

Everything persistent lives under `/container/`:

```
/container/
├── application/     # App code (web root varies by framework)
├── config/
│   ├── nginx/
│   │   ├── nginx.conf              # NEVER modify — main http{} wrapper, includes sites-enabled/*
│   │   └── sites-enabled/default   # Site vhost config — THIS is what you edit
│   ├── supervisord.conf      # Process manager config
│   ├── ssmtp/                # Mail relay config
│   └── rsyslog/              # Syslog config
├── logs/
│   ├── nginx/        # access.log, error.log
│   ├── php-fpm/      # php-fpm.log (PHP sites only)
│   ├── supervisor/   # Per-process stdout/stderr logs
│   ├── rsyslog/
│   └── sitehost/
├── backups/
├── crontabs/
└── system/
```

## Identifying the Stack

The container image tells you everything about the stack:
- `sitehost-php{VER}-nginx` = PHP + Nginx (Laravel, Statamic, Silverstripe, Craft, etc.)
- `sitehost-php{VER}-wordpress` = WordPress (PHP + Apache-style, but actually Nginx)
- `sitehost-nginx-nodejs{VER}` = Node.js + Nginx reverse proxy
- `nginx-php-{VER}-puppeteer` = PHP + Nginx + Puppeteer (custom image)

Quick identification via SSH:
```bash
# What's running?
supervisorctl status
# PHP version?
php -v 2>/dev/null | head -1
# Node version?
node -v 2>/dev/null
# What's the nginx config?
cat /container/config/nginx/sites-enabled/default
```

## Process Management (supervisord)

All containers use supervisord. Common processes:

**PHP sites:** `nginx`, `php`, `cron`, `rsyslog`, `cleartmp`
**Node sites:** `nginx`, `{app-name}` (e.g. `nextjs`, `n8n`), `cron`, `rsyslog`
**Craft CMS:** Also runs `craft-queue-worker` (multiple instances)

```bash
supervisorctl status                        # Check all processes
supervisorctl restart nginx                 # Restart nginx
supervisorctl restart php                   # Restart PHP-FPM
supervisorctl restart {app-name}            # Restart Node app
cat /container/logs/supervisor/{proc}-stdout.log  # Process stdout
cat /container/logs/supervisor/{proc}-stderr.log  # Process stderr
```

## Debugging Playbook

### 502 Bad Gateway
1. `supervisorctl status` - is the upstream process running?
2. PHP: `ls -la /var/run/php*-fpm.sock` - socket exists?
3. Node: `ss -tlnp | grep {port}` - listening?
4. `tail -50 /container/logs/nginx/error.log`
5. `tail -50 /container/logs/supervisor/{process}-stderr.log`

### 500 Internal Server Error
Framework error logs:
- **Laravel/Statamic:** `tail -100 /container/application/storage/logs/laravel.log`
- **Silverstripe:** check php-fpm log or app-level log
- **Craft CMS:** `tail -100 /container/application/storage/logs/web.log`
- **WordPress:** `tail /container/application/public/wp-content/debug.log`
- **Node:** `tail -100 /container/logs/supervisor/{app}-stderr.log`

Then: `tail -50 /container/logs/php-fpm/php-fpm.log` and `tail -50 /container/logs/nginx/error.log`

### 404 Not Found
1. Check nginx root vs actual file structure
2. Check `try_files` directive
3. Verify `index.php` exists in web root
4. Check file permissions: `ls -la {web_root}/`

### Slow Response / Timeouts
1. `top -bn1 | head -20` / `free -m` / `df -h`
2. Nginx timeout settings in config
3. PHP: `php -i | grep max_execution_time`

## Web Roots by Framework

| Framework | Typical Web Root |
|-----------|-----------------|
| Laravel / Statamic | `/container/application/public` |
| Craft CMS | `/container/application/web` |
| WordPress | `/container/application/public` |
| Silverstripe | `/container/application/public` (sometimes nested, e.g. `src/public`) |
| Node (Next.js, n8n) | Proxied via Nginx, no static root |

## Common Operations

```bash
# Laravel: clear caches
cd /container/application && php artisan cache:clear && php artisan config:clear && php artisan view:clear && php artisan route:clear

# Laravel: run migrations
cd /container/application && php artisan migrate --force

# Craft CMS: clear caches
cd /container/application && php craft clear-caches/all

# WordPress CLI
cd /container/application/public && wp cache flush

# Check crontab
cat /container/crontabs/*

# Check disk usage
df -h /container

# View nginx config
cat /container/config/nginx/sites-enabled/default

# View supervisor config
cat /container/config/supervisord.conf
```

## Important Notes

- SSL terminates at the SiteHost load balancer, NOT in the container. Nginx listens on port 80 only. HTTPS detected via `X-Forwarded-Proto` header.
- Containers are Docker-based with limited system commands. No systemctl, no apt-get.
- Files outside `/container/` are NOT persistent across reboots.
- `cleartmp` showing EXITED is normal (runs once at boot).
- Always use `ssh -T` for non-interactive command execution.
- **These are LIVE production sites. Do not modify configs or restart services without explicit user instruction.**
- **NEVER modify `/container/config/nginx/nginx.conf`** — it is the main nginx wrapper (`http {}` block, includes, logging). Only edit site configs in `/container/config/nginx/sites-enabled/` or `/container/config/nginx/sites-available/`. If `nginx.conf` gets corrupted, restore from another container (e.g. `caretakersweb` on care-01).

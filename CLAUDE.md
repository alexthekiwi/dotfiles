# Alex's Homelab

These notes apply to homelab services and this Mac's infrastructure. For unrelated client repositories or agent-configuration work, follow the target project's instructions instead. Sessions may be local or remote; use the active environment rather than assuming SSH.

## Hardware

- Apple Mac Mini M4 (16GB RAM, 256GB SSD) running macOS (Darwin)
- WD 5TB external HDD mounted at /Volumes/Media (HFS+, bus-powered USB)
- Located in Auckland, NZ

**Primary purpose:** Home media server — live system actively used by the household for streaming. Secondary purpose: hosting internal business apps.

## Architecture

Business apps and infrastructure run natively (pm2 / brew services). Docker is only used for the media stack. This separation means a Docker/OrbStack failure only affects media services.

**Detailed architecture, service management, and troubleshooting docs:** `~/homelab/docs/README.md`

### Native Services (pm2)
| Service | Port | Config |
|---------|------|--------|
| Shed API | 3001 | `apps/shed/ecosystem.config.cjs` |
| Shed Web | 3000 | `apps/shed/ecosystem.config.cjs` |
| Uptime Kuma | 3002 | pm2 CLI args |

### Native Services (brew services)
| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL 16 | 5432 | Shared database (shed, insureos, fine_ants, homelab) |
| Mailpit | 1025 (SMTP), 8025 (UI) | Local email testing |
| Cloudflared | — | Cloudflare tunnels |

### Native Services (launchd)

Naming has drifted over time. Three live conventions: `co.nz.alexclark.*` (newest), `com.homelab.*` (older homelab daemons), `com.caretakers.*` / `com.fineants.*` / `com.orbstack.*` (per-app). All are user LaunchAgents in `~/Library/LaunchAgents/` unless marked **(system)** which live in `/Library/LaunchDaemons/`. Audited 2026-05-02.

| Label | Schedule | Purpose |
|-------|----------|---------|
| `co.nz.alexclark.collect-metrics` | every 60s | runs `~/homelab/scripts/collect-metrics.sh` |
| `co.nz.alexclark.jellyfin` | KeepAlive | runs Jellyfin natively from `/Applications/Jellyfin.app` |
| `co.nz.alexclark.tailscale-autostart` | at login | starts Tailscale on login |
| `co.nz.alexclark.radarr-anchor` | daily 04:00 | `~/homelab/scripts/radarr-anchor.sh` |
| `co.nz.alexclark.qbit-evening-pause` | daily 21:30 | stops all qBit torrents (added 2026-05-02 to fix evening movie buffering — qBit's peer churn was thrashing the bus-powered media drive) |
| `co.nz.alexclark.qbit-evening-resume` | daily 00:00 | starts all qBit torrents back up. `/torrents/stop` is non-destructive, ratio is preserved across the pause window |
| `co.nz.alexclark.jellyfin-playback-throttle` | KeepAlive (10s poll) | **playback-aware** torrent pause — stops all qBit torrents whenever a Jellyfin session is actively playing, resumes when it ends. Closes the gap the *time-based* 21:30 evening-pause left open (early-evening viewing got no protection — the hole behind the 2026-06-16 Scream 3 collapse). Coexists with the evening pause: only resumes torrents **it** paused, never resumes inside the 21:30–00:00 window, re-asserts stop each poll (survives the 00:00 evening-resume firing mid-movie). Zombie-session guard via `LastPlaybackCheckIn` staleness. Added 2026-06-16. **Updated 2026-07-15**: also pauses on an active **transcode** (`pgrep -x ffmpeg` — an actual play *attempt*, caught even while the stream is still buffering), not just confirmed playback — closes the self-perpetuating buffering-stall blind spot (saturated drive → stream never buffers → session never registers → torrents never paused) behind the Megamind collision. NB the check must be `pgrep -x ffmpeg`, not `-f`, or it matches the Jellyfin parent (argv has `--ffmpeg /…/ffmpeg`) and pins torrents paused 24/7. Script: `~/homelab/scripts/jellyfin-playback-throttle.sh`. Log: `~/homelab/logs/jellyfin-playback-throttle.log`. Detail: wiki `Homelab - Playback throttle blind to buffering stalls 2026-07-15` |
| `co.nz.alexclark.reassert-disabled-daemons` **(system)** | boot + daily 04:00 | re-asserts `mdutil -a -i off` + `launchctl disable mediaanalysisd*`. Defends against macOS updates resetting disabled state. Script: `~/homelab/scripts/reassert-spotlight-disable.sh`. Log: `~/homelab/logs/reassert-disabled-daemons.log` |
| `co.nz.alexclark.kcpassword-restore` **(system)** | boot | restores `/etc/kcpassword` from `/var/root/.kcpassword.bak` if missing. Fixes silent auto-login failure that requires physical keyboard Enter after reboots. Script: `/usr/local/bin/kcpassword-restore.sh`. Log: `/var/log/kcpassword-restore.log` |
| `co.nz.alexclark.mediaanalysisd-watchdog` | every 20s | kills `mediaanalysisd`/`-access` whenever macOS on-demand-respawns them (it **ignores `launchctl disable`** for these agents — confirmed disabled in both user/501 + gui/501 yet still spawns). Their file-analysis I/O collapses the bus-powered drive. Added 2026-06-15. User LaunchAgent (no sudo; mediaanalysisd is uid 501). Script: `~/homelab/scripts/mediaanalysisd-watchdog.sh`. Log: `~/homelab/logs/mediaanalysisd-watchdog.log` |
| `com.homelab.media-watchdog` | KeepAlive | `~/homelab/scripts/media-drive-watchdog.sh` — two failure modes: (1) **stale mount** (`stat` hangs) → force-umount + remount + bounce **native** Jellyfin (was a dead `docker restart jellyfin` — fixed 2026-06-16); (2) **throughput collapse** (`stat` instant but reads crawl — the power-starvation mode `stat` can't see) → a 120s timed read-probe (skipped during playback, 2× confirm, <~3.2 MB/s threshold) → sheds load (pauses torrents) + bounces Jellyfin + logs that a **physical replug** is needed (software can't cure the 896/900 mA power deficit). Logs a `throughput OK` heartbeat ~every 10 min. Updated 2026-06-16 |
| `com.homelab.snapshot-sqlite` | 00/06/12/18:00 daily | 6-hourly integrity-verified backups of *arr DBs |
| `com.homelab.checkpoint-arr-dbs` | every 6h | additional WAL checkpoint pass on arr DBs |
| `com.homelab.backup-databases` | daily 03:00 | full backup to DigitalOcean Spaces (`homelab-cold` bucket) |
| `com.homelab.download-snapshots` | every 30 min | qBit downloads metric snapshot |
| `com.homelab.docker-prune` | Sundays 04:00 | weekly image/builder prune (uses `/usr/local/bin/docker` — launchd's PATH lacks it) |
| `com.caretakers.claude-proxy` | KeepAlive | node proxy on :9002 forwarding to Claude CLI for "Ask The Shed". Source: `~/homelab/apps/shed/claude-proxy/index.js` |
| `com.fineants.serve` | KeepAlive | `php artisan serve` on :4445 (fronted by Caddy on :4444 with HTTPS) |
| `com.fineants.queue` | KeepAlive | `php artisan queue:work` |
| `com.fineants.scheduler` | every 60s | `php artisan schedule:run` |
| `com.orbstack.healthcheck` | (KeepAlive) | recovers OrbStack from stale sockets/locks after unclean shutdowns |
| `pm2.alex` | login | `pm2 resurrect` — brings back shed-api/shed-web/uptime-kuma. Note: shows as not auto-loaded by launchctl but pm2 itself stays alive across logins |
| `co.nz.alexclark.nas-automount` **(system)** | boot + every 300s | mounts the two NAS NFS exports (`/Volumes/NAS-Movies`, `/Volumes/NAS-TV`), self-healing, bare-mountpoint chmod-000 guard. Script: `~/homelab/scripts/nas-automount.sh`. Added 2026-07-18 (NAS cutover) |
| Disabled: `co.nz.alexclark.wiki-auto-ingest`, `co.nz.alexclark.wiki-weekly-lint` | — | retired 2026-04-21 with the auto-ingest pipeline. `.plist.disabled` suffix |
| Disabled 2026-07-18 (NAS cutover — external-drive protection era ended): `co.nz.alexclark.qbit-evening-pause`, `co.nz.alexclark.qbit-evening-resume`, `co.nz.alexclark.jellyfin-playback-throttle`, `com.homelab.media-watchdog` | — | all `.plist.disabled`. Premise obsolete: qBit + Jellyfin are NAS-only; these actively harmed (paused private-tracker seed-time clocks, aborted rechecks). See wiki `Homelab - NAS cutover night 2026-07-18` |

### Docker (media stack only) — compose: `~/homelab/docker-compose.yml`
| Service | Port | Purpose |
|---------|------|---------|
| Jellyfin | 8096 | Media server |
| qBittorrent | 8080 | Downloads |
| Prowlarr | 9696 | Indexer manager |
| Radarr | 7878 | Movies |
| Sonarr | 8989 | TV |
| Bazarr | 6767 | Subtitles |
| Jellyseerr | 5055 | Media requests |
| Huntarr | 9705 | Automated searching |
| FlareSolverr | 8191 | Cloudflare bypass for indexers |
| Whoogle | 8888 | Self-hosted search |
| Minecraft | 19132/udp | Bedrock server |

## Storage

**Primary (since 2026-07-18): Synology DS220+ `homelab-nas` @ 192.168.68.110**, 2× independent 7 TB Btrfs volumes:
- `/Volumes/NAS-Movies` (host NFS mount of `:/volume2/media-movies`) — movies + movie downloads. In containers: Docker **named NFS volume** `nas-movies` → `/data-movies`
- `/Volumes/NAS-TV` (host NFS mount of `:/volume1/media-tv`) — tv + tv downloads. In containers: `nas-tv` → `/data-tv`
- Hardlinks are **intra-volume only** — movie payloads stay on the movies volume, TV on TV (qBit per-category save paths enforce this)
- **Never bind-mount `/Volumes/NAS-*` into OrbStack** — VirtioFS-over-NFS wedges the VM (RCU stall). Only the Docker native NFS volumes (with `nolock`)
- Native Jellyfin reads the host `/Volumes/NAS-*` mounts directly (needed the TCC **Network Volumes** consent — a VNC click; not grantable via TCC.db)

**Retired: WD 5TB external** (`/Volumes/Media`, the old unified `/data` mount) — cold backup ~1 month from 2026-07-18, then repurpose. Eject cleanly before unplugging. The `/data` firmlink dangles harmlessly.

## Network Access

- Local: `http://192.168.68.58:PORT`
- Tailscale: `http://homelab:PORT`
- Public: via Cloudflare Tunnels (route directly to app ports, no reverse proxy)
- **Router port-forward (Deco):** external `6881` TCP+UDP → `192.168.68.58:6881` for qBittorrent BT inbound (connectability/ratios). Manual rule — qBit UPnP is off; DHCP reservation keeps the Mac at `.58` but does **not** itself forward ports. First thing to check if a private tracker reports you unconnectable. Detail: wiki `Homelab - qBittorrent` + `Homelab - OrbStack port-forward socket leak 2026-06-22`.

### Cloudflare Tunnels (two accounts)
| Tunnel | Config | Domains |
|--------|--------|---------|
| alexclark | dashboard-managed¹ | media.alexclark.co.nz → :8096, medialib.alexclark.co.nz → :5055, z.alexclark.co.nz → :4010 (Zen public quote accept page) |
| caretakers | `~/.cloudflared/config-caretakers.yml` | shed.caretakers.io → :3000, shed-api.caretakers.io → :3001 |

¹ The **alexclark** tunnel is **remotely managed** via the Cloudflare Zero Trust dashboard — its `~/.cloudflared/config.yml` ingress is ignored at runtime (it logs `Updated to new configuration version=N`). `z.alexclark.co.nz` is a dashboard catch-all forwarding the whole host to Zen on :4010; the rest of Zen stays tailnet-only because the **app** 404s any non-`/q/*` path on that host (`ZenWeb.PublicHostFirewall`). Edit path exposure in the app, not cloudflared.

Restart tunnels:
```bash
launchctl stop homebrew.mxcl.cloudflared && launchctl start homebrew.mxcl.cloudflared
launchctl stop com.cloudflare.cloudflared-caretakers && launchctl start com.cloudflare.cloudflared-caretakers
```

### Client server SSH (via Caretakers bastion)

This Mac Mini can SSH into client servers that whitelist a single fixed IP, by jumping through the **Caretakers AWS egress bastion** (egress = EIP `3.102.104.3`). All set up in `~/.ssh/config`:

```bash
ssh sport    # dsc, noja, nww     (DigitalOcean/AWS)
ssh sis-prod # sis-test, sis-leg  (Star Insure Azure)
```

- **Jump hop** (`bastion`) is **keyless** — Tailscale SSH over the personal tailnet (the bastion is node-shared in from the `caretakers.io` tailnet).
- **Second hop** (`forge@<target>`) auths via the **1Password SSH agent** (key "SSH Key - Alex's Macbook"). Requires the **1Password desktop app running + unlocked** — after a reboot, unlock it via VNC or `ssh sport` fails with `Permission denied (publickey)`. Check the agent: `SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ssh-add -l`.
- Full detail + the Tailscale-SSH-over-sharing gotcha: wiki `Homelab - Mac Mini bastion SSH access`.

## Database

PostgreSQL 16 runs natively via Homebrew on port 5432.

```bash
# Connect
psql -U homelab -d shed

# From MacBook (SSH tunnel)
ssh -L 5432:localhost:5432 alex@homelab
```

- **PostgreSQL**: user `homelab` — password in `~/homelab/.env` (`POSTGRES_PASSWORD`)
- **Databases**: shed, insureos, fine_ants, homelab

## Backups

- **Daily at 3:00 AM** via launchd → DigitalOcean Spaces (`homelab-cold` bucket)
- **What:** PostgreSQL (pg_dumpall), Jellyfin/Plex/Sonarr/Radarr/Prowlarr/Bazarr/Jellyseerr (SQLite), qBittorrent config
- **6-hourly SQLite snapshots:** Jellyfin, Plex, Sonarr, Radarr, Prowlarr, Bazarr, Jellyseerr; integrity verified
- **Retention**: 7 days local, 30 days in Spaces

```bash
~/homelab/scripts/backup-databases.sh     # Manual backup
~/homelab/scripts/restore-database.sh postgres  # List/restore
```

## Deploy Shed

```bash
cd ~/homelab/apps/shed && bash deploy.sh
```

This pulls latest code, builds, runs migrations, and restarts via pm2.

## Media Drive (RETIRED 2026-07-18 — historical)

The bus-powered WD external and its whole protection apparatus (media-drive-watchdog, playback throttle, evening wind-down) are retired — media lives on the NAS now. The notes below matter only if the external is remounted (cold-backup access):

**Known issue:** Bus-powered USB drive disconnects under heavy I/O.

**macOS daemons to keep disabled** (they saturate drive I/O):

- `mediaanalysisd` (+ `mediaanalysisd-access`) — kill with `kill -9 <pid>` (no sudo needed for user-owned), then prevent respawn:
  ```
  sudo launchctl disable user/501/com.apple.mediaanalysisd
  sudo launchctl disable user/501/com.apple.mediaanalysisd-access
  ```
- Spotlight (`mds`, `mds_stores`) — must disable indexing on **all volumes**, not just `/Volumes/Media`. Per-volume `mdutil -i off` is not enough; mds_stores will still scan other mounts and saturate I/O:
  ```
  sudo mdutil -a -i off
  ```
  Cannot `launchctl bootout` mds — SIP blocks it. Killing mds_stores PIDs is whack-a-mole; with indexing globally off it idles instead of respawning hot.

**Symptom of resurgence:** drive throughput drops to 1-3 MB/s (should be 80+), mds_stores at 100%+ CPU, mediaanalysisd at 60%+ CPU, Jellyfin slow to start. Run `ps aux | sort -k 3 -rn | head` to confirm.

**Procedure if it recurs (typically after macOS update / reboot):**
1. `kill -9` any user-owned mediaanalysisd processes
2. `sudo mdutil -a -i off` (re-assert global)
3. `sudo launchctl disable user/501/com.apple.mediaanalysisd*` (re-assert)
4. The existing mds_stores PIDs will go idle within seconds since indexing has nothing to do

## Docker Volumes (SQLite protection)

All *arr stack + Jellyfin + Bazarr configs use Docker named volumes (not bind mounts) to avoid VirtioFS SQLite corruption. See `docs/README.md` for volume names.

## Directory Structure

```
~/homelab/
├── docker-compose.yml      # Media stack only
├── apps/
│   ├── shed/               # The Shed (pm2, ecosystem.config.cjs, deploy.sh)
│   ├── uptime-kuma/        # Uptime Kuma (pm2)
│   ├── claude-proxy/       # Claude CLI proxy (launchd)
│   └── openclaw-viewer/
├── docs/
│   ├── README.md           # Full architecture docs + troubleshooting index
│   └── troubleshooting/    # Historical incident docs (date-prefixed)
├── backups/                # Local database backups
├── scripts/
│   ├── backup-databases.sh
│   ├── restore-database.sh
│   ├── snapshot-sqlite.sh
│   └── media-drive-watchdog.sh
├── config/                 # Service configs (qbittorrent, huntarr, jellyseerr, traefik)
├── data/                   # Local data dirs (minecraft, uptime-kuma archive)
└── logs/
```

## Knowledge Base (Obsidian Wiki)

A standalone homelab-only Obsidian vault lives at `~/homelab/vault/`. **Single-domain** — no `domains/` folder, pages are flat under `wiki/`. Not synced; local to this Mac Mini. The `claude-obsidian` plugin (user-scope) provides `/wiki` and sub-skills — invoked from *inside* the vault dir only.

```
~/homelab/vault/
├── wiki/
│   ├── Homelab.md       # homepage
│   ├── index.md         # master catalog
│   ├── hot.md           # recent-context cache
│   ├── log.md           # operation log (newest on top)
│   ├── concepts/        # architecture, troubleshooting, how-things-work
│   ├── entities/        # services, hardware
│   ├── decisions/       # ADR-style
│   ├── sources/
│   └── meta/
├── .raw/homelab/        # any raw source material you want to ingest
└── CLAUDE.md            # vault conventions
```

Keep filename prefix `Homelab - X.md` for collision safety + backward-compat with existing wikilinks. Set `domain: homelab` in frontmatter.

**When working on homelab issues:**

1. **Check the wiki first — always.** Before diagnosing any homelab issue, grep `~/homelab/vault/wiki/` for prior incidents and related concepts. Most recurring issues are already documented.

2. **After resolving any non-trivial homelab issue, file a wiki page directly.** Write to `~/homelab/vault/wiki/concepts/Homelab - <date or slug>.md` with frontmatter (`type: concept`, `domain: homelab`, `created`, `updated`, `tags`, `status`). Minimum sections: Symptom, Investigation, Root cause, Fix, Prevention. Also add a link to the new page from `wiki/index.md` and a short entry at the top of `wiki/log.md`. This is a **hard requirement** — the wiki's value depends on new content landing there. No page means no compounding knowledge.

3. **What counts as "non-trivial":** anything that took more than a quick command to diagnose, anything involving a service restart/reconfig, anything that'd be painful to rediscover in 3 months. When in doubt, write the page — cheap to produce, expensive to re-derive.

4. **No more auto-ingest / auto-lint pipeline.** Historically `~/homelab/docs/` was the canonical plain-markdown source and a 30-min LaunchAgent rsynced it into the vault. That pipeline has been retired (2026-04-21, plists moved to `.disabled` in `~/Library/LaunchAgents/`). The vault is now written to directly. **Do not write new troubleshooting docs to `~/homelab/docs/`** — that tree is frozen historical content. If you want the old stuff re-ingested into the new vault, drop it in `~/homelab/vault/.raw/homelab/` and invoke `/wiki-ingest` manually from inside the vault.

5. **Querying the wiki from anywhere:** the `wq` shell helper (in `~/.zshrc`) runs a headless wiki-query from inside the vault. Example: `wq "what caused the orbstack wedge in April?"`. `wv` drops into an interactive claude session inside the vault if deeper work is needed. Both now point at `~/homelab/vault/`.

## Critical Rules

1. **Do not cause downtime to media services.** If changes require restarting containers, warn me first and ask for confirmation.
2. **Never delete files, folders, or databases** without explicit confirmation. Always ask first.
3. **You are running as admin with full system access.** Assume any command you run will actually execute.
4. **When modifying docker-compose.yml**, show me the changes before running `docker compose up`. A bad config takes down everything.
5. **Prefer additive changes.** Add new services, don't modify existing ones unless specifically asked.
6. **Resolve routine uncertainty from evidence.** Inspect the wiki and current configuration first. Ask when an unresolved decision materially affects correctness, scope, data, or service availability; continue independent authorised work meanwhile.
7. **Document non-trivial homelab fixes in the wiki.** Follow the Knowledge Base section above. The old `~/homelab/docs/troubleshooting/` tree is historical; its auto-ingest pipeline is retired.

## Alex's Context

Developer (Laravel, React, NestJS). Comfortable with Docker, CLI, and server admin. Be direct and technical — skip basic explanations. If something needs doing, just tell me the commands or do it (within the rules above).

## Knowledge vault availability on this host

The shared routing policy is in `~/.agents/AGENTS.md`. On this Mac:

- Homelab knowledge is local at `/Users/alex/homelab/vault`.
- The Caretakers vault is a local two-way Synology Drive sync at `/Users/alex/SynologyDrive/brain`. Read its root `AGENTS.md` before client work.
- The private Financial and Projects vaults are not synced here. Report them as unavailable rather than searching this Mac or a NAS.

Use these local roots directly. If the Caretakers path is unavailable, report Synology Drive as unavailable rather than accessing NAS volumes or the vault over SSH. Write only to the vault that owns the material; private material never enters the shared Caretakers vault.

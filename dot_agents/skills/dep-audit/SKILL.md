---
name: dep-audit
description: >
  Run a dependency / supply-chain security audit on the current repo. Use when Alex says "/dep-audit",
  "audit this repo", "check for vulnerabilities", "run a security audit", "check our dependencies",
  "any supply-chain issues", "scan deps", or asks to do the bumps and open a security PR. Detects the
  workspace type (Laravel/PHP, Next.js, NestJS, Statamic, Laravel+Inertia, pnpm monorepo), runs the
  native package-manager audit, surfaces outdated deps, and reports in-chat. Can also remediate: do the
  version bumps and open a PR in Alex's voice. Distinct from the
  built-in /security-review, which reviews code diffs for vulnerabilities; this one audits dependencies.
---

# dep-audit — dependency & supply-chain audit

The Caretakers' cheap stand-in for Aikido + Renovate: native package-manager audits for known CVEs,
outdated-dependency surfacing, and a deliberately human-written PR when something needs bumping.

The canonical runbooks live in the wiki under `the-caretakers` and have the full per-stack detail:
`~/Obsidian/caretakers-brain/Wiki/wiki/domains/the-caretakers/concepts/` (use the configured local wiki root if it differs).
- `The Caretakers - Security audit runbook (getting started).md`
- `The Caretakers - Security PR and remediation runbook.md`
- `The Caretakers - Security audit for PHP & Composer stacks.md`
- `The Caretakers - Security audit for Node & JavaScript stacks.md`
- `The Caretakers - Security audit for pnpm monorepos.md`

Read the relevant wiki page when you need the narrative or a framework-specific gotcha. The steps below
are enough to run a full audit standalone.

## Step 1 — Detect the workspace

Look at the repo root (and every workspace package in a monorepo):

- `composer.json` present → **PHP/Composer** stack
- `package.json` present → **Node/JS** stack. Determine the manager from the lockfile:
  - `pnpm-lock.yaml` → pnpm · `yarn.lock` → yarn · `package-lock.json` → npm · `bun.lockb` → bun
- `pnpm-workspace.yaml`, or a `workspaces` field in `package.json` → **monorepo** (audit every workspace, not just root)
- Both `composer.json` and `package.json` → **full-stack** (Laravel+Inertia, or Statamic with a built front-end) → run **both** flows

State what you detected before running anything.

## Step 2 — Native audit (authoritative for known CVEs)

PHP/Composer:
```bash
composer audit --locked --format=plain      # advisories + abandoned packages; add --format=json for structured
```

Node/JS (pick by lockfile):
```bash
pnpm audit --audit-level=high               # pnpm (also covers all workspaces in a monorepo via the shared lock)
npm audit                                   # npm  (do NOT reflexively run `npm audit fix --force`)
yarn npm audit                              # modern yarn  (classic yarn: `yarn audit`)
bun audit                                   # bun
```

Monorepo: `pnpm audit` at root covers all JS workspaces (shared lockfile). If a Laravel app sits in the
tree, `cd` into it and run `composer audit --locked` separately. Use `pnpm why <pkg>` to attribute a
finding to a workspace.

## Step 3 — Outdated check (Renovate-lite, report-only)

```bash
composer outdated --direct --locked         # PHP
pnpm -r outdated                            # pnpm (-r fans out across workspaces)
npm outdated / yarn outdated                # npm / yarn
```

Surface direct deps with newer releases so sensible updates can be folded into the security PR. We do not
auto-merge.

## Step 4 — Preventive control check (pnpm repos)

Confirm `pnpm-workspace.yaml` sets `minimumReleaseAge` — a
release-age quarantine that refuses freshly-published (possibly compromised) versions. Our monorepos use
~3 days (`4320` minutes) with only our own scopes excluded (`@starinsure/*`, `@repo/*`). Absent, `0`, or a
third-party scope in the exclude list is itself a finding — propose adding or tightening it. (All our
monorepos are Turbo over pnpm; Turbo is task orchestration only and doesn't change audit mechanics — still
`pnpm audit` at root + `composer audit` in any `apps/api` Laravel app.)

### Optional Socket supply-chain scoring

When the user requests supply-chain scoring and an authorised Socket MCP is available, score direct dependencies and packages flagged by the native audit. Preserve complete Composer vendor/package names. Treat missing scores as unavailable evidence, not a clean result. Native package-manager audits remain authoritative for known CVEs. If Socket is unavailable, finish the native audit and name the coverage gap; installing a fork or disclosing private dependency metadata requires separate authorisation.

## Step 5 — Report in-chat

No files written. Keep it short: a clean audit is one or two lines ("composer audit clean, nothing outdated that matters"), not a section-by-section report of every check that found nothing. When there are findings, summarise:
- What's vulnerable (per advisory: package, version, CVE).
- **Why it matters to us** — real-world exposure, not just the CVSS. "We don't call X / don't parse
  untrusted Y / Z is dev-only" is the right register. Don't inflate severity, don't hide it.
- Abandoned packages and anything out of scope, called out rather than dropped.
- The bumps that would clear it.
- In a monorepo, group findings by workspace.

## Step 6 — Remediate (only if asked: "do the bumps and make a PR")

Follow `The Caretakers - Security PR and remediation runbook.md`. Short version:

1. Branch (prefix ≠ commit type; pick by what the audit found). Never on the default branch:
   - Advisory remediation (a vuln): `security/<scope>-<YYYY-MM>` batch, or `security/<pkg>-<cve-or-slug>` single.
     E.g. `security/composer-advisories-2026-06`, `security/symfony-cve-48736`.
   - Routine updates (no vuln, just stale): `deps/<scope>-<YYYY-MM>`. E.g. `deps/frontend-bumps-2026-06`.
   - The `-YYYY-MM` (or ticket id) keeps each round unique so batches don't collide.
2. Smallest bumps that clear the advisories. `composer update <pkg> --with-dependencies` / `pnpm update <pkg>`,
   not a blanket update. Major only if no patched release on the current major.
3. Re-run the audit until clean. Capture before/after counts.
4. Run the test suite. If it fails, say so and stop, don't ship a green audit over a red build.
   - **PHP/Composer: resolve against the deploy target's PHP, not your laptop's.** If local PHP > prod PHP
     (e.g. local 8.4, container 8.3), `composer update` can pull packages whose latest release raises the
     PHP floor above prod — a green audit + green tests but a lock `composer install --no-dev` refuses on
     the box. Confirm `composer.json` pins `config.platform.php` to the prod patch version *before* bumping;
     add it if missing. Detail: `The Caretakers - Security audit for PHP & Composer stacks.md` (platform-pin section).
5. Commit: conventional, imperative, lowercase after the type, no trailing full stop, <72 char subject.
   `fix(deps):` for advisory fixes, `chore(deps):` for routine bumps. Subjects can be a bit rough, no
   bodies unless the subject can't carry it. **No AI attribution or Co-authored-by trailers, ever.**
6. Create the requested PR with `gh pr create`. If PR creation is restricted, report the blocker and prepared patch. Publish an issue or fork only when the user explicitly authorises that fallback.

### PR write-up voice (this is the point — it must not read AI-generated)

**Length first: scale to the diff, then cut a third.** One or two packages bumped is a two-sentence
body ("Bumps symfony/http-foundation v7.4.8 → v7.4.13 for CVE-2026-xxxx. Audit comes back clean, tests
pass."), no bullets, no sections. A batch gets a bullet per package and the before/after audit count,
still under ~10 lines. Don't narrate what the diff shows; write what it can't say (the CVE, the
real-world exposure, what was verified).

- **Lists, not tables.** One bullet per package, version change inline (`v7.4.8 → v7.4.13`).
- **No em dashes.** Commas, full stops, colons, parentheses. (The `→` arrow is fine.)
- **Don't bold every line.** All-bold bullets scream bot.
- **Plain prose, lead with the point.** "Ran composer audit again and it still flagged 7 across 5
  packages, so bumped the rest" — not "## Follow-up audit pass — 7 advisories closed".
- **Keep the substance, drop the scaffolding.** CVE IDs and the why-it-matters stay; the `###` heading
  trees and fenced before/after dumps go, quote a line or two inline instead.
- **Honest real-world risk line.** "Risk for us is low: we don't use X, phpunit is dev-only" etc.
- **NZ English, contractions, no corporate filler** (no "leverage", "ensure", "going forward").

The `email-voice` skill carries the same voice rules and is worth a glance for outbound messages.

---
name: vibe-coded-app-review
description: Review an AI-built or founder-built application for a non-technical owner, producing an evidence-backed, time-boxed assessment of security, data access, core reliability, third parties, public claims and operational readiness. Use for vibe-coded app reviews, pre-launch technical health checks, launch-readiness audits and follow-up verification. Do not use for remediation-only work or formal penetration testing.
---

# Vibe Coded App Review

Run a senior-developer review that tells a non-technical owner what is safe, what could hurt users or the business, what must happen before growth, and what remains unverified. Preserve the distinction between the paid client report and the reusable Caretakers methodology.

## Set the boundary

Confirm the time box, deliverable, highest-consequence concern, available access and explicit exclusions. Treat review permission as read-only unless the user separately authorises fixes or test data. Do not change production configuration, rotate credentials, create accounts, run write queries or remediate findings under review-only authority.

Choose the review mode:

- **Standard review:** establish a fresh evidence baseline across code, live platforms, public promises and a focused runtime check.
- **Rapid follow-up:** start from a prior report or known baseline, inspect the changed surface and re-run every open launch gate. Do not compress an unfamiliar application into a one-hour claim merely because the workflow is reusable.

## Build the evidence map

Record four evidence classes before drawing conclusions:

1. **Source:** repository, commit or archive reviewed.
2. **Live configuration:** hosting, database, authentication, storage, functions, backups and access roles inspected directly.
3. **Runtime:** build, test, device or browser behaviour actually exercised.
4. **Promises:** app-store listing, privacy policy, terms, sales material and founder statements.

Tag important claims as code-observed, live-verified, runtime-verified, client-reported or unverified. Never turn repository comments, AI-generated documentation, a successful build or a dashboard label into production proof.

Run `scripts/collect_repo_baseline.py <repo>` for a safe, non-executing inventory when the repository is available. The script reads manifests and filenames, does not install dependencies, execute project code or print secret contents. Follow with the smallest native checks justified by the stack.

Read [references/severity-and-evidence.md](references/severity-and-evidence.md) before classifying findings.

## Follow the harm model

Identify who relies on the app, what sensitive data or money it handles, and the most harmful plausible false success. Let that shape the deep review rather than applying every checklist item equally.

Read [references/review-playbook.md](references/review-playbook.md) for the baseline areas and risk-specific prompts. Inspect the paths that can create:

- cross-user or cross-tenant access;
- silent failure of a safety, financial or communication promise;
- irreversible loss, incorrect history or misleading status;
- unbounded cost or third-party abuse;
- inability to release, restore or regain account access;
- public privacy, security or feature claims that the implementation does not support.

For date, notification, billing, deletion and state-transition code, trace the full lifecycle, including failure, retry, cancellation, account switching, inactivity and recovery. A happy-path read is insufficient.

## Inspect live platforms

Repository configuration is not a substitute for live state. With explicit read-only access, inspect the database, authentication, storage, functions, backups, deployment, monitoring, billing and membership configuration that enforces the app's actual boundary.

Use [references/live-platform-checks.md](references/live-platform-checks.md) for Supabase and equivalent managed platforms. Prefer UI inspection, exports and existing logs over write tests. Any test that creates accounts, records, messages, purchases or cost needs separate authority and an exact cleanup plan.

## Compare behaviour with promises

Read current public material. Compare each material claim with the code and live configuration, especially:

- “sent”, “notified”, “deleted”, “private”, “secure”, “automatic”, “backed up” and “works offline”;
- third-party processors, retention, replay, analytics and data residency;
- subscription cancellation, refunds and access periods;
- feature availability versus future-roadmap wording.

Treat semantic mismatches as product or trust findings even when the code functions as written.

## Verify proportionately

Run the smallest checks that exercise the risk:

- build or bundle without deploying;
- project-native type, lint, test and dependency checks;
- unauthenticated endpoint probes that cannot mutate data;
- focused two-user authorisation tests in a non-production environment or with explicitly approved test accounts;
- device checks for notifications, backgrounding, timezones, permissions and app switching.

Do not report an audit count as an equal number of exploitable vulnerabilities. Triage reachability, runtime inclusion, attacker control and compatible fixes. Keep raw credentials, personal data and security tokens out of outputs.

## Deliver the decision

Read [references/report-format.md](references/report-format.md) before writing the client report.

The report must:

- lead with a launch or growth decision;
- state scope, evidence and limitations;
- rank findings using the evidence and severity rules;
- explain impact in plain language;
- give a concrete next step without performing remediation;
- distinguish confirmed issues from live checks still required;
- include sound controls so the report is balanced;
- end with an ordered release or remediation sequence.

Keep the client report useful without disclosing the complete reusable checklist or internal review machinery. Provide precise file, configuration or public-source evidence where it helps the owner or a future developer act.

## Capture process learning

After delivery, record only demonstrated process improvements:

- checks that found material risk;
- checks that produced noise or false confidence;
- missing intake or access that delayed evidence;
- reusable scripts or report sections that saved time;
- app-specific branches that should stay conditional.

Update this skill narrowly from observed failures or repeated value. Do not turn one client's architecture into a universal rule.

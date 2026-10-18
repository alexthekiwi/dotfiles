# Review playbook

Use the baseline as a map, not a flat checklist. Spend depth where the app's harm model and evidence point.

## Intake and ownership

- Product purpose, current users, live status, target launch or growth event.
- Founder concerns, known issues, future phases and claims already made publicly.
- Repository, deployed version, hosting, database, authentication, storage, billing, AI, monitoring and app-store access.
- Legal entity, account ownership, MFA, recovery contacts, billing owner and offboarding.
- Review-only boundary, time box, deliverable, remediation exclusion and deadline.

## Repository and release baseline

- Pin the branch and commit reviewed; record dirty state without changing it.
- Read local instructions, architecture notes and manifests, while treating generated status claims as unverified.
- Locate environments, ignored files, tracked diagnostics, secret reports and generated provider state.
- Detect CI, tests, type checks, lint, build commands, migrations and release scripts.
- Build or bundle without deploying when safe. Separate app, server and Edge Function toolchains so one invalid configuration does not hide another.
- Run the native dependency audit and doctor command, then triage production reachability rather than repeating counts.

## Data and authorisation

- Inventory sensitive data and every processor it reaches.
- Trace authentication, account recovery, session persistence, sign-out and account switching.
- For each table or tenant boundary, check grants, RLS or equivalent row policy, object ownership, write checks and service-role use.
- Look for client-supplied owner or tenant identifiers, update-by-ID calls and privileged functions.
- Verify storage bucket privacy, path ownership, signed URL lifetime, size and MIME restrictions, deletion and orphan cleanup.
- Confirm baseline schema and policies are versioned and recoverable.

## Lifecycle and false success

- Notifications: scheduling horizon, caps, cancellation order, offline refresh, reboot, background limits, timezone, DST and public lock-screen content.
- Communications: distinguish opening a composer, provider acceptance, delivery and recipient success.
- Deletion: request, grace period, cancellation, execution, retries, storage cleanup, processors and proof of completion.
- Billing: user identity, purchase, restore, account switch, cancellation, grace period, refund, webhook duplication and expiration.
- History and counters: ensure inactivity, retries and concurrent devices do not omit or double-count events.
- Backup and recovery: confirm coverage, retention and a usable restore path rather than relying on a dashboard badge.

## Third parties and privacy

- Identify analytics, session replay, crash reporting, AI, email, SMS, billing and storage processors from code and live settings.
- Record PII defaults, masking, logs, network/body capture, region, retention, access and deletion.
- Check API secrets stay server-side and public/mobile keys have the intended scope.
- Add rate, payload, MIME, cost and concurrency controls to AI/upload and webhook paths.
- Compare the inventory with privacy policy, data-safety declarations, terms and consent flows.

## Risk-specific prompts

### Health or safety

- Can reminders or check-ins silently stop, appear successful or expose sensitive details?
- Does history omit inactivity and make adherence look better?
- Are medical or safety claims supported by actual delivery semantics?

### Marketplace or multi-tenant

- Can a user choose another tenant, owner, business, shift or document ID?
- Do storage and exports preserve the same tenant boundary as database rows?
- Are admin roles and internal ratings separated from ordinary accounts?

### Payments and subscriptions

- Is entitlement tied to the authenticated account throughout login, logout and restore?
- Are cancellation and expiration distinct?
- Can webhook replay, duplication, ordering or missing events create incorrect access or money state?

### AI and uploads

- Can a user bypass cost limits with concurrency or oversized payloads?
- What personal data appears in images, prompts and logs?
- Is retention or no-training language supported by current provider settings?

### Internal or business-critical tools

- Who can operate, recover and hand over the system?
- Can a failed sync or partial update be detected and replayed safely?
- Are backups and provider accounts controlled by the business rather than one device or person?

## Useful positive evidence

Record controls that materially reduce risk, such as server-side secrets, deny-by-default endpoints, private buckets, signed webhook verification, soft deletion, input limits, monitoring, force-update paths and a reproducible build. Positive evidence makes the final decision more credible; it is not filler.


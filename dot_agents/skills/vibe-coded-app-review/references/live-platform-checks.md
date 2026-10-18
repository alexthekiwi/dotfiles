# Live platform checks

Inspect live configuration read-only. Never expose secret values or individual user records in notes or reports.

## Supabase

### Database

- List every exposed schema and application table.
- Confirm RLS status per table.
- Capture each policy's operation, target roles, USING and WITH CHECK expression.
- Check grants for anon, authenticated and service_role. Policies and grants both matter.
- Inspect functions, triggers and security-definer functions, including search paths and caller-controlled identifiers.
- Compare the live schema with migrations and note any dashboard-only state.
- Dump the catalogue through the Management API `POST /v1/projects/{ref}/database/query` with `"read_only": true` (runs as `supabase_read_only_user`, refuses writes) instead of the SQL editor. Record the reviewer's actual org role: Read-only exists only on Team/Enterprise, and Developer can reveal the service_role and secret keys.
- For every view, check `information_schema.views.is_updatable` together with anon/authenticated INSERT/UPDATE/DELETE grants. A SECURITY DEFINER (non-`security_invoker`) view over one table owned by `postgres` is writable past RLS. Clients often call such views "read-only by design".
- Flag guard triggers that exempt `auth.uid() IS NULL` as "service role": an `anon` request also has no uid, so it passes them. The safe test is `current_user NOT IN ('authenticated','anon')`.
- Test an owner's "no real users" claim with aggregate-only queries, such as account counts by email domain and counts of filled sensitive columns. Never read individual rows.

### Minimum authorisation proof

For every personal or tenant table, prove:

- anonymous cannot select, insert, update or delete;
- user A can perform only intended operations on user A rows;
- user A cannot read or mutate user B rows;
- inserts and updates cannot assign user B or another tenant as owner;
- service-role access exists only in trusted server paths.

Use an existing non-production test environment when possible. Creating test users or data in production requires explicit approval and a cleanup plan.

A zero-row PostgREST write (nil-UUID filter) does not prove writability: RLS-filtered tables also return `200 []`. Projects may ignore `Prefer: tx=rollback`, so a probe matching a real row commits. Prove write paths from the catalogue (`has_table_privilege`, `pg_relation_is_updatable`) instead.

### Storage

- Bucket public/private flag, object size limit and allowed MIME types.
- SELECT, INSERT, UPDATE and DELETE policies on storage.objects.
- Folder or owner checks for every operation, including upsert and signed URL creation.
- Object cleanup when a row or account is deleted.

### Authentication

- Site URL and redirect allowlist. Wildcards on shared hosts such as `*.vercel.app` and `*.netlify.app` combined with email templates that build links from `{{ .RedirectTo }}`, or with magic links, give one-click token theft.
- Whether admin access requires AAL2 at the data layer (policies and definer functions), not only in the UI, and whether admins have actually enrolled a factor.
- Enabled providers, anonymous sign-in, email confirmation and secure password change.
- Password strength, leaked-password detection, MFA options and session controls.
- Rate limits, CAPTCHA or bot protection where signup or recovery abuse matters.
- SMTP ownership, sender identity and delivery monitoring.

### Edge Functions

- Deployed functions, version/time, JWT verification and repository parity.
- Secret names and ownership without opening values.
- Authentication, payload limits, rate limits, CORS, timeout, retry and logging.
- Service-role use scoped to a validated user or trusted event identity.

### Backups and access

- Plan, scheduled backup retention, PITR availability and restore procedure.
- Organisation owners, developer access, least privilege, MFA visibility and recovery path.
- Security Advisor results and unresolved warnings.

## Other managed platforms

Apply the same proof structure:

- authentication and roles;
- data and object boundaries;
- public exposure and network entry points;
- secrets and privileged execution;
- logs, monitoring and alerts;
- backup and restore;
- owners, billing, MFA and recovery;
- reproducible configuration in source control.

Label dashboard state with the inspection date. A live UI can drift immediately after review.

Check hosting and billing state before planning runtime work. On Vercel, the team's `softBlock` and `billing.status` and an unauthenticated `curl` showing `x-vercel-error: DEPLOYMENT_DISABLED` reveal an unpaid-invoice block that silently stops the site, crons and any database job that calls the app. If the database is billed through a marketplace (`billing_partner`), the same account controls it. To see where a `pg_net` job posts without reading its vault URL, read the `server` and `x-matched-path` headers in `net._http_response` (kept about six hours).

When driving the owner's signed-in browser, open a new tab (for example `browser.newPage()` from an adopted tab) and navigate there. Navigating the owner's adopted dashboard tab directly can close it.

## App-level gates and browser walks

- Probe every host or path gate with the variants a string match misses: upper-case host, trailing-dot host, and an encoded path suffix (`/login%2F`). Browsers normalise the host but keep the encoded path, and Next.js still serves the page for it.
- For client-side third-party checks (breach lookup, CAPTCHA), confirm the enforced CSP `connect-src` allows the host. A fail-open check behind a CSP block passes everything.
- During each portal walk, read the network payload as well as the screen. Data the UI hides ("shared once approved") may already be downloaded.
- Page loads can fire housekeeping RPCs that write. List the RPCs from the request log and disclose any state change in the report's scope.

## Cloudflare Workers (when the app runs on Workers)

- Static assets are served before the Worker unless `assets.run_worker_first` is set. Probe `/_next/static/*`, `/_next/image` and `public/` files unauthenticated before trusting a middleware password gate.
- Preview URLs (`<version>-<worker>.<subdomain>.workers.dev`) keep every stored version reachable against the live bindings. Probe each listed version.
- Scoped read roles (for example "Workers Content Read") hide other Workers and return 403 for D1, R2, log queries, Access policies and members. Probe Worker names found in the repo directly, and list the hidden areas as unverified.
- Compare the plan (Workers plans page) with the CPU-limit errors by time window before attributing error 1102 to code.
- Inspect the dashboard in a dedicated browser window. Never drive a window the owner is using.


---
name: ux-wireframe
description: Clickable lo-fi website wireframe for client sign-off on site map, navigation, home-page modules, key page layouts and journeys, built from wiki notes, meetings or briefs through a guided questionnaire. Use when asked for a wireframe, site map, clickable prototype or page-structure review.
---

# UX wireframe

Produce an unbranded, clickable HTML wireframe a client can open in a browser and approve. It decides the site map, navigation, the modules each page needs, and the main journeys. Visual design comes after it. Alex, Keir or a non-developer can run this: they answer questions, and you do all the building.

## Fixed defaults

These are settled. Apply them without asking:

- **Output:** static HTML, CSS and JavaScript with no build step and no dependencies. One flat file per page, written to `prototype/` in the current project (or the folder the user names; outside a repo, `~/Code/<client>-wireframe/`).
- **Fidelity:** lo-fi greyscale, unbranded, responsive for desktop and a 375px phone.
- **Interactivity:** real links between pages. Drawers, modals, tabs and forms work and advance to their confirmation states. Demo data persists in `localStorage`. There is no backend.
- **Review layer:** a bottom bar with a review-state toggle (for example guest or signed in), a notes toggle, a pop-up toggle when the site has one, a site map link and a demo reset. Yellow notes explain decisions; outlined notes ask open questions.
- **Viewing:** serve with `python3 -m http.server` and open it in the user's browser as soon as the first page exists, so they watch progress.
- **Hosting:** prepare a Cloudflare Pages deploy behind Cloudflare Access. Run it only when the user approves the target and project name.

## Steps

### 1. Gather the sources

Use every source the user points at. If they point at none, ask one question: where do the notes live (wiki domain, meeting, briefs folder, current site URL, design references)?

- **Caretakers clients:** read the vault's `AGENTS.md`, then `wiki/hot.md`, `wiki/index.md`, `wiki/domains/<slug>/_index.md`, then the newest relevant `sources/`, `concepts/` and `decisions/` pages. Meeting transcripts are usually already ingested there.
- **Project repo:** read the plan, design brief and ADRs it names.
- **Current site:** fetch the live navigation and menu labels; they show what the client's customers already know.
- **Images the user pastes** (mock-ups, reference sites) are requirements. Match their structure.

**Done when** you can state, each with its source, the goal, the audiences in priority order, the settled decisions, the conflicts between sources and the gaps.

### 2. Brief back

Send a short summary: what is settled, what conflicts, what the wireframe must cover, and the questions coming. Keep it to one screen.

**Done when** the user has the summary and can correct it before the questions start.

### 3. Run the questionnaire

Read [`references/questionnaire.md`](references/questionnaire.md) and run its rounds with the ask tool.

**Done when** every question in the bank is answered by the user, settled by a source you can name, or (after the user says to make assumptions) defaulted and logged as an assumption. Fold any interjections in as they arrive; the latest instruction wins.

### 4. Build

Read [`references/build.md`](references/build.md) for the kit, page conventions, build order and delegation. Read [`references/style.md`](references/style.md) before writing any page, and apply it to every page and worker brief.

**Done when** every page in the agreed site map exists, every agreed journey can be clicked from start to its confirmation state, and `sitemap.html` lists the pages, journeys, decisions, open questions and assumptions.

### 5. Verify

1. Run `python3 <skill-dir>/scripts/check.py <prototype-dir>`.
2. In a browser, load every page in every review state and collect console errors.
3. Click through each journey on the site map.
4. Screenshot the home page, the main detail page and the open mobile menu at 375px.

**Done when** there are zero broken links and zero script errors, every journey reaches its end page, mobile layouts hold, and the only style findings left are product codes or real product colours.

### 6. Hand over

Report:
- the local URL and the starting page (`sitemap.html`);
- what was built, page family by page family;
- the assumptions you made and the open questions for the client;
- what you verified;
- the deploy command, offered but not run.

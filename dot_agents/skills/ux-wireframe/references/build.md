# Build

## Kit

Copy `<skill-dir>/assets/kit/` into the output folder. It contains:

| File | Role |
|---|---|
| `assets/wf.css` | All styles. Read it for the class vocabulary: layout (`wrap`, `section`, `grid g2–g6`, `row`, `spread`, `two-col`, `checkout-layout`, `catlayout`), boxes (`box`, `band`, `msg`), `img` placeholders, buttons, forms (`field`, `choice`, `seg`, `upload`), `badge`, `chip`, `steps`, `numbered`, tabs, accordions, `card`, `tile`, `hero-full`, footer, drawer and modal, plus the order-grid, finder and filter components. |
| `assets/wf.js` | Header, mega menus, footer, review bar, review states, overlays, tabs and toast, all driven by `site.js`. |
| `assets/site.js` | `window.SITE` config: name, review states, utility bar, signed-in strip, navigation and mega menus, search, header icons, footer columns, pop-up. This is the template to fill from the questionnaire. |
| `page.html` | Page skeleton. |
| `sitemap.html` | The review guide: site map tree, journeys, decisions, open questions, assumptions and what's left out. |

Script order on every page: `site.js`, then `data.js` (if any), then `wf.js`, then the page script.

## Conventions

- **Pages:** one flat file per page. Variants use query strings (`category.html?c=hoodies`, `product.html?s=CODE`), so links stay simple and one template serves many pages.
- **`<body data-page="key">`** marks the current nav item (through `page` in `site.js`) and lets the pop-up skip pages via `popup.skipPages`.
- **Review states:** mark markup with `data-only="state"` (space-separate several states). For script-rendered differences, read `WF.state()` and re-render on the `wf:state` event.
- **Notes:** `<div class="note">` records a decision and its source; `<div class="note q">` asks an open question and names who decides. Put two to five on each page, next to the thing they describe.
- **Data:** put illustrative records in `assets/data.js` as `window.WFDATA` (styles or products, categories, people, locations, the demo account). Generate prices and stock deterministically, so every reload shows the same numbers.
- **Overlays:** `WF.overlay({ id, kind: 'drawer' | 'modal' | 'modal narrow', title })` returns `{ el, body, foot }`. Fill it, then call `WF.openOverlay(el)`. Register an opener with `WF.register('quote', (data) => …)`, and any `data-open="quote"` element triggers it with its `data-*` values.
- **Header counts:** set `WF.counts.cart = () => n` and call `WF.refreshCounts()` after changes.
- **Storage:** use `WF.store.get(key, fallback)` and `WF.store.set(key, value)`. Reset demo clears it.
- **Multi-step forms** (enquiry, quote, booking): keep one state object, re-render the current step, and end on a confirmation that says who receives it, what happens next and a reference number.

The Cloke wireframe (`~/Code/cloke/prototype/`, when present) is a full worked example. It has a three-step quote drawer, a finder that works as both a page and a modal, a colour-by-size trade grid, a cart with role-aware lines, a one-page checkout, five order-status states and an account area.

## Build order

1. Fill `site.js` with the agreed nav, states, footer and pop-up. Write `data.js` if the site has a catalogue.
2. Build the home page and the main detail page. Start the server (`python3 -m http.server <port>` in the output folder) and open it in the user's browser.
3. Smoke-test those two pages before going wide. Shared bugs found now are fixed once, not in every page.
4. Build the remaining page families. With subagents available, give one worker per family, in parallel.
5. Write `sitemap.html` and a short `README.md` covering how to run the wireframe locally and how to deploy it.

## Delegating page families

Give each worker:
- the goal and the agreed decisions;
- the kit file list, the page skeleton and these conventions;
- the style rules in `style.md`;
- the exact files it owns, with an instruction to leave `assets/*` alone and report any gaps in the kit instead;
- an instruction not to run browsers or tests (you verify the integrated result).

Typical families are: catalogue (listing, landing, search); transactions (cart, checkout, status, repeat-use tools); account (sign-in, account pages, partner landing); content (how it works, finder, about, guides, journal, generic content page, 404).

## Deploy

```bash
npx wrangler pages deploy <prototype-dir> --project-name <client>-wireframe
```

Put Cloudflare Access (an email one-time PIN) in front so only the client's reviewers can open it. Deploy only after the user confirms the project name and the reviewer list.

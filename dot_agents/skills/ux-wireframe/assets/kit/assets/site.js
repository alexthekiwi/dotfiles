/* Site configuration for the wireframe kit. Replace every value with the agreed structure from the questionnaire.
   Load order on every page: site.js, then data.js (optional), then wf.js, then the page script. */
window.SITE = {
  name: 'Client',                       // Wordmark text in header and footer. Sentence case, no box.
  storageKey: 'wf-client',              // localStorage prefix; unique per project so demos don't collide.
  currency: '$',
  locale: 'en-NZ',

  // Review states shown in the bottom bar. Mark content with data-only="signed-in" (space-separate several).
  states: [
    { key: 'guest', label: 'Guest' },
    { key: 'signed-in', label: 'Signed in' },
  ],

  utility: {
    left: [{ html: '<span class="muted hide-sm">One-line proposition for the utility bar</span>' }],
    right: [
      { label: 'For partners', href: 'partners.html', only: 'guest' },
      { label: 'Sign in', href: 'sign-in.html', only: 'guest', strong: true },
      { html: 'Signed in as Sam · <a href="#" data-set-state="guest">Sign out</a>', only: 'signed-in' },
      { label: 'Help', href: 'contact.html' },
    ],
  },

  // Optional slim bar for a signed-in state (shortcuts for repeat users).
  strip: { only: 'signed-in', title: 'Account name', links: [{ label: 'Quick action', href: 'account.html' }, { label: 'My account', href: 'account.html' }] },

  // Main navigation. An item with `mega` opens a mega menu; `page` matches <body data-page> for the current marker.
  nav: [
    {
      label: 'Products',
      mega: [
        { heading: 'Browse', links: [{ label: 'Category one', href: 'category.html?c=one' }, { label: 'Category two', href: 'category.html?c=two' }] },
        { heading: 'Collections', links: [{ label: 'New', href: 'category.html?c=new' }, { label: 'All', href: 'category.html?c=all' }] },
      ],
      promo: { label: 'Promo tile', href: 'category.html?c=new', note: 'CMS-managed slot' },
      note: 'Why the menu is organised this way, in one or two sentences.',
    },
    { label: 'How it works', href: 'how-it-works.html', page: 'how' },
    { label: 'About', href: 'about.html', page: 'about' },
  ],

  search: { action: 'search.html', placeholder: 'Search' },   // set to null for no search

  icons: [
    { label: 'Saved', href: 'saved.html', ico: '♡' },
    { label: 'Sign in', href: 'sign-in.html', ico: '○', only: 'guest' },
    { label: 'Account', href: 'account.html', ico: '◉', only: 'signed-in' },
    { label: 'Cart', href: 'cart.html', ico: '▢', count: 'cart' },        // count reads WF.counts.cart()
  ],

  // Footer: full width, columns split by borders, an optional bottom line per column.
  footer: {
    blurb: 'One sentence about the organisation.',
    brandFoot: '© Client 2026',
    columns: [
      { heading: 'Shop', links: [{ label: 'All products', href: 'category.html?c=all' }] },
      { heading: 'Help', links: [{ label: 'How it works', href: 'how-it-works.html' }, { label: 'Contact', href: 'contact.html' }], foot: '<a href="content.html?t=privacy">Privacy</a> · <a href="content.html?t=terms">Terms</a>' },
      { heading: 'About', links: [{ label: 'Our story', href: 'about.html' }], foot: 'Instagram · LinkedIn' },
    ],
  },

  // Optional delayed pop-up (newsletter or promo). Remove the key to disable.
  popup: {
    delay: 8000,
    skipPages: ['cart', 'checkout', 'account', 'sign-in'],
    title: 'Hear about new things first',
    html: `<form onsubmit="event.preventDefault();WF.closeOverlays();WF.toast('Thanks. You\\'re on the list.')">
      <div class="field"><label for="pp-e">Email</label><input id="pp-e" type="email"></div>
      <button class="btn block">Sign up</button></form>
      <div class="note">When it fires, where it never fires, and which tool receives the address.</div>`,
  },
};

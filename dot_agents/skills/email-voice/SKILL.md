---
name: email-voice
description: >-
  Use whenever drafting, writing, replying to, or rewriting an email or message
  as Alex Clark (Caretakers alex@caretakers.io or his studio
  hello@alexclark.co.nz), including reviewing a draft to sound more like him.
  Has his voice rules, real samples, and how he shifts for specific people.
---
# Alex's Email Voice

Every draft must sound like Alex Clark. Read `references/voice-guide.md` (beside this file) before drafting: it has the full style breakdown and 17 real sample emails.

This is the canonical copy. It is managed with chezmoi: edit `~/.local/share/chezmoi/dot_agents/skills/email-voice/`, run `chezmoi apply`, and commit. Other machines' copies (such as the Grok Bot box) are re-synced from here.

## Quick Reference

**Always:**
- Open with "Hey [Name]," ("Hey all," / "Hey both," for groups, "Hey mate," for people he knows well). Quick mid-thread replies can skip the greeting.
- End every connector draft with the real signature for that mailbox (see Signatures below). Gmail does **not** add his signature to drafts made through the connector or a draft card, so leave it off and the sent email goes out bare. Put a blank line after the body, then the signature block exactly as written.
- Use NZ English spelling (organise, recognise, colour, behaviour).
- Warm, conversational but professional. Direct and clear. Lead with the point.
- End the body on something specific to this email: a real next step, a question, or an invitation ("Have a read and let me know what you think.", "How are you placed early next week?"). If the email already ends on a question or a clear ask, stop there, then add the signature.
- Keep quick replies genuinely short.
- Plain-text headings rather than bold; "Done:" / "Not done:" lists for work summaries.

**Never:**
- **Em dashes or en dashes, anywhere, including number ranges.** They are the biggest AI tell. Use commas, full stops, colons, or parentheses, or restructure. Ranges use a hyphen or words ("2pm to 4pm", "9-11"). A plain spaced hyphen (" - ") is allowed at most once per email, only as a short casual lead-in like "Sure thing - attached."
- "Just sing out" or "sing out". Retired.
- "Any q's, just let me know" or any other stock catch-all closer. Alex finds it repetitive. Use it rarely at most, never by default, and never when the email already ends on a question.
- "Dear", "Hello", "Hi there", or overly formal openings.
- Corporate buzzwords (synergy, leverage, circle back, align, loop in).
- Filler ("I just wanted to reach out", "I hope this email finds you well").
- Other AI tells: tidy five-paragraph essays, "It's not just X, it's Y", reflexive rule-of-three lists, opening with "I'd be happy to...", a generic "Let me know if you need anything else!" closer.
- Over-hedging.
- "Please don't hesitate to" / "don't hesitate to reach out".
- American spelling.
- Inventing or shortening a signature. Use the exact block for that mailbox.

## Which mailbox

- Caretakers / agency clients: `alex@caretakers.io` (work Gmail).
- Personal studio, side clients, family, house stuff: `hello@alexclark.co.nz` (personal Gmail).
- Pick the mailbox from who it is, not from habit. Always append that mailbox's signature.

## Signatures

Copied from emails Alex actually sent. Use these verbatim after the body.

### Work (`alex@caretakers.io`)

```
Kind Regards,

Alex Clark
Technical Director

/ 141 Picton St / Howick 2014
/ Auckland / New Zealand
/ 022 020 8262

/ caretakers.io
```

(Link `caretakers.io` to https://caretakers.io/ when the draft is HTML-capable. Bold his name if the channel supports it. Do not invent extra lines.)

### Personal studio (`hello@alexclark.co.nz`)

```
Kind regards,
Alex Clark

+64 22 020 8262
alexclark.co.nz
```

(Bold his name if the channel supports it. Do not invent extra lines.)

## How he shifts for specific people

Default for an unknown person: "Hey [First]," then two to five sentences, answer first, then the next step. Small habits that fit most people: "arvo", "heaps", "Sweet!", "cheers", "yep", "$200 + GST", and at most one emoji in a short friendly reply.

### Caretakers people

- **Sarah Cason** (Sarah.Cason@sportintegrity.nz). Warm government client, friendly and slightly personal. Short on tickets, longer on quotes. "Hey Sarah," / "Hope you're well!" / "Cheers for your time yesterday!" Tickets: found it, fixed it, one-line cause ("Not a problem at all - done."). Goodwill said plainly: "No time tracked on this."
- **Maxim Kalabukhov** (maxim.kalabukhov@starinsure.co.nz). Technical peer, nerd to nerd; jokes and personal warmth are fine. "Hey Maxim," or "Hey team,". PR links, staging, merge talk ("Sweet! All done and on staging."). Don't use this register on Sarah or the Noonans.
- **Aaron Mortimer** (aaron@mariner.co.nz). Long-run commercial partner. Casual, direct, a bit sales-adjacent, can be longer. Explicit asks, one dry joke is fine, close with a phone offer or next step.
- **The Noonans** (matt@ / michelle@ / bryan@nautical.co.nz). Warm sales and proposal register, don't rush. Bryan, not Brian. "Hey Matt," / "Hey Nautical team," / "Hey Bryan and Michelle,". Proposals: cheers for the meeting, what's attached, one-line positioning, what you need, offer a call. Follow-ups stay light.

### Personal studio people (hello@alexclark.co.nz)

- **Murray Clark** (murray@glassprojects.co.nz, Glass Projects). Family and a client. Very casual, swearing is fine, can be frank in a way he'd never be with a Caretakers client. "Morning," / "Hey guys," / "Hey,". Short: "No problem, as attached." / "Oh sweet! Sorry about that." John Aranui (John@glassprojects.co.nz) is in the same circle: "Hey John," / "Hey mate,".
  > Hey guys,
  >
  > Saw a new Google review pop up this arvo.
  >
  > Do you want to draft a reply to this ass? I can post it for you.
- **Amy Elliott** (amy@askbellwether.com, Bellwether / Be Brilly). Warm and organised. Status emails stay short; brand and design emails can run longer and explain the thinking. "Hey Amy," / "Hey all," with the team. "Stoked to hear that you're pleased with the work!" Numbered replies to change lists ("Sure thing, confirming this is fixed."). Catch-ups are often evenings.
- **Mark Sandford** (mark@sandforddesign.co.nz, Sandford Design). Howick neighbour who designed the house reno (27a Sale Street, with Jiwon), also a website client. Warm, helpful, slightly over-delivers. "Great to catch up with you guys!" / "Absolute legend" is fine here. Protective on IT and hosting: explain plainly, offer to email their IT for them.

## Process

1. Read `references/voice-guide.md`.
2. Work out the mailbox, the person, and the email type (update, proposal, follow-up, quick reply, technical explanation, etc.).
3. Draft it in his voice, then append that mailbox's signature.
4. Self-check before presenting:
   - Zero em dashes and zero en dashes? If any, rewrite those sentences.
   - At most one spaced hyphen, only as a short lead-in?
   - No "sing out"?
   - Signature present and matching the mailbox?
   - Reads like the samples, not like AI? Warm without filler?
   - Body ends with a clear next step, question, or invitation specific to this email, not a stock "Any q's" line?
5. Present it as a draft for Alex to review. Never send until he says to. If the email creates a next action, ask before adding a Shed todo.

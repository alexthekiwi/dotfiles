# Client report format

Write for a non-technical owner who needs a decision and a practical next step. Keep the reusable internal checklist out of the client deliverable.

## Required order

1. **Specific title and status**
   - Application name, review purpose, date and whether any live evidence is still pending.
2. **Executive summary**
   - Launch or growth decision first.
   - Two short paragraphs on the strongest controls and the material gaps.
3. **Before launch or growth**
   - Ordered actions that change the decision.
4. **Scope and evidence**
   - What was reviewed, excluded and still unverified.
5. **Detailed findings**
   - Plain client explanation followed by a compact technical handoff.
6. **Controls already sound**
   - Only material positives.
7. **Verification or release sequence**
   - The order that protects users and avoids rework.
8. **References and limitations**

## Writing rules

- Lead with the decision, not the tooling used.
- Write for two readers in sequence: the non-technical owner first, then the AI agent or developer who will carry out the work.
- Use a plain-English finding title. Put exact identifiers, files and configuration in the technical handoff rather than the title.
- Keep facts, client statements, inference and recommendations distinguishable.
- Use exact file or configuration references where they help a future developer act.
- Never include credentials, user records, raw security payloads or personal data.
- Avoid declaring a system secure. State what was and was not verified.
- Do not label dependency-audit counts as exploit counts.
- Keep remediation separate from the review; offer estimates only when requested.
- Remove repetition before reducing font size. A summary table is optional and should be omitted when it merely repeats compact detailed findings.
- Prefer roughly 80 to 140 words per finding across all layers. Use more only when the extra context changes the decision or prevents an unsafe fix.

## Finding shape

```markdown
## A subscription can be linked to the wrong account or switched off too early

High priority

If the app starts signed out and the person logs in later, the subscription service can stay linked to a temporary account. A purchase may reach the wrong person, and cancelling renewal can remove paid access before the paid period ends.

**Action:** Link the subscription service to the signed-in account throughout login and logout, and remove access only when the subscription expires.

**Technical handoff:** Name the exact files and configuration. State the incorrect event or state transition and the acceptance tests needed for purchase, restore, account switching, cancellation, refunds and expiry.
```

The client paragraph explains the real-world failure without assuming technical knowledge. The technical handoff is concise but sufficiently exact for an AI agent to inspect and implement safely. Do not hide uncertainty: label code-observed, live-verified and unverified evidence when that distinction affects the action.

## Decision language

Use one of these as a starting point, then tailor it:

- **Ready for controlled release:** no open high-priority gate in the reviewed scope; named residual risks remain.
- **Controlled beta only:** existing testers can continue with stated limits; wider growth should wait for listed gates.
- **Release stop:** current evidence shows an active critical risk that needs containment before further use.
- **Decision deferred:** a named live configuration or runtime check is essential and was not available.

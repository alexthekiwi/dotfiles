# Severity and evidence

Classify the consequence and likelihood supported by current evidence. Severity is not a measure of how untidy the code looks.

## Evidence labels

- **Runtime verified:** observed through a safe build, test, device flow or request.
- **Live verified:** read directly from the relevant production or managed-service configuration.
- **Code observed:** follows from the reviewed source, but the deployed version or live setting may differ.
- **Client reported:** supplied by the owner or meeting evidence and not independently reproduced.
- **Unverified:** material to the decision but inaccessible or outside the time box.

A finding can combine labels. State the boundary, for example: “Code observed; current production policy not yet verified.”

## Severity

### Critical

Use when current evidence shows an active, readily exploitable path to broad sensitive-data access, account takeover, destructive loss, fraudulent money movement or severe user-safety harm. Critical means immediate containment or a release stop, not merely “important”.

### High

Use for a likely core-function failure, material privacy or authorisation weakness, exposed credential, misleading safety state, unfulfilled deletion promise, subscription or payment error, or operational gap that should block wider launch or growth.

### Medium

Use for a meaningful resilience, maintainability, least-privilege, dependency, observability or process weakness that increases incident likelihood or makes recovery harder but is not presently shown to create immediate severe harm.

### Low

Use sparingly for bounded hygiene or polish that has a credible effect. Omit generic best-practice commentary that does not change the owner's decision.

## Confidence

Use confidence only when it helps prioritisation:

- **High confidence:** direct live or runtime evidence, or an unavoidable code path.
- **Moderate confidence:** strong code evidence with one live assumption outstanding.
- **Low confidence:** plausible concern that needs a specific verification step.

Do not upgrade severity to compensate for low confidence. Keep the severity tied to consequence and likelihood, then state the missing evidence.

## Finding test

A reportable finding answers all five:

1. What was observed?
2. Where is the evidence?
3. What credible failure follows?
4. Why does that matter to this app and owner?
5. What is the next decision or action?

If one is missing, investigate further, downgrade it to an open verification item, or leave it out.


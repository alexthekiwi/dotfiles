---
name: sol-advisor
description: Architect-led delegated implementation using a model-pinned Terra worker, parent verification, and a fresh read-only Sol review. Use when Alex says "Sol Advisor", invokes $sol-advisor, or requests architect-led implementation with mandatory independent review.
---

# Sol Advisor

Act as the primary architect. Own requirements, architecture, decomposition,
verification, correction decisions, and final acceptance. Delegate implementation to
the configured Terra worker and require a fresh Sol verdict before reporting a code
change complete.

## Preflight

Before implementation, confirm that the native spawn surface exposes both exact custom
agent names:

- `sol_advisor_terra_implementer`
- `sol_advisor_sol_reviewer`

If either is absent, stop and tell the user to start a fresh Codex task. Do not use a
built-in agent, another model, or another effort as a fallback. The custom-agent TOMLs
pin model and reasoning, so never add per-spawn model or reasoning overrides.

## Parent responsibilities

Keep these responsibilities in the primary session:

- Resolve material ambiguity and choose the architecture.
- Define interfaces, ownership boundaries, constraints, and acceptance criteria.
- Inspect the actual working tree and complete diff.
- Rerun verification independently.
- Evaluate reviewer findings and accept or reject the result.

Do not write implementation code, tests, boilerplate, or mechanical configuration in
the primary session while the Terra lane is available. If implementation is wrong,
correct the specification and send the correction to the same worker when practical.

## Implementation lane

Spawn `sol_advisor_terra_implementer` with fresh context (`fork_turns: none`). Use one
worker by default. Run multiple Terra workers concurrently only for genuinely
independent, non-overlapping file sets; keep shared files and dependency chains serial.

Give every worker this complete contract:

~~~text
ROLE
Act as Sol Advisor's implementation worker. Do not delegate or spawn subagents.

OBJECTIVE
<Observable outcome, why it matters, and acceptance condition.>

FILES AND OWNERSHIP
You own only:
- <Exact file or module paths.>

You are not alone in the codebase. Preserve concurrent edits, do not revert unrelated
work, and do not modify files outside your ownership. Return a blocker if ownership
must expand.

INTERFACES
- <Signatures, schemas, commands, routes, APIs, or behavior to preserve.>

CONSTRAINTS
- <Repository rules, safety boundaries, settled decisions, and excluded scope.>

VERIFICATION
- Run: <Exact focused command.>
  Success: <Concrete expected output or exit status.>
- Inspect: <Exact diff, file, or generated artifact.>
  Success: <Concrete evidence required.>

RETURN
IMPLEMENTATION REPORT
STATUS: complete | partial | blocked
OBJECTIVE: <One-line restatement.>
CHANGES: <File-by-file summary from the actual diff.>
VERIFIED: <Exact commands and concrete output evidence.>
JUDGMENT CALLS: <Decisions the specification left open, or none.>
GAPS: <Unfinished work, ambiguity, or none.>
~~~

Treat the worker report as a claim. Before review:

1. Inspect `git status`, the complete diff, and changed-file scope.
2. Confirm interfaces and constraints remain intact.
3. Rerun the specified verification in the primary session.
4. Send precise corrections to the worker and repeat verification when needed.

## Fresh Sol review

After implementation and parent verification, record the repository state, then spawn
a new `sol_advisor_sol_reviewer` with fresh context (`fork_turns: none`). Never reuse an
implementation thread for review.

Give the reviewer this complete packet:

~~~text
ROLE
Act as Sol Advisor's fresh final reviewer. Remain strictly read-only. Do not edit files,
implement fixes, or spawn subagents.

STATED GOAL
<The user's requested outcome.>

ACCUMULATED CHANGE SET
<Exact allowed files and complete working-tree diff, or explicit base/head revisions.>

INTERFACES AND CONSTRAINTS
- <Compatibility requirements, repository rules, safety boundaries, excluded scope.>

VERIFICATION EVIDENCE
- <Command> -> <Actual primary-session output.>
- <Artifact or diff inspection> -> <Actual evidence.>

REVIEW
Inspect the actual files and accumulated change set. Judge correctness, completeness,
regressions, scope discipline, interface preservation, test adequacy, and material
risk. Return exactly one allowed verdict.

SOL REVIEW
VERDICT: ship | fix-first | rethink
REASON: <Decisive evidence-based reason.>
FINDINGS: <Precise file references and required fixes, or none.>
RESIDUAL RISK: <Most important remaining risk, or none.>
~~~

The reviewer TOML requests `sandbox_mode = "read-only"`, but live parent permission
overrides may broaden a child. Report only observed isolation. Compare repository state
before and after review; any mutation invalidates the verdict.

Handle the verdict as follows:

- `ship`: report completion with parent verification evidence.
- `fix-first`: send the required fixes to Terra, verify again, then spawn a new reviewer.
- `rethink`: revise the architecture or scope and do not report completion.

Any post-review code change invalidates the verdict. Never let the reviewer implement
its own fixes. Sol reviewing Sol is context-clean, not model-family independent.

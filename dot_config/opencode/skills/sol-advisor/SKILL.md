---
name: sol-advisor
description: Orchestrates delegated implementation with Sol/High architecture, Terra/High implementation, verification, and mandatory fresh Sol review. Use when the user says Sol Advisor, asks to use the sol-advisor skill, or requests architect-led delegated implementation.
---

# Sol Advisor

Act as the architect. Own the user's intent, architecture, decomposition, routing,
verification, and final acceptance. Delegate implementation to Terra, then obtain a
fresh Sol verdict before reporting a deliverable complete.

This workflow uses OpenCode child sessions. Every Task invocation without a `task_id`
starts with fresh context. Never resume an implementation child for final review.

## Required Agents

Use only these configured agents:

- `sol-advisor-terra`: GPT-5.6 Terra, `high`, for all implementation.
- `sol-advisor-reviewer`: GPT-5.6 Sol, `high`, with only read, glob, grep, and list tools.

Do not silently substitute another agent, model, or variant. If a required agent is
unavailable, stop and tell the user to restart OpenCode so global agent config is
reloaded.

## Architect Responsibilities

Keep these in the primary session:

- Resolve requirements and material ambiguity.
- Choose architecture, interfaces, and decomposition.
- Write the complete five-part implementation specification.
- Inspect the actual working tree and diff.
- Rerun verification independently.
- Judge reviewer feedback and accept the deliverable.

Do not write implementation code in the primary session. If a worker result is wrong,
correct the specification and delegate the fix.

## Route Implementation

Use `sol-advisor-terra` for routine features, mechanical edits, tests, bounded bug
fixes, difficult debugging, security-sensitive work, non-trivial algorithms, and
broad refactors. There is no second implementation or fallback lane.

Give each worker a non-overlapping file set or bounded responsibility. Run independent
work concurrently when useful; keep shared files and dependency chains serial.

## Implementation Contract

Every implementation prompt must contain all five sections and the return contract:

```text
OBJECTIVE
<Observable outcome and why it matters.>

FILES AND OWNERSHIP
You own only:
- <exact file or module>

You are not alone in the codebase. Preserve concurrent edits, do not revert unrelated
work, and adapt to changes already present. Do not modify files outside your ownership.

INTERFACES
- <Signatures, types, schemas, commands, or behavior that must remain compatible.>

CONSTRAINTS
- <Repository conventions, safety boundaries, excluded scope, and settled decisions.>

VERIFICATION
- Run: <exact command>
  Success: <concrete expected result>
- Inspect: <exact file, diff, or generated artifact>
  Success: <concrete expected evidence>

RETURN
IMPLEMENTATION REPORT
STATUS: complete | partial | blocked
OBJECTIVE: <one-line restatement>
CHANGES: <file-by-file summary from the actual diff>
VERIFIED: <exact commands plus concrete output evidence>
JUDGMENT CALLS: <decisions the spec left open, or none>
GAPS: <unfinished work, ambiguity, or none>
```

Treat worker reports as claims. Before acceptance:

1. Inspect the working tree and actual diff.
2. Confirm only in-scope files changed.
3. Rerun the specification's verification commands in the primary session.
4. Compare evidence with the objective, interfaces, and constraints.
5. Delegate corrections when evidence fails or the diff is wrong.

## Final Review

After implementation and primary verification, start a new Task with
`subagent_type: sol-advisor-reviewer` and no `task_id`. Include the complete review
packet below. Because the reviewer cannot run shell commands or edit files, include
the complete accumulated diff and actual primary-session verification output.

```text
ROLE
Act as the fresh final reviewer. Remain strictly read-only. Do not edit files,
implement fixes, or broaden scope.

STATED GOAL
<The user's requested outcome.>

ACCUMULATED CHANGE SET
<Exact allowed files and complete working-tree diff, or explicit base/head revisions.>

INTERFACES AND CONSTRAINTS
- <Compatibility requirements, repository rules, safety boundaries, excluded scope.>

VERIFICATION EVIDENCE
- <command> -> <actual primary-session output evidence>
- <artifact or diff inspection> -> <actual evidence>

REVIEW
Inspect the actual files and supplied change set. Judge correctness, completeness,
regressions, scope discipline, interface preservation, test adequacy, and material
risk. Return exactly one allowed verdict.

SOL REVIEW
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-based reason>
FINDINGS: <precise file references and required fixes, or none>
RESIDUAL RISK: <most important remaining risk, or none>
```

Handle the verdict as follows:

- `ship`: report completion with primary verification evidence.
- `fix-first`: delegate the named fixes, verify them, then start another fresh review.
- `rethink`: revise the architecture or scope and do not report completion.

Never waive final review because a change is small. Any post-review code change
invalidates the verdict. Sol reviewing Sol is context-clean, not model-family
independent.

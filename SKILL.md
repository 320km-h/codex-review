---
name: codex-review
description: Send a spec, plan, or code target to the local Codex CLI for an external, second-opinion review. Use when the user invokes /codex-review, or asks to "let codex review" / "get codex's perspective on" a file, directory, spec, or plan. Manual, user-triggered — not every task needs it.
---

# Codex Review

Get an outside, skeptical review from the **Codex CLI** on a target the user points at — a spec, an implementation plan, or code. The user triggers this deliberately. Simple tasks skip it; complex ones get the second opinion.

This skill does NOT auto-detect a target, and it does NOT use a fixed prompt. **YOU compose the review prompt from the current context** — you usually already know what this work is, what matters most, and where the risk is. `scripts/review.sh` is just transport: it runs codex read-only over the project and returns the result.

## Steps

You MUST create a TodoWrite item per step and do them in order.

1. **Determine the target.** Read it from the invocation argument — a file or directory path.
   - If NO target was given, **ASK the user what to review** (a path). Do NOT default to any file, do NOT guess. Wait for their answer.

2. **Get enough context to write a good prompt.**
   - If this conversation already built/discussed the target, use that context directly.
   - If context is thin (e.g. cold start, just a path), **read the target first** and skim the surrounding project so your prompt is specific, not generic.

3. **Compose the review prompt.** Write specific "what to scrutinize" instructions for codex, tailored to THIS target: what it is, its purpose, the tech stack / project conventions, what changed, known risk areas, and the decisions you most want a second opinion on. Tell codex to give a prioritized, terse list of concrete findings citing file/section (and line for code), most important first, skipping nitpicks.
   - Use the coverage checklist below as a reminder so you don't miss a dimension — but **tailor** it, don't paste it verbatim.

4. **Run the wrapper**, piping your composed prompt on stdin:
   ```
   printf '%s' "$PROMPT" | bash scripts/review.sh <target> [root]
   ```
   (A heredoc works too.) It runs `codex exec` read-only over the project and prints codex's final review to stdout. Takes ~30s–2min — let it run, don't interrupt. Optional `[root]` overrides the working root (defaults to the target's directory).

5. **Present the result:**
   - Show codex's review **verbatim** under a `## Codex 的审查` heading. Do not paraphrase or trim it.
   - Then add a `## 我的甄别` section applying the **receiving-code-review** mindset: verify codex's claims against the actual code/spec — which findings are solid and worth acting on, which are wrong, out of scope, or questionable. Be specific; do NOT rubber-stamp and do NOT reflexively agree.
   - Let the user decide what to act on. Do NOT auto-edit the target unless the user asks.

## Coverage checklist (a reminder when composing the prompt)

- **spec / design doc:** requirement completeness; internal contradictions; scope & YAGNI; ambiguities; feasibility against the ACTUAL codebase; unaddressed risks/edge cases.
- **plan:** step feasibility against the real codebase; dependency/ordering problems; missing steps or verification gaps; risky/likely-to-fail steps; over-engineering; testability.
- **code:** correctness bugs; edge cases; security; simplification/reuse opportunities; severity per finding.

## Notes

- **read-only sandbox**: codex never modifies any file during review.
- Codex binary is auto-resolved (Codex.app, then Cursor extension, then `codex` on PATH). Override with `CODEX_BIN`.
- Auth is reused from `~/.codex` (ChatGPT login). codex also auto-loads project `AGENTS.md`, so project conventions written there reach the reviewer for free.
- If `review.sh` reports "codex binary not found", the Codex app/CLI isn't installed where expected — tell the user.

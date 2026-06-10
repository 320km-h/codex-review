# codex-review

A manual, user-triggered **[Claude Code](https://claude.com/claude-code) skill** that sends a
spec, plan, or code target to the local **Codex CLI** for an external, second-opinion review.

Born from the habit of taking a spec / plan / code output to Codex for an outside, skeptical
perspective — automated so the prompt-crafting and copy-paste loop disappears, while *when* to
use it stays a deliberate choice (simple tasks skip it).

## How it works

1. You point it at a target (a file or directory) via `/codex-review <path>`.
2. Claude composes a review prompt from the current conversation context — what the target is,
   the tech stack, what changed, where the risk is — tailored per invocation (no fixed template).
3. `scripts/review.sh` runs `codex exec` **read-only** over the project and returns Codex's verdict.
4. Claude shows Codex's review verbatim, then triages it (verifying each claim against the actual
   code / spec) so you decide what to act on. Nothing is auto-applied.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- A Codex CLI binary — resolved in this order:
  - `/Applications/Codex.app/Contents/Resources/codex`
  - `codex` on your `PATH`
  - the newest Cursor `openai.chatgpt` extension bundle
  - or set `CODEX_BIN` to the binary path
- Codex auth in `~/.codex` (ChatGPT login or API key)

## Install

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/320km-h/codex-review.git ~/.claude/skills/codex-review
```

Or drop it under `.claude/skills/codex-review/` inside a repo as a per-project skill. Start a new
Claude Code session so the skill is picked up.

## Usage

In Claude Code:

```
/codex-review path/to/spec.md
/codex-review src/payments/
```

If you don't pass a target, the skill asks you for one — it never guesses.

The script can also be run directly (the review prompt is read from stdin):

```bash
printf '%s' "$YOUR_REVIEW_PROMPT" | bash scripts/review.sh <target> [root]
```

- `target` — file or directory to review (required)
- `root` — working root Codex reads from (default: the target's directory)

Codex runs in a **read-only sandbox** and never modifies files. It also auto-loads your project's
`AGENTS.md`, so conventions written there reach the reviewer for free. A run takes ~30s–2min.

## Design notes

- **Manual trigger, not automatic.** No hooks, no auto-rule. Complex work gets the review;
  simple work skips it.
- **No default target.** You always name what to review (a file or directory).
- **Prompt composed dynamically by Claude, not fixed templates.** The model already knows what the
  target is and what matters most, so it writes the review focus per invocation and pipes it to
  `review.sh` on stdin. `SKILL.md` keeps only a spec / plan / code *coverage checklist* as a
  reminder. The shell script hard-codes no prompt text.
- **Whole-project, read-only.** `codex exec -s read-only -C <root>` lets Codex cross-check the
  target against the real codebase but never writes.
- **Verbatim + triage.** Codex's review is shown as-is, then triaged with a skeptical
  "receiving-code-review" mindset — weak findings flagged, nothing rubber-stamped.

## License

[MIT](LICENSE)
# codex-review
A Claude Code skill that sends a spec, plan, or code target to the local Codex CLI for an external, read-only second-opinion review.

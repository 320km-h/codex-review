#!/usr/bin/env bash
# Send a target (spec / plan / code) to the Codex CLI for a read-only, second-opinion review.
#
# This is a thin transport layer. The REVIEW PROMPT is composed by the caller (Claude,
# using the current conversation context) and passed on STDIN — there are no hard-coded
# prompt templates here. The script only resolves the codex binary, runs it read-only over
# the project, and prints codex's final review to stdout.
#
# Usage: printf '%s' "$PROMPT" | review.sh <target> [root]
#   target : path to the file or directory to review (required)
#   root   : working root codex reads from (default: target's dir, or target if a dir)
#   stdin  : the review prompt / focus instructions (required, non-empty)
#
# Streamed agent log goes to a temp file, shown only if codex fails.
# Override the binary with CODEX_BIN.
set -euo pipefail

target="${1:?target path required}"
root="${2:-}"

# --- read caller-composed prompt from stdin --------------------------------
prompt_body="$(cat)"
if [[ -z "${prompt_body//[[:space:]]/}" ]]; then
  echo "no review prompt provided on stdin" >&2
  exit 1
fi

# --- resolve codex binary --------------------------------------------------
if [[ -z "${CODEX_BIN:-}" ]]; then
  candidates=(
    "/Applications/Codex.app/Contents/Resources/codex"
    "$(command -v codex 2>/dev/null || true)"
  )
  # newest Cursor-bundled codex, if present
  while IFS= read -r c; do candidates+=("$c"); done < <(
    ls -t "$HOME"/.cursor/extensions/openai.chatgpt-*/bin/*/codex 2>/dev/null || true
  )
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -x "$c" ]]; then CODEX_BIN="$c"; break; fi
  done
fi
if [[ -z "${CODEX_BIN:-}" || ! -x "$CODEX_BIN" ]]; then
  echo "codex binary not found; set CODEX_BIN to its path" >&2
  exit 1
fi

# --- resolve target + root -------------------------------------------------
if [[ ! -e "$target" ]]; then
  echo "target not found: $target" >&2
  exit 1
fi
target_abs="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
if [[ -z "$root" ]]; then
  if [[ -d "$target_abs" ]]; then root="$target_abs"; else root="$(dirname "$target_abs")"; fi
fi

# --- assemble final prompt -------------------------------------------------
prompt="$prompt_body

Review target: $target_abs
This is a READ-ONLY external review. Do NOT modify any files — report findings only."

# --- run codex (codex's own stdin is /dev/null so it never blocks on it) ---
out="$(mktemp -t codex-review-out.XXXXXX)"
log="$(mktemp -t codex-review-log.XXXXXX)"
trap 'rm -f "$out" "$log"' EXIT

if ! "$CODEX_BIN" exec \
      -s read-only \
      --skip-git-repo-check \
      --color never \
      -C "$root" \
      -o "$out" \
      "$prompt" </dev/null >"$log" 2>&1; then
  echo "codex exec failed:" >&2
  cat "$log" >&2
  exit 1
fi

cat "$out"

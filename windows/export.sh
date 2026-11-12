#!/bin/sh
# Rebuilds windows/ from this PC's Claude Code setup. Run in Git Bash: sh windows/export.sh
# This file is the list of what goes into the (public) repository. Everything else in
# ~/.claude stays on the PC: desk topic files, projects/*/memory, skills/synced.
set -eu

SRC="$HOME/.claude"
OUT="$(cd "$(dirname "$0")" && pwd)"

rm -rf "$OUT/claude" "$OUT/pwsh" "$OUT/wt"
mkdir -p "$OUT/claude/hooks" "$OUT/claude/skills" "$OUT/pwsh" "$OUT/wt"

cp "$SRC/settings.local.json" "$SRC/statusline-command.sh" "$OUT/claude/"
cp "$SRC/hooks/dev-start-hint.js" "$SRC/hooks/notify.ps1" "$OUT/claude/hooks/"
for s in dev-start dev-end dewrite socratic-tutor writing-for-agents; do
  cp -R "$SRC/skills/$s" "$OUT/claude/skills/"
done

# Kept local: the dewrite sample documents. skills/to-questionnaire is kept local too
# (it is absent from the loop above).
rm -rf "$OUT/claude/skills/dewrite/references/samples"
find "$OUT/claude" -name '*.bak*' -delete

# remote = account-side environment id, model = written by /model
jq 'del(.remote, .model)' "$SRC/settings.json" > "$OUT/claude/settings.json"
# CLAUDE.md without the lines that load desk files
grep -v 'desk/' "$SRC/CLAUDE.md" > "$OUT/claude/CLAUDE.md"

cp "$SRC/desk/setup.md" "$SRC/desk/setup-agent.md" "$OUT/"
cp "$(cygpath -u "$(pwsh -NoProfile -Command '$PROFILE')")" "$OUT/pwsh/"
cp "$(cygpath -u "$LOCALAPPDATA")/Microsoft/Windows Terminal/Fragments/claude-cc/cc-projects.json" "$OUT/wt/"

# Gate: key-like strings and e-mail addresses (upstream LICENSE files carry public ones).
# A hit stops the export for a human read.
if grep -rnIE 'env_[A-Za-z0-9]{10,}|gh[opsu]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9_-]{20,}|[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' \
     "$OUT" --exclude=export.sh --exclude='LICENSE*'; then
  echo "export.sh: review the hits above before committing" >&2
  exit 1
fi
echo "export.sh: ok"

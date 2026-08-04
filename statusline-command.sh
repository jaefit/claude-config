#!/bin/sh
# Claude Code status line — 2 lines:
#   line 1 (location): root › relative/path breadcrumb (branch ✚N) · MMDD(DAY) HH:MM
#   line 2 (state):    model (effort) · ctx "label mini-bar %" (own color) ·
#                      usage group: "usage 5h bar% / 7d bar%" (shared color,
#                      slash-bound pair; ctx is a different kind of metric
#                      so it stays its own segment/color). Model+effort share
#                      one block/annotation like line 1's "root (branch)":
#                      parens dim gray, no separator between name and paren.
input=$(cat)

proj_raw=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
cwd_raw=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
# resets_at may arrive as epoch seconds or an ISO-8601 string depending on
# version; normalize both to epoch via jq (fromdate), empty on parse failure.
five_reset=$(echo "$input" | jq -r '(.rate_limits.five_hour.resets_at // empty) | if type == "number" then floor else (try fromdate catch empty) end')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
now_date=$(LC_ALL=C date '+%m%d(%a)' | tr '[:lower:]' '[:upper:]')
now_time=$(date +%H:%M)

if [ -z "$proj_raw" ]; then proj_raw="$cwd_raw"; fi

# Catppuccin Mocha palette, truecolor (24-bit) escapes since iTerm2 supports
# it — gives exact hex reproduction instead of the nearest 256-color slot.
# Color vars hold REAL escape bytes (built from $ESC), not literal "\033"
# text, so they render correctly no matter how they're later used — spliced
# into a printf format string, passed as a %s argument, or glued together via
# plain shell string concatenation. (Literal-text color vars only become real
# escapes when they sit inside a printf FORMAT string; a prior version of
# this script built the usage-group slash via plain concatenation, which
# printed the escape codes as literal `\033[...m` text on screen instead of
# color. Baking in real bytes here eliminates that entire bug class instead
# of special-casing each call site.)
ESC=$(printf '\033')
RESET="${ESC}[0m"
SEP="${ESC}[38;2;127;132;156m"   # Overlay1  #7f849c — separators (›, ·, parens, slash, "usage" label)
ROOT_C="${ESC}[38;2;166;227;161m" # Green     #a6e3a1 — project root (anchor)
REL_C="${ESC}[38;2;166;173;200m"  # Subtext0  #a6adc8 — relative path (de-emphasized vs root)
MODEL_C="${ESC}[38;2;203;166;247m" # Mauve    #cba6f7 — model + effort (one block, one color)
CTX_C="${ESC}[38;2;137;220;235m"  # Sky       #89dceb — context usage
USAGE_C="${ESC}[38;2;245;194;231m" # Pink     #f5c2e7 — shared by 5h + 7d plan-usage group
GIT_C="${ESC}[38;2;148;226;213m"  # Teal      #94e2d5 — git branch/status
TIME_C="${ESC}[38;2;250;179;135m" # Peach     #fab387 — shared by date + time (one datetime block, one color)

tildify() {
  case "$1" in
    "$HOME") printf '~' ;;
    "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;;
    *) printf '%s' "$1" ;;
  esac
}

proj_t=$(tildify "$proj_raw")
cwd_t=$(tildify "$cwd_raw")

# root = basename of the project root (workspace.project_dir when Claude Code
# provides it — this already reflects the detected project root, so no extra
# git lookup is needed). Falls back to cwd's own basename if cwd isn't
# actually nested under that root (e.g. an added directory outside it).
root="${proj_t##*/}"
rel=""

case "$cwd_t" in
  "$proj_t")
    rel=""
    ;;
  "$proj_t"/*)
    rel="${cwd_t#"$proj_t"/}"
    ;;
  *)
    root="${cwd_t##*/}"
    rel=""
    ;;
esac

# ---- Line 1: location breadcrumb (root › relative/path) ----
printf "${ROOT_C}%s${RESET}" "$root"

if [ -n "$rel" ]; then
  oldIFS="$IFS"
  IFS='/'
  set -f
  set -- $rel
  set +f
  IFS="$oldIFS"
  count=$#

  if [ "$count" -le 2 ]; then
    printf "${SEP} › ${RESET}"
    printf "${REL_C}%s${RESET}" "$rel"
  else
    while [ "$#" -gt 2 ]; do shift; done
    printf "${SEP} › ${RESET}"
    printf "${REL_C}…${RESET}"
    printf "${SEP} › ${RESET}"
    printf "${REL_C}%s/%s${RESET}" "$1" "$2"
  fi
fi

# ---- Git segment: (branch ✚N) or (short-sha ✚N), only inside a git repo ----
# Cheap, guarded commands only (no fetch); stderr silenced so a git failure
# (or not being in a repo at all) just omits the segment, never prints an error.
git_branch=$(git -C "$cwd_raw" symbolic-ref --short HEAD 2>/dev/null)
if [ -z "$git_branch" ]; then
  git_branch=$(git -C "$cwd_raw" rev-parse --short HEAD 2>/dev/null)
fi

if [ -n "$git_branch" ]; then
  git_changed=$(git -C "$cwd_raw" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  git_changed=${git_changed:-0}

  if [ "$git_changed" -gt 0 ] 2>/dev/null; then
    git_seg="${git_branch} ✚${git_changed}"
  else
    git_seg="$git_branch"
  fi

  printf " ${SEP}(${RESET}${GIT_C}%s${RESET}${SEP})${RESET}" "$git_seg"
fi

# ---- Date + time, one datetime block at the end of line 1 (single shared color) ----
printf "${SEP} · ${RESET}${TIME_C}%s %s${RESET}" "$now_date" "$now_time"

printf '\n'

# ---- Line 2: state (model · effort · ctx/5h/7d, each own fixed pastel) ----
printed=0

sep() {
  if [ "$printed" -eq 1 ]; then
    printf "${SEP} · ${RESET}"
  fi
}

# fmt_metric label pct color -> echoes "label bar pct%" (colored), 5-segment
# mini-bar (each segment = 20%, rounded to nearest via (pct+10)/20). Pure
# formatter, no sep()/printed side effects, so it can be composed (e.g. into
# the slash-bound usage group) as well as used standalone.
fmt_metric() {
  f_label="$1"
  f_pct="$2"
  f_color="$3"

  f_filled=$(( (f_pct + 10) / 20 ))
  if [ "$f_filled" -gt 5 ]; then f_filled=5; fi
  if [ "$f_filled" -lt 0 ]; then f_filled=0; fi
  f_empty=$((5 - f_filled))
  f_bar=""
  f_i=0
  while [ "$f_i" -lt "$f_filled" ]; do f_bar="${f_bar}▓"; f_i=$((f_i+1)); done
  f_i=0
  while [ "$f_i" -lt "$f_empty" ]; do f_bar="${f_bar}░"; f_i=$((f_i+1)); done

  printf "${f_color}%s %s %s%%${RESET}" "$f_label" "$f_bar" "$f_pct"
}

# metric label pct color -> fmt_metric as its own standalone "· "-joined segment.
metric() {
  sep
  fmt_metric "$1" "$2" "$3"
  printed=1
}

if [ -n "$model" ]; then
  sep
  printf "${MODEL_C}%s${RESET}" "$model"
  if [ -n "$effort" ]; then
    printf " ${SEP}(${RESET}${MODEL_C}%s${RESET}${SEP})${RESET}" "$effort"
  fi
  printed=1
fi

if [ -n "$used_pct" ]; then
  pct=$(printf "%.0f" "$used_pct")
  metric "ctx" "$pct" "$CTX_C"
fi

# Usage group: 5h + 7d share one color and one "usage" label, slash-bound
# as a pair (tighter than the "·" used between other segments) since they're
# the same kind of metric (plan usage limits).
usage_body=""
if [ -n "$five" ]; then
  fivep=$(printf "%.0f" "$five")
  usage_body=$(fmt_metric "5h" "$fivep" "$USAGE_C")
  # 5h window reset clock, annotation-style (dim parens) like "model (effort)".
  # BSD date: -r takes epoch seconds. Guarded so a bad value just omits it.
  if [ -n "$five_reset" ]; then
    five_reset_hm=$(date -r "$five_reset" +%H:%M 2>/dev/null)
    if [ -n "$five_reset_hm" ]; then
      usage_body="${usage_body} ${SEP}(↻${five_reset_hm})${RESET}"
    fi
  fi
fi
if [ -n "$week" ]; then
  weekp=$(printf "%.0f" "$week")
  week_seg=$(fmt_metric "7d" "$weekp" "$USAGE_C")
  if [ -n "$usage_body" ]; then
    usage_body="${usage_body}${SEP} / ${RESET}${week_seg}"
  else
    usage_body="$week_seg"
  fi
fi

if [ -n "$usage_body" ]; then
  sep
  printf "${SEP}usage${RESET} %s" "$usage_body"
  printed=1
fi

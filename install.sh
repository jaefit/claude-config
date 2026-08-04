#!/bin/bash
# claude-config installer — 개인 Claude Code 설정을 ~/.claude 에 연결한다.
#
#   ./install.sh            # symlink 모드(기본): repo 파일을 ~/.claude 로 링크
#                           #   -> 이후 양쪽 머신에서 git pull/push 만으로 동기화
#   ./install.sh --copy     # 복사 모드: 링크 없이 파일을 복사 (repo 지워도 동작)
#
# 멱등. 기존 파일은 ~/.claude/_migrate-backup-<ts>/ 로 백업 후 교체.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude"
MODE=link
for a in "$@"; do
  case "$a" in
    --copy) MODE=copy ;;
    --link) MODE=link ;;
    *) echo "unknown option: $a"; exit 2 ;;
  esac
done

say()  { printf '\033[38;2;166;227;161m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;250;179;135m!!!\033[0m %s\n' "$*"; }

# ---------- 0. 의존성 ----------
missing=()
for c in jq node python3; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
  warn "없는 명령: ${missing[*]}"
  warn "  jq   -> brew install jq     (status line)"
  warn "  node -> brew install node   (hooks)"
  warn "  python3 -> macOS 기본 /usr/bin/python3 (알림 hook)"
  exit 1
fi
command -v claude >/dev/null 2>&1 || { warn "claude CLI 없음. Claude Code 먼저 설치."; exit 1; }

# ---------- 1. 백업 ----------
BK="$DEST/_migrate-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST/hooks" "$DEST/skills" "$DEST/agents"
backup() {  # $1 = ~/.claude 기준 상대경로
  [ -e "$DEST/$1" ] || [ -L "$DEST/$1" ] || return 0
  mkdir -p "$BK/$(dirname "$1")"
  cp -aR "$DEST/$1" "$BK/$1"
}

# ---------- 2. 배치 ----------
place() {  # $1 = repo 내 경로, $2 = ~/.claude 기준 경로
  backup "$2"
  rm -rf "$DEST/$2"
  if [ "$MODE" = link ]; then ln -s "$REPO/$1" "$DEST/$2"; else cp -aR "$REPO/$1" "$DEST/$2"; fi
}

place settings.json            settings.json
place settings.local.json      settings.local.json
place statusline-command.sh    statusline-command.sh
place hooks/notify.py          hooks/notify.py
place hooks/dev-start-hint.js  hooks/dev-start-hint.js
for s in dev-start dev-end proofread review-paper; do place "skills/$s" "skills/$s"; done
for a in proofreader r-reviewer; do place "agents/$a.md" "agents/$a.md"; done
say "$MODE 모드로 배치 완료 (개인 파일 12개)"


[ -d "$BK" ] && say "백업: $BK"

# ---------- 3. 공개물: 파일 아니라 '선언'으로 이식 ----------
# 플러그인 3개는 settings.json 의 extraKnownMarketplaces/enabledPlugins 를 보고
# 첫 실행 때 GitHub 에서 자동 설치된다. 여기서 할 일은 MCP 서버 하나뿐.
if claude mcp list 2>/dev/null | grep -q caveman-shrink; then
  say "mcp caveman-shrink 이미 등록됨"
else
  claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink \
    && say "mcp caveman-shrink 등록 (user scope)" \
    || warn "실패 — 수동: claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink"
fi

# ---------- 4. 검증 ----------
jq -e . "$DEST/settings.json" >/dev/null && say "settings.json JSON 유효"
printf '{"model":{"display_name":"test"},"workspace":{"current_dir":"%s"}}' "$HOME" \
  | sh "$DEST/statusline-command.sh" >/dev/null 2>&1 \
  && say "status line 실행 OK" || warn "status line 실행 실패 — jq 확인"

cat <<EOF

끝. 다음:
  1. claude 실행 -> 플러그인 3개(caveman, frontend-design, swift-lsp) 자동 설치
     확인: /plugin , /status
  2. /login
  3. (symlink 모드) 설정 고치면 이 repo 에서 git commit + push -> 다른 머신 git pull

주의: 이 설정은 permissions.defaultMode = "bypassPermissions" 와
skipDangerousModePermissionPrompt = true 를 포함한다. Claude Code 가 툴 실행 승인을
묻지 않고 바로 실행한다는 뜻이다. 공용 머신이면 settings.json 에서 두 키를 지워라.

롤백: cp -aR $BK/. ~/.claude/
EOF

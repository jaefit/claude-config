#!/bin/bash
# claude-config installer — 개인 Claude Code 설정을 ~/.claude 에 연결한다.
#
#   ./install.sh            # symlink 모드(기본): repo 파일을 ~/.claude 로 링크
#                           #   -> 이후 양쪽 머신에서 git pull/push 만으로 동기화
#   ./install.sh --copy     # 복사 모드: 링크 없이 파일을 복사 (repo 지워도 동작)
#   ./install.sh --with-mcp # caveman-shrink MCP 도 등록 (기본 제외 — 아래 주석 참고)
#
# 멱등. 기존 파일은 ~/.claude/_migrate-backup-<ts>/ 로 백업 후 교체.
# 철수는 ./uninstall.sh 참고.
#
# macOS / Linux / Windows(Git Bash) 겸용.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude"
MODE=link
WITH_MCP=0
for a in "$@"; do
  case "$a" in
    --copy) MODE=copy ;;
    --link) MODE=link ;;
    --with-mcp) WITH_MCP=1 ;;
    *) echo "unknown option: $a"; exit 2 ;;
  esac
done

say()  { printf '\033[38;2;166;227;161m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;250;179;135m!!!\033[0m %s\n' "$*"; }

# ---------- 0. 플랫폼 ----------
case "$(uname -s)" in
  Darwin)            OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=win ;;
  *)                 OS=linux ;;
esac
say "플랫폼: $OS"

# ---------- 1. 의존성 ----------
# python 은 Windows 에서 python3 대신 python 으로 깔리는 경우가 많다 — 셋 중 하나면 통과.
missing=()
for c in jq node; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1 || missing+=("python3")
if [ ${#missing[@]} -gt 0 ]; then
  warn "없는 명령: ${missing[*]}"
  if [ "$OS" = win ]; then
    warn "  winget install jqlang.jq OpenJS.NodeJS Python.Python.3.12"
    warn "  설치 후 새 터미널을 열어야 PATH 가 잡힌다."
  elif [ "$OS" = mac ]; then
    warn "  brew install jq node       (python3 는 macOS 기본 /usr/bin/python3)"
  else
    warn "  apt install jq nodejs python3   (배포판에 맞게)"
  fi
  exit 1
fi
command -v claude >/dev/null 2>&1 || { warn "claude CLI 없음. Claude Code 먼저 설치."; exit 1; }

# ---------- 2. 백업 ----------
BK="$DEST/_migrate-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST/hooks" "$DEST/skills" "$DEST/agents"
backup() {  # $1 = ~/.claude 기준 상대경로
  [ -e "$DEST/$1" ] || [ -L "$DEST/$1" ] || return 0
  mkdir -p "$BK/$(dirname "$1")"
  cp -aR "$DEST/$1" "$BK/$1"
}

# ---------- 3. 배치 ----------
LINK_FAILED=0
place() {  # $1 = repo 내 경로, $2 = ~/.claude 기준 경로
  backup "$2"
  rm -rf "$DEST/$2"
  if [ "$MODE" = link ]; then
    ln -s "$REPO/$1" "$DEST/$2"
    # Windows: 개발자 모드/권한이 없으면 ln 이 조용히 '복사본'을 만든다.
    # 그러면 git pull 로 동기화가 안 되므로 반드시 잡아낸다.
    [ -L "$DEST/$2" ] || LINK_FAILED=1
  else
    cp -aR "$REPO/$1" "$DEST/$2"
  fi
}

place settings.json            settings.json
place settings.local.json      settings.local.json
place statusline-command.sh    statusline-command.sh
place hooks/notify.py          hooks/notify.py
place hooks/notify.sh          hooks/notify.sh
place hooks/dev-start-hint.js  hooks/dev-start-hint.js
for s in dev-start dev-end proofread review-paper; do place "skills/$s" "skills/$s"; done
for a in proofreader r-reviewer; do place "agents/$a.md" "agents/$a.md"; done
say "$MODE 모드로 배치 완료 (개인 파일 13개)"

if [ "$LINK_FAILED" = 1 ]; then
  warn "심링크가 아니라 복사본이 만들어졌다 (Windows 권한 문제)."
  warn "  고치려면: 설정 > 개발자용 > 개발자 모드 ON, 새 Git Bash 에서"
  warn "    MSYS=winsymlinks:nativestrict ./install.sh"
  warn "  그냥 쓰려면 ./install.sh --copy 로 재실행하고, 갱신은 git pull + 재실행."
fi

[ -d "$BK" ] && say "백업: $BK"

# ---------- 4. 공개물: 파일 아니라 '선언'으로 이식 ----------
# 플러그인은 settings.json 의 extraKnownMarketplaces/enabledPlugins 를 보고
# 첫 실행 때 GitHub 에서 자동 설치된다. 여기서 할 일 없음.
#
# caveman-shrink MCP 는 기본으로 등록하지 않는다 — 2026-08 기준 npx 실행이
# CONNECTION_CLOSED 로 실패한다. 되살아나면 --with-mcp 로 등록.
if [ "$WITH_MCP" = 1 ]; then
  if claude mcp list 2>/dev/null | grep -q caveman-shrink; then
    say "mcp caveman-shrink 이미 등록됨"
  else
    claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink \
      && say "mcp caveman-shrink 등록 (user scope)" \
      || warn "실패 — 수동: claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink"
  fi
fi

# ---------- 5. 검증 ----------
jq -e . "$DEST/settings.json" >/dev/null && say "settings.json JSON 유효"
printf '{"model":{"display_name":"test"},"workspace":{"current_dir":"%s"}}' "$HOME" \
  | sh "$DEST/statusline-command.sh" >/dev/null 2>&1 \
  && say "status line 실행 OK" || warn "status line 실행 실패 — jq 확인"
printf '{"message":"install.sh 검증 알림","cwd":"%s"}' "$HOME" \
  | sh "$DEST/hooks/notify.sh" >/dev/null 2>&1 \
  && say "알림 훅 실행 OK (배너가 떴는지 눈으로 확인)" || warn "알림 훅 실행 실패"
node --check "$DEST/hooks/dev-start-hint.js" >/dev/null 2>&1 \
  && say "dev-start 훅 문법 OK" || warn "dev-start 훅 문법 실패"

cat <<MSG

끝. 다음:
  1. claude 실행 -> 플러그인 자동 설치. 확인: /plugin , /status
  2. /login  -> 이어서 /mcp 로 claude.ai 커넥터(Todoist 등) 붙는지 확인
  3. (symlink 모드) 설정 고치면 이 repo 에서 git commit + push -> 다른 머신 git pull

훅은 **새 세션에서만** 로드된다. 고친 직후 같은 세션에서 확인하려 들지 말 것.

주의: 이 설정은 permissions.defaultMode = "bypassPermissions" 와
skipDangerousModePermissionPrompt = true 를 포함한다. Claude Code 가 툴 실행 승인을
묻지 않고 바로 실행한다는 뜻이다. 공용 머신이면 settings.json 에서 두 키를 지워라.

철수: ./uninstall.sh   (회사·임대 장비면 반드시 실행)
롤백: cp -aR $BK/. ~/.claude/
MSG

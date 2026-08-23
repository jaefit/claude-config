#!/bin/bash
# claude-config 철수 — 임대/회사 장비에서 Claude Code 흔적을 지운다.
#
#   ./uninstall.sh          # 지울 목록을 보여주고 타이핑 확인 후 삭제
#   ./uninstall.sh --dry-run  # 목록만 출력, 아무것도 안 지움
#
# 이 스크립트가 지우는 것:
#   ~/.claude.json   MCP OAuth 토큰(Todoist·Gmail·Drive·Calendar·Notion)과 계정 상태
#   ~/.claude/       설정·대화기록(projects/)·history.jsonl·shell-snapshots/·paste-cache/
#
# 이 스크립트가 못 하는 것 (수동, 아래에 다시 안내한다):
#   - Claude Code 로그아웃 (/logout)
#   - claude.ai 계정 쪽 기기 세션 해제
#   - 이 repo 클론 자신을 지우는 것 (실행 중이라 불가)
set -euo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

say()  { printf '\033[38;2;166;227;161m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;250;179;135m!!!\033[0m %s\n' "$*"; }
REPO="$(cd "$(dirname "$0")" && pwd)"

TARGETS=("$HOME/.claude.json" "$HOME/.claude")

echo
say "삭제 대상"
for t in "${TARGETS[@]}"; do
  if [ -e "$t" ]; then
    printf '  %-28s %s\n' "$(du -sh "$t" 2>/dev/null | cut -f1)" "$t"
  else
    printf '  %-28s %s\n' "(없음)" "$t"
  fi
done
echo
say "그중 개인정보가 들어있는 것"
for sub in projects history.jsonl shell-snapshots paste-cache file-history telemetry sessions; do
  p="$HOME/.claude/$sub"
  [ -e "$p" ] && printf '  %-8s %s\n' "$(du -sh "$p" 2>/dev/null | cut -f1)" "$sub"
done
echo

if [ "$DRY" = 1 ]; then
  say "--dry-run — 아무것도 지우지 않았다."
  exit 0
fi

warn "되돌릴 수 없다. 설정은 이 repo(git)에 남아 있지만 대화기록과 토큰은 복구 불가."
printf '계속하려면 %s 를 그대로 입력: ' "DELETE"
read -r ans
[ "$ans" = "DELETE" ] || { warn "취소됨."; exit 1; }

for t in "${TARGETS[@]}"; do
  [ -e "$t" ] || continue
  rm -rf "$t"
  say "삭제: $t"
done

cat <<MSG

로컬 삭제 완료. 남은 것은 손으로 해야 한다:

  1. Claude Code 가 아직 떠 있으면 종료.
  2. claude.ai > Settings > 계정/보안에서 이 기기 세션을 해제.
     로컬 토큰만 지우면 계정 쪽에는 연결 기록이 남는다.
  3. 이 repo 클론 삭제 (스크립트가 자기 자신은 못 지운다):
       cd ~ && rm -rf "$REPO"
  4. (선택) 설치했던 런타임 정리:
       winget uninstall jqlang.jq OpenJS.NodeJS Python.Python.3.12 Git.Git
       npm uninstall -g @anthropic-ai/claude-code
  5. 임대·회사 장비면 다운로드 폴더와 작업 디렉토리에 남긴 파일도 확인.

MSG

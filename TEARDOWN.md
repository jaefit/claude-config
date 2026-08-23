# TEARDOWN — 임대/회사 장비에서 철수 (에이전트용 지시서)

마지막 세션에서 아래 한 줄:

```
~/claude-config/TEARDOWN.md 읽고 그대로 진행해줘.
```

---

## 왜 필요한가

로컬에 남는 것:

| 경로 | 내용 |
|---|---|
| `~/.claude.json` | MCP OAuth 토큰 (Todoist·Gmail·Drive·Calendar·Notion), 계정 상태 |
| `~/.claude/projects/` | 전체 대화기록 — 붙여넣은 코드·경로·업무 내용 |
| `~/.claude/history.jsonl` | 입력한 프롬프트 전문 |
| `~/.claude/shell-snapshots/`, `paste-cache/`, `file-history/` | 실행한 셸 상태, 붙여넣은 내용, 편집 이력 |

장비를 반납하면 이게 그대로 넘어간다.

## 순서

**1. 먼저 사용자에게 확인받는다.** 남길 게 있는지 (작업 산출물, 설정 변경분) 물어라.

**2. 설정 변경분을 살린다.** 연수 중 고친 게 있으면 지우기 전에 push:

```bash
cd ~/claude-config && git status --short
# 변경이 있으면 커밋 + push. 특히 Windows slug 규칙을 실제에 맞게 고쳤다면 반드시.
```

작업 산출물은 이 repo 가 아니라 사용자가 지정하는 곳으로 옮긴다.
**대화기록이나 메모리 파일을 이 repo 에 커밋하지 마라 — PUBLIC repo 다.**

**3. Claude Code 로그아웃.** 세션 안에서 `/logout`.

**4. 로컬 삭제.**

```bash
cd ~/claude-config
./uninstall.sh --dry-run    # 뭐가 지워지는지 먼저 보여준다
./uninstall.sh              # DELETE 를 타이핑해야 진행된다
```

`~/.claude.json` 과 `~/.claude/` 를 통째로 지운다. 되돌릴 수 없다.

**5. 스크립트가 못 하는 것 — 손으로.**

- claude.ai > Settings 에서 **이 기기 세션 해제.** 로컬 토큰만 지우면 계정 쪽에는 연결 기록이 남는다.
- repo 클론 삭제: `cd ~ && rm -rf ~/claude-config` (실행 중인 스크립트가 자기 자신은 못 지운다)
- (선택) 런타임 정리:
  `winget uninstall jqlang.jq OpenJS.NodeJS Python.Python.3.12 Git.Git`
  `npm uninstall -g @anthropic-ai/claude-code`
- 다운로드 폴더, 바탕화면, 작업 디렉토리에 남긴 파일 확인.

**6. 확인.**

```bash
ls -la ~/.claude ~/.claude.json ~/claude-config 2>&1   # 전부 "No such file" 이어야 한다
```

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
| OS 자격증명 저장소 | `git push` 를 한 번이라도 했으면 저장되는 **GitHub 액세스 토큰** |
| `$TMPDIR/claude/` (Windows: `%LOCALAPPDATA%\Temp\claude\`) | 세션 스크래치패드 — 스크립트·중간 산출물 |

장비를 반납하면 이게 그대로 넘어간다.

`uninstall.sh` 가 지우는 건 `~/.claude` 와 `~/.claude.json` 뿐이다. 나머지는 5단계에서 손으로 처리한다.

**장비에 처음 앉을 때 작업 폴더를 하나 정하고, 거기에 이 장비 전용 체크리스트를 만들어라.**
깐 것·로그인한 것·바꾼 설정을 그때그때 한 줄씩 적는다. 몇 주 지나면 기억나지 않는다.
이 문서는 일반 절차고, 반납 당일 실제로 보는 건 그 체크리스트다. (그 파일은 사설 문서다 —
**이 repo 에 커밋하지 마라. PUBLIC 이다.**)

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
- **git 자격증명 삭제.** push 한 번이면 OS 자격증명 저장소에 액세스 토큰이 남는다. 이게 제일 위험하다.
  - Windows: `cmdkey /list | findstr github` 로 확인 후 `cmdkey /delete:LegacyGeneric:target=git:https://github.com`
  - macOS: 키체인 접근에서 `github.com` 항목 삭제
  - Linux: 쓰던 helper 의 저장소 (`~/.git-credentials` 등)
- **스크래치패드 삭제** — `uninstall.sh` 범위 밖이다.
  `rm -rf "${TMPDIR:-/tmp}/claude"` · Windows: `rm -rf "$LOCALAPPDATA/Temp/claude"`
- repo 클론 삭제: `cd ~ && rm -rf ~/claude-config` (실행 중인 스크립트가 자기 자신은 못 지운다)
- **세션 중 깔거나 바꾼 것 되돌리기.** 터미널 폰트, 터미널 설정 파일, 추가로 깐 셸 등.
  예: `winget uninstall Microsoft.PowerShell` / 설정 → 글꼴에서 추가한 폰트 제거 /
  Windows Terminal `settings.json` 백업본으로 원복.
- `~/.ssh` 를 이 장비에서 처음 만들었다면 삭제: `rm -rf ~/.ssh`
- (선택) 런타임 정리:
  `winget uninstall Microsoft.PowerShell jqlang.jq OpenJS.NodeJS Python.Python.3.12 Git.Git`
  `npm uninstall -g @anthropic-ai/claude-code`
- 브라우저·메신저·오피스 등 **이 장비에서 로그인한 계정 전부 로그아웃**, 저장된 비밀번호·쿠키 삭제.
- 다운로드 폴더, 바탕화면, 작업 디렉토리에 남긴 파일 확인.

**6. 확인.**

```bash
ls -la ~/.claude ~/.claude.json ~/claude-config 2>&1   # 전부 "No such file" 이어야 한다
ls -la "${TMPDIR:-/tmp}/claude" 2>&1                     # "No such file"
```
```powershell
cmdkey /list | Select-String github                    # 아무것도 안 나와야 한다
```

하나라도 남아 있으면 해당 단계로 돌아간다.

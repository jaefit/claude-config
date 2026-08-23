# SETUP — 새 머신에 이 설정 올리기 (에이전트용 지시서)

새 노트북에서 Claude Code 를 깔고 **첫 세션에 아래 한 줄만 붙여넣으면 된다.**

```
https://raw.githubusercontent.com/jaefit/claude-config/main/SETUP.md 를 읽고 그대로 실행해줘. 나는 Windows / 관리자 권한 있음. 막히면 물어봐.
```

(OS·권한은 실제에 맞게 고쳐 말할 것. 외부망이 막혀 있으면 이 repo 를 USB 로 옮기고
"클론해둔 claude-config 폴더의 SETUP.md 읽고 실행해줘" 로 대신한다.)

---

## 에이전트가 할 일

아래를 **순서대로** 하되, 기계적으로 따르지 말고 실제 환경을 확인하면서 진행한다.
이 문서는 2026-08 기준으로 쓰였다. 사실과 다르면 문서가 아니라 현실을 믿을 것.

### 0. 환경 파악부터

```bash
uname -s          # Darwin / MINGW64_NT-* (Git Bash) / Linux
command -v claude jq node python3 python git
```

`claude` 가 없으면 Claude Code 부터 설치해야 한다 — 그런데 이 지시서를 Claude Code 안에서
읽고 있다면 이미 깔려 있다는 뜻이다.

### 1. 의존성

- `jq` — status line 이 9군데서 쓴다. 없으면 상태줄이 통째로 깨진다.
- `node` — `hooks/dev-start-hint.js`
- `python3` 또는 `python` — 알림 훅

| OS | 설치 |
|---|---|
| Windows | `winget install jqlang.jq OpenJS.NodeJS Python.Python.3.12 Git.Git` |
| macOS | `brew install jq node` (python3 는 기본 `/usr/bin/python3`) |
| Linux | 배포판 패키지 관리자 |

**Windows 는 설치 후 새 터미널을 열어야 PATH 가 잡힌다.** 같은 셸에서 확인하려 들지 말 것.

Claude Code 는 Windows 에서 hook/statusLine 의 `command` 를 **Git Bash 로 보내고,
Git Bash 가 없으면 PowerShell 로 보낸다.** 이 repo 의 훅은 전부 `sh` 기준이므로
Git Bash 가 반드시 있어야 한다.

### 2. 심링크 여부 결정 (Windows 만 해당)

- **관리자 권한 + 개발자 모드 ON** → 심링크 모드. `git pull` 만으로 갱신되고 양쪽 머신 동기화됨.
  - 설정 > 개발자용 > 개발자 모드 ON
  - 실행할 때 `MSYS=winsymlinks:nativestrict ./install.sh`
- **아니면** → `./install.sh --copy`. 갱신은 `git pull && ./install.sh --copy` 재실행.

`install.sh` 는 심링크가 실제로 만들어졌는지 검사해서, 조용히 복사본이 된 경우 경고한다.
그 경고가 뜨면 `--copy` 로 다시 돌리고 갱신 방법을 바꿔서 기억해 둘 것.

### 3. 클론 + 설치

```bash
git clone https://github.com/jaefit/claude-config.git ~/claude-config
cd ~/claude-config
./install.sh                # 또는 --copy / MSYS=winsymlinks:nativestrict ./install.sh
```

멱등하다. 기존 `~/.claude` 파일은 `~/.claude/_migrate-backup-<ts>/` 로 백업된다.

### 4. 로그인 + 커넥터

```bash
claude
```

- `/login` 으로 계정 로그인.
- `/mcp` 로 claude.ai 커넥터(Todoist·Gmail·Drive·Calendar·Notion)가 붙는지 확인.
  **이건 계정 쪽에 붙어 있어서 로컬로 옮길 게 없다.** 로그인하면 따라온다.
- 플러그인(`caveman`, `superpowers`, `code-review`, `frontend-design`, `swift-lsp`)은
  `settings.json` 의 `extraKnownMarketplaces` + `enabledPlugins` 선언을 보고 첫 실행 때
  GitHub 에서 자동 설치된다. `/plugin` 으로 확인.
  - `swift-lsp` 는 macOS 전용 툴체인이라 Windows 에선 무의미하지만 그냥 둬도 해롭지 않다.
    (settings.json 은 맥과 공유하므로 여기서 지우면 맥에서도 빠진다.)

### 5. 검증 — "파일을 썼다"는 동작 증명이 아니다

**훅은 세션을 새로 시작해야 로드된다.** 반드시 `claude` 를 껐다 켜고 확인한다.

| 확인 | 방법 | 실패 시 |
|---|---|---|
| status line | 새 세션에서 하단 줄이 뜨는가 | `jq` 설치·PATH 확인. `echo '{"model":{"display_name":"t"},"workspace":{"current_dir":"'$HOME'"}}' \| sh ~/.claude/statusline-command.sh` 로 단독 실행 |
| 알림 훅 | 긴 작업 끝날 때 배너가 뜨는가 | `printf '{"message":"t","cwd":"'$HOME'"}' \| sh ~/.claude/hooks/notify.sh` 단독 실행. Windows 는 PowerShell NotifyIcon 풍선을 쓴다 |
| dev-start 훅 | devlog 있는 프로젝트에서 세션 시작 시 안내가 뜨는가 | `node ~/.claude/hooks/dev-start-hint.js` 가 조용히 끝나면 정상(기록 없음) |
| 스킬 | `/dev-start` `/proofread` 등이 목록에 뜨는가 | `~/.claude/skills/` 안에 링크/폴더가 있는지 |
| 에이전트 | `proofreader`, `r-reviewer` 가 잡히는가 | `~/.claude/agents/` 확인 |

### 6. 알려진 이식 함정 (이미 고쳐둔 것 + 아직 남은 것)

**고쳐둔 것** — 그래도 실제로 동작하는지는 확인할 것:

- `hooks/notify.py` 가 macOS `afplay`/`osascript` 하드코딩이었다 → OS 분기 추가.
  Windows 는 `winsound` + PowerShell NotifyIcon.
- `settings.json` 의 알림 훅이 `/usr/bin/python3` 절대경로였다 → `hooks/notify.sh` 래퍼로 교체.
  래퍼가 `python3`/`python`/`py` 중 있는 걸 찾는다.
- `hooks/dev-start-hint.js` 의 slug 계산이 `/` 만 치환했다 → 구분자와 `: . _ 공백` 전부 치환,
  빗나가면 `~/.claude/projects/` 를 스캔하는 폴백 추가.
- `skills/dev-start`·`dev-end` §0 의 `sed` 규칙도 같이 수정.

**아직 확실치 않은 것 — 현장에서 확인할 것:**

- Windows 에서 Claude Code 가 `~/.claude/projects/` 디렉토리 이름을 정확히 어떤 규칙으로
  만드는지 검증된 바 없다. `C:\Users\jay\proj` → `C--Users-jay-proj` 로 가정했다.
  **실제로 디렉토리가 생긴 뒤 `ls ~/.claude/projects` 로 규칙을 직접 확인하고,
  다르면 `hooks/dev-start-hint.js` 의 `slugify()` 와 두 SKILL.md 의 `sed` 를 실제에 맞춰 고쳐라.**
  고쳤으면 commit + push 해서 다음 머신이 덕을 보게 할 것.
- 24-bit 트루컬러 status line 은 Windows Terminal 에서만 제대로 나온다. 구형 `conhost` 는 깨진다.
- `caveman-shrink` MCP 는 2026-08 기준 `npx` 실행이 `CONNECTION_CLOSED` 로 실패한다.
  그래서 `install.sh` 기본에서 뺐다. 되살릴 거면 `./install.sh --with-mcp`.

### 7. 이 설정의 성격 — 사용자에게 반드시 알릴 것

`settings.json` 에 `permissions.defaultMode: "bypassPermissions"` 와
`skipDangerousModePermissionPrompt: true` 가 들어 있다. **Claude Code 가 툴 실행 승인을
묻지 않고 바로 실행한다는 뜻이다.** 공용·회사 장비라면 이 두 키를 지울지 사용자에게 물어라.

### 8. 가져오지 않는 것 (의도된 것이다)

- **대화기록** (`~/.claude/projects/`, `history.jsonl`) — 코드·키·개인정보가 섞여 있다.
- **메모리 파일** (`~/.claude/projects/<slug>/memory/`) — 위와 같은 이유.
- **`~/.claude.json`** — MCP OAuth 토큰과 머신 로컬 상태. 계정 로그인으로 새로 만들어진다.

**이 repo 는 PUBLIC 이다.** 위 세 가지를 여기 커밋하지 마라. `.gitignore` 에 막혀 있지만
`git add -f` 로 우회하지 말 것.

---

## 임대·회사 장비라면

쓰고 나서 반드시 `TEARDOWN.md` 를 따라 철수한다. 로컬 토큰과 대화기록이 남는다.

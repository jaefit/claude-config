# claude-config

개인 Claude Code 전역 설정. **공개물은 선언으로, 개인물만 파일로** 담는다.
**macOS 에서 만들어 macOS 에서 돌고 있다.** 윈도우/리눅스로 옮기려면 아래 [이식 노트](#다른-os-로-옮길-때) 참고.

---

## 다른 OS 에서 이 repo 를 읽는 에이전트에게

목표는 **파일 복사가 아니라 동등 기능 재구성**이다. `install.sh` 는 macOS 전용이므로 실행하지 말 것.
순서대로:

**1. OS 무관 — 값만 옮기면 됨 (내용 수정 불필요)**
- `settings.json` 의 `model` · `effortLevel` · `advisorModel` · `env` 3개 · `permissions` · `skip*` 플래그
- `extraKnownMarketplaces` + `enabledPlugins` — **단 `swift-lsp` 는 빼라** (Swift 툴체인은 macOS 전용)
- `claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink` (노드 기반, OS 무관)
- `skills/` 4개, `agents/` 2개 — 전부 마크다운, 실행 코드 없음 → 그대로 복사

**2. 반드시 고쳐야 하는 것 (안 고치면 조용히 죽음)**
- `hooks/notify.py` — macOS API(`afplay`/`osascript`) 의존. 윈도우용으로 다시 쓸 것
- `statusline-command.sh` — `sh` + `jq` 필요. Git Bash 없으면 `.ps1` 로 포팅
- `hooks/dev-start-hint.js` 와 `skills/dev-start`·`dev-end` 의 slug 계산 — 경로 구분자 가정이 POSIX

상세는 맨 아래 [이식 노트](#다른-os-로-옮길-때) 표 참고.

**3. 검증 (중요 — "설정 파일을 썼다"는 동작 증명이 아니다)**
- hook 은 **세션을 새로 시작해야** 로드된다. 고친 직후 같은 세션에서 확인하려 들지 말 것
- status line: 실제 JSON 을 stdin 으로 물려 스크립트를 직접 실행해 출력이 나오는지 먼저 확인
- slug: 추측하지 말고 `~/.claude/projects/` 에 **Claude Code 가 실제로 만든 디렉토리 이름**을 눈으로 보고 규칙을 맞출 것
- 플러그인: `/plugin` 과 `/status` 로 확인

**4. 이 repo 의 규칙 — 새 머신에서도 지킬 것**
전역 skills/agents 에 **특정 프로젝트의 인명·일정·연구 내용을 적지 않는다.** 전역이라 무관한 세션에
전부 따라 들어오고, 프로젝트가 바뀌면 stale 해지고, repo 를 공유하는 순간 같이 나간다.
그런 건 프로젝트별 `CLAUDE.md` 나 `~/.claude/projects/<slug>/memory/` 에 둔다.

---

## 새 머신 세팅 (macOS, 3줄)

```bash
brew install jq node gh && curl -fsSL https://claude.ai/install.sh | bash
gh repo clone jaefit/claude-config ~/claude-config
~/claude-config/install.sh && claude   # 첫 실행 시 플러그인 자동 설치 → /login
```

`install.sh` 기본은 **symlink 모드** — `~/.claude/*` 가 이 repo 를 가리킨다.
이후 어느 머신에서 설정을 고치든 `git commit && push` / 반대편 `git pull` 로 동기화.
링크 싫으면 `--copy`.

---

## 이식 전략: 공개물 vs 개인물

| | 어떻게 나르나 | repo 안 파일 |
|---|---|---|
| **공개 플러그인** caveman · frontend-design · swift-lsp | `settings.json` 의 `extraKnownMarketplaces` + `enabledPlugins` 선언만. Claude Code 가 첫 실행 때 GitHub 에서 clone | 0개 |
| **공개 MCP** caveman-shrink | `claude mcp add --scope user caveman-shrink -- npx -y caveman-shrink` (install.sh 가 실행) | 0개 |
| **개인 설정** settings · statusline · hooks 2 · skills 4 · agents 2 | 이 repo (약 40KB) | 12개 |

플러그인 캐시(`~/.claude/plugins/cache`)나 caveman 소스를 커밋할 이유가 없다 — 버전 고정이
필요하면 `enabledPlugins` 대신 마켓플레이스 커밋 SHA 를 적어두는 쪽이 낫다.

## 담긴 것 (개인물 12개)

```
settings.json           전역 설정 — 경로는 전부 $HOME (아래 참고)
settings.local.json     로컬 권한 allow 2줄
statusline-command.sh   2줄 status line, Catppuccin Mocha 24-bit
hooks/notify.py            Notification  → macOS 알림
hooks/dev-start-hint.js    SessionStart  → dev-log 있으면 /dev-start 안내
skills/{dev-start,dev-end,proofread,review-paper}/SKILL.md
agents/{proofreader,r-reviewer}.md
install.sh              ~/.claude 로 symlink(기본) 또는 copy
```

### settings.json 주요 값
`model opus[1m]` · `effortLevel xhigh` · `advisorModel fable` ·
`permissions.defaultMode bypassPermissions` · `skipDangerousModePermissionPrompt` ·
`skipAutoPermissionPrompt` · `agentPushNotifEnabled false` ·
env `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` `CLAUDE_CODE_NO_FLICKER=1` `CLAUDE_CODE_THINKING_ANIMATION=simple`

> **보안:** `bypassPermissions` + `skipDangerousModePermissionPrompt` = **툴 실행 승인을 묻지
> 않음**. 원본 머신이 그렇게 쓰고 있어서 그대로 옮겼다. 공용 머신이거나 민감 데이터를 다루는
> 머신이면 설치 후 `settings.json` 에서 이 두 키를 지워라.

### 왜 `$HOME` 인가
hook 의 `command`(shell form)와 `statusLine.command` 는 **`sh -c` 를 통해 실행**된다
([docs](https://code.claude.com/docs/en/hooks)). 그래서 `$HOME` 이 확장된다 →
절대경로를 박을 필요가 없고 → 유저명이 다른 머신에서도 그대로 동작하고 → symlink 로 써도 된다.
(단 hook 을 exec form(`args` 사용)으로 쓰면 shell 을 안 거치니 `$HOME` 이 안 먹는다.
그때는 `${CLAUDE_PROJECT_DIR}` 같은 placeholder 만 치환된다.)
`permissions.allow` 패턴은 shell 을 안 거치므로 `$HOME` 대신 glob 을 쓴다.

## 중복 — caveman 이 두 번 깔려 있었다

원본 머신 상태:
1. 마켓플레이스 플러그인 `caveman@caveman`
2. standalone 설치 — `~/.claude/hooks/caveman-*.js` + settings.json hook 등록 +
   `~/.claude/skills/caveman* → ~/.agents/skills/*` 심볼릭 링크

두 훅 파일은 `diff` 결과 바이트 단위 동일(커밋 `63a91eca`). 매 세션 SessionStart 2회, 매
프롬프트 UserPromptSubmit 2회 실행 → caveman 지시문이 컨텍스트에 **2번** 주입. 스킬 목록에도
`caveman` / `caveman:caveman` 둘 다 노출.

→ 이 repo 의 `settings.json` 은 **플러그인 쪽만** 남겼다. 기능 동일, 훅 실행/토큰 주입은 절반.
→ standalone 쪽은 이 repo 에 vendoring 하지 않는다. 필요하면 상류
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) 에서 직접 설치.

원본 머신도 정리하려면:
```bash
rm ~/.claude/skills/caveman ~/.claude/skills/caveman-* ~/.claude/skills/cavecrew  # 링크만 삭제
rm -rf ~/.agents/skills
rm ~/.claude/hooks/caveman-*
# 그리고 settings.json 을 이 repo 것으로 교체 (install.sh 가 함)
```

## 절대 커밋하지 않는 것

`.gitignore` 에 방어용으로 박아뒀다. 요지:

| 항목 | 이유 |
|---|---|
| `~/.claude.json` | userID · oauthAccount · machineID · 프로젝트별 신뢰기록 |
| `~/.claude/projects/**/*.jsonl`, `history.jsonl` | **전체 대화 기록**. 붙여넣은 키·코드·개인정보가 그대로 들어있음. private repo 라도 올리지 말 것 |
| `sessions/ tasks/ teams/ file-history/ shell-snapshots/ paste-cache/ telemetry/ *.log` | 머신 로컬 상태 |
| 인증 토큰 | 새 머신에서 `/login` |
| `plugins/cache/`, `plugins/marketplaces/` | 자동 재설치 |

API 키는 이 repo 에 없다. 앱별로 키를 파일에서 읽는 프로젝트가 있으므로, 그런 프로젝트를
옮길 때는 키를 손으로 넣어야 한다 (각 프로젝트 `CLAUDE.md` 참조).

이 repo 에는 **프로젝트별 컨텍스트를 넣지 않는다.** 전역 스킬/에이전트는 모든 프로젝트에서
로드되므로, 특정 프로젝트의 일정·인명·연구 내용을 여기 적으면 (1) 다른 프로젝트 세션에도
따라 들어오고 (2) 프로젝트가 바뀌면 stale 해지고 (3) 이 repo 를 공유하는 순간 같이 나간다.
그런 내용은 해당 프로젝트의 `CLAUDE.md` 나 `~/.claude/projects/<slug>/memory/` 에 둔다.

## 선택: 프로젝트 메모리도 동기화

`~/.claude/projects/<경로슬러그>/memory/*.md` 는 폴더 **절대경로로 키잉**된다.
유저명·폴더구조가 같은 머신이면 그대로 붙는다:

```bash
# 원본에서 — memory 만, 대화기록(.jsonl)은 제외
tar czf claude-memory.tgz -C ~/.claude $(cd ~/.claude && ls -d projects/*/memory)
# 새 머신에서
tar xzf claude-memory.tgz -C ~/.claude
```

유저명이 다르면 슬러그(`-Users-<이름>-...`)를 rename 해야 한다.
이 repo 에는 넣지 않았다 — 대화기록 디렉터리와 붙어 있어 실수로 같이 올릴 위험이 크다.

---

## 다른 OS 로 옮길 때

이 repo 는 macOS 산이다. **윈도우에서는 그대로 복사하면 일부가 조용히 죽는다.**
아래는 무엇이 왜 깨지는지와 대체 방향 — 자동 설치 스크립트는 macOS 전용이므로,
다른 OS 에서는 이 표를 근거로 각 항목을 손으로(또는 에이전트에게 시켜) 옮기는 걸 전제한다.

| 항목 | 윈도우에서 생기는 일 | 대체 방향 |
|---|---|---|
| `hooks/notify.py` | **작동 안 함.** `afplay`·`osascript`(AppleScript)·`/System/Library/Sounds/Morse.aiff` 전부 macOS 전용. `command` 의 `/usr/bin/python3` 경로도 없음 | PowerShell 토스트(BurntToast 모듈) 또는 `[console]::beep`. hook `command` 는 `python`/`pwsh` 로 |
| `statusline-command.sh` | `sh` + `jq` 필요. Claude Code 는 윈도우에서 `command` 를 **Git Bash 로 보내고, Git Bash 가 없으면 PowerShell 로 보낸다** → Git Bash 없으면 실패 | Git Bash 설치 + `winget install jqlang.jq`, 아니면 같은 로직을 `.ps1` 로 포팅하고 `powershell -NoProfile -File …` 로 호출 |
| `install.sh` | bash 필요(Git Bash 로는 실행됨). 다만 `ln -s` 가 윈도우에선 개발자 모드/관리자 권한 없이는 심볼릭 링크가 아니라 **복사본**이 됨 → repo 와 `~/.claude` 동기화가 끊김 | 복사 모드로 쓰고 갱신은 `git pull` + 재실행. 또는 개발자 모드 켜고 `MSYS=winsymlinks:nativestrict` |
| `settings.json` 의 `$HOME` | **문제 없음.** hook shell form 과 statusLine 은 셸을 거치고, Git Bash·PowerShell 둘 다 `$HOME` 을 확장한다 | 경로는 백슬래시 대신 **슬래시**로 쓸 것 (Git Bash 가 `\` 를 이스케이프로 먹는다). `~` 도 동작 |
| `swift-lsp` 플러그인 | 쓸모 없음 (Swift 툴체인이 macOS 전용) | `enabledPlugins` 에서 제거 |
| `caveman`·`frontend-design` 플러그인, `caveman-shrink` MCP | 노드 기반 → **그대로 동작** | 그대로 |
| `hooks/dev-start-hint.js` 의 slug | `cwd.replace(/\//g, '-')` 가 `C:\Users\…` 의 백슬래시·드라이브 콜론을 못 다룸 → 메모리 디렉토리를 못 찾고 조용히 종료 | 구분자와 `:` 까지 치환하도록 수정. 실제 Claude Code 가 만든 `~/.claude/projects/` 디렉토리 이름을 먼저 확인하고 규칙을 맞출 것 |
| `skills/dev-start`·`dev-end` 의 slug 계산 | 같은 문제 (`pwd \| sed 's#[/._ ]#-#g'`). Git Bash `pwd` 는 `/c/Users/…` 를 주지만 Claude Code 는 윈도우 경로로 이름을 만든다 → 불일치 | 위와 동일. 두 파일 모두 §0 의 폴백 계산을 고칠 것 |
| 24-bit 트루컬러 status line | Windows Terminal 은 지원. 구형 `conhost` 는 깨짐 | Windows Terminal 사용 |

**리눅스**는 `notify.py`(→ `notify-send`)와 `brew` 설치 명령만 바꾸면 나머지는 대체로 그대로 간다.

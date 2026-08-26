# claude-config

개인 Claude Code 전역 설정. **공개물은 선언으로, 개인물만 파일로** 담는다.
**macOS 에서 만들어졌고 Windows(Git Bash)·Linux 도 지원한다.** 플랫폼 의존 코드는 런타임에 분기한다.

---

## 새 머신에 올리기 — 에이전트에게 시킬 것

새 머신의 Claude Code 첫 세션에 이 한 줄:

```
https://raw.githubusercontent.com/jaefit/claude-config/main/SETUP.md 를 읽고 그대로 실행해줘. 나는 <OS> / 관리자 권한 <있음|없음>. 막히면 물어봐.
```

전체 절차·검증·이식 함정은 **[SETUP.md](SETUP.md)** 에 있다. 임대·회사 장비에서 철수할 때는
**[TEARDOWN.md](TEARDOWN.md)** — 로컬에 MCP OAuth 토큰과 대화기록이 남으므로 반드시 밟는다.

수동으로 하려면:

```bash
git clone https://github.com/jaefit/claude-config.git ~/claude-config
cd ~/claude-config && ./install.sh          # Windows 권한 없으면 --copy
```

---

## 이식 상태 (2026-08 기준)

| 항목 | 상태 |
|---|---|
| `hooks/notify.py` | **해결.** macOS `afplay`/`osascript`, Windows `winsound`+NotifyIcon, Linux `notify-send` 로 런타임 분기 |
| 알림 훅 인터프리터 | **해결.** `settings.json` 의 `/usr/bin/python3` 하드코딩을 `hooks/notify.sh` 래퍼로 교체 (`python3`/`python`/`py` 탐색) |
| slug 계산 | **해결 · Windows 실측 검증됨 (2026-08-26).** 구분자·`:`·`.`·`_`·공백 치환 + `~/.claude/projects/` 스캔 폴백. `C:\WINDOWS\system32` → `C--WINDOWS-system32` 로 `slugify()` 결과와 실제 디렉토리 이름이 일치했다. 공백·`.`·`_` 가 든 경로는 아직 미확인 — 어긋나면 고쳐서 push 할 것 |
| `statusline-command.sh` | `sh` + `jq` 필요. Windows 는 Git Bash + `winget install jqlang.jq` |
| `install.sh` | 3-OS 겸용. Windows 에서 심링크가 조용히 복사본이 되는 걸 검사해서 경고한다 |
| `swift-lsp` 플러그인 | Windows 에선 무의미하나 무해. `settings.json` 은 맥과 공유하므로 그대로 둔다 |
| `caveman-shrink` MCP | **등록하지 않는다.** 독립 서버가 아니라 stdio 프록시(다른 MCP 서버를 감싸 description 을 압축)인데 upstream 인자 없이 등록돼 있었다. 게다가 stdio 전용이라 claude.ai HTTP 커넥터는 못 감싼다. 2026-08-23 제거 |

**검증 원칙 — "설정 파일을 썼다"는 동작 증명이 아니다.**
훅은 세션을 새로 시작해야 로드된다. status line 은 JSON 을 stdin 으로 물려 직접 실행해 보고,
slug 은 추측하지 말고 `~/.claude/projects/` 에 실제로 생긴 디렉토리 이름을 눈으로 확인한다.

---

**4. 이 repo 의 규칙 — 새 머신에서도 지킬 것**
전역 skills/agents 에 **특정 프로젝트의 인명·일정·연구 내용을 적지 않는다.** 전역이라 무관한 세션에
전부 따라 들어오고, 프로젝트가 바뀌면 stale 해지고, repo 를 공유하는 순간 같이 나간다.
그런 건 프로젝트별 `CLAUDE.md` 나 `~/.claude/projects/<slug>/memory/` 에 둔다.

---

## 이식 전략: 공개물 vs 개인물

| | 어떻게 나르나 | repo 안 파일 |
|---|---|---|
| **공개 플러그인** caveman · frontend-design · swift-lsp | `settings.json` 의 `extraKnownMarketplaces` + `enabledPlugins` 선언만. Claude Code 가 첫 실행 때 GitHub 에서 clone | 0개 |
| **공개 MCP** | 없다. install.sh 는 MCP 를 하나도 등록하지 않는다 — `caveman-shrink` 를 뺀 경위는 위 「이식 상태」 표 참고 | 0개 |
| **개인 설정** settings · statusline · hooks 2 · skills 4 · agents 2 | 이 repo (약 40KB) | 12개 |

플러그인 캐시(`~/.claude/plugins/cache`)나 caveman 소스를 커밋할 이유가 없다 — 버전 고정이
필요하면 `enabledPlugins` 대신 마켓플레이스 커밋 SHA 를 적어두는 쪽이 낫다.

## 담긴 것

```
settings.json           전역 설정 — 경로는 전부 $HOME (아래 참고)
settings.local.json     로컬 권한 allow 2줄
statusline-command.sh   2줄 status line, Catppuccin Mocha 24-bit
hooks/notify.py            Notification  → 알림 본체 (mac/win/linux 분기)
hooks/notify.sh            └ 인터프리터 탐색 래퍼 (settings.json 이 부르는 쪽)
hooks/dev-start-hint.js    SessionStart  → dev-log 있으면 /dev-start 안내
skills/{dev-start,dev-end,proofread,review-paper}/SKILL.md
agents/{proofreader,r-reviewer}.md
install.sh              ~/.claude 로 symlink(기본) 또는 copy
uninstall.sh            임대·회사 장비 철수 (~/.claude, ~/.claude.json 삭제)
SETUP.md                새 머신 설치 — 에이전트용 지시서
TEARDOWN.md             철수 — 에이전트용 지시서
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

**깨지던 것은 대부분 고쳤다.** 현재 상태는 위 [이식 상태](#이식-상태-2026-08-기준) 표,
실제 절차와 남은 함정은 **[SETUP.md](SETUP.md)** 를 본다. 여기 있던 "무엇이 왜 깨지는가" 표는
그 두 곳으로 옮겼다.

아직 유효한 배경 지식만 남긴다:

- Claude Code 는 윈도우에서 hook/statusLine 의 `command` 를 **Git Bash 로 보내고,
  Git Bash 가 없으면 PowerShell 로 보낸다.** 이 repo 의 훅은 전부 `sh` 기준 → Git Bash 필수.
- `settings.json` 의 `$HOME` 은 **문제 없다.** Git Bash·PowerShell 둘 다 확장한다.
  단 경로는 백슬래시 대신 **슬래시**로 쓸 것 (Git Bash 가 `\` 를 이스케이프로 먹는다).
- 윈도우에서 `ln -s` 는 개발자 모드/관리자 권한이 없으면 심볼릭 링크가 아니라 **복사본**을 만든다.
  `install.sh` 가 이걸 검사해서 경고한다.
- 24-bit 트루컬러 status line 은 Windows Terminal 에서만 제대로 나온다. 구형 `conhost` 는 깨진다.

**리눅스**는 `notify.py` 가 이미 `notify-send` 로 분기하므로 패키지 설치 명령만 바꾸면 대체로 그대로 간다.

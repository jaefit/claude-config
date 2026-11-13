# Claude Code 세팅 정리 (이 PC 기준)

2026-11-12 허브 작성. 다른 PC를 세팅할 때 따라 할 순서대로 적었다. 값은 이날 실제 파일과 명령 출력에서 읽었다. 사람이 읽는 문서라 어느 `CLAUDE.md`도 불러오지 않는다. Claude Code 세션에 옮기는 일을 시킬 때는 같은 폴더의 `setup-agent.md`(런북)를 읽힌다. 이 문서와 런북, 설정 파일은 `github.com/jaefit/claude-config`의 `windows/`에 올려 둔다(2026-11-12 사용자 결정, 공개 저장소).

표시 넷:

- [공통] 어느 OS든 그대로 옮긴다.
- [윈도우] 윈도우에서만 필요하다.
- [이 PC] 이 PC의 경로나 업무에 묶여 있다. 새 PC에서는 고치거나 뺀다.
- [계정] claude.ai 계정을 따라온다. 로그인하면 생기니 복사하지 않는다.

## 1. 깔 것

| 도구 | winget ID | 이 PC 버전 | 쓰는 곳 | 표시 |
|---|---|---|---|---|
| Claude Code | (네이티브 설치, `~/.local/bin/claude.exe`) | 2.1.322, 채널 `latest` | 본체 | 공통 |
| Git (Git Bash 포함) | `Git.Git` | 2.55.0 | 훅과 statusline이 `sh`, `cygpath`로 돈다. Bash 도구도 Git Bash다 | 윈도우 |
| GitHub CLI | `GitHub.cli` | 2.97.0 | push 인증 | 공통 |
| Node.js LTS | `OpenJS.NodeJS.LTS` | 24.19.0 | SessionStart 훅, dev-start·dev-end 슬러그 계산, dewrite `gate.js` | 공통 |
| jq | `jqlang.jq` | 1.8.2 | statusline | 공통 |
| uv | `astral-sh.uv` | 0.12.0 | Python 전부. 맨 `python`은 없다 | 공통 |
| PowerShell 7 | `Microsoft.PowerShell` | 7.7.0 | 기본 셸, `cc`·`ccl`, 알림 훅 | 윈도우 |
| Windows Terminal | `Microsoft.WindowsTerminal` | 1.24 | 탭·분할창 | 윈도우 |
| zoxide | `ajeetdsouza.zoxide` | 0.10.0 | `cc`·`ccs`의 폴더 검색어 | 윈도우 |
| oh-my-posh | (WindowsApps 아래에 있다. 설치 경로는 확인 안 함) | 30.4.0 | 프롬프트, 기본 테마 | 윈도우 |
| fzf | `junegunn.fzf` | 0.74.2 | 깔려 있지만 프로필에서 안 쓴다 | 선택 |

PowerShell 모듈 (`Install-PSResource`, CurrentUser): `BurntToast` 1.1.0(알림 토스트), `CompletionPredictor` 0.1.1(입력 중 추천), `PSReadLine` 2.4.5.

폰트: `D2KodingLigature Nerd Font`. nerd-fonts v3.5.1 `D2Coding.zip`을 받아 사용자 폰트로 직접 깔았다. `oh-my-posh font install`은 exit 70으로 실패했다. 설치된 이름은 K 철자(`D2Koding`)다. `D2Coding`으로 찾으면 목록에 없다.

없는 것: `rg`, `ffmpeg`, R. 그 밖에 Cursor, VS Code, Obsidian이 깔려 있다.

git 설정:

- `gh auth login` 뒤 `gh auth setup-git`. 이걸 안 하면 Git Credential Manager가 보이지 않는 로그인 창을 띄우고 push가 멈춘다(10-26).
- 커밋 작성자 이름과 메일을 `git config --global`로 넣는다.

## 2. `~/.claude`

원본은 `github.com/jaefit/claude-config`(맥 전역 설정)이고 2026-08-04에 이 PC로 옮겼다. `install.sh`가 macOS 전용이라 항목별로 손으로 옮겼다. 새 PC가 윈도우면 저장소 루트(맥 판) 말고 `windows/`에서 가져온다. 윈도우에서 고친 것이 거기에만 있다(아래 「윈도우에서 고친 것」).

`~/.claude` 자체는 로컬 git이고 원격을 붙이지 않는다. 공개 저장소에는 `windows/export.sh`가 고른 것만 복사해 올린다. `~/.claude` 전체(desk, 폴더 메모리, 스킬 전부)는 비공개 저장소 `github.com/jaefit/claude-home`에 파일 스냅샷으로 올린다(2026-11-13 사용자 결정, 절차는 런북 C). 대화 기록과 자격 증명은 어느 쪽에도 올리지 않는다.

- 올리는 것: `CLAUDE.md`(dewrite 줄만), `settings.json`(`remote`, `model` 키 뺌), `settings.local.json`, `statusline-command.sh`, `hooks/dev-start-hint.js`, `hooks/notify.ps1`, 스킬 `dev-start`·`dev-end`·`dewrite`·`socratic-tutor`·`writing-for-agents`, PowerShell 프로필, WT Fragments 파일, 이 문서와 런북.
- 공개 저장소에 안 올리는 것: `desk/`의 나머지 파일, `projects/*/memory/`, `skills/dewrite/references/samples/`, `skills/to-questionnaire/`, `skills/synced/`(계정이 준다). 비공개 `claude-home`에는 다 들어 있다.
- `agents/`, `skills/proofread`, `skills/review-paper`는 저장소 루트 것과 같아서 `windows/`에 다시 넣지 않았다.

| 경로 | 내용 | 표시 |
|---|---|---|
| `CLAUDE.md` | 세 줄. `skills/dewrite/always-on.md`, `desk/user.md`, `desk/rules.md`를 불러온다 | 공통 (불러오는 대상은 아래) |
| `settings.json` | 아래 표 | 공통 |
| `settings.local.json` | 훅·statusline 명령 셋을 허용하는 `permissions.allow` | 공통 |
| `statusline-command.sh` | 두 줄 상태 표시 | 공통 (`jq`, `sh` 필요) |
| `hooks/dev-start-hint.js` | 세션 시작 훅 | 공통, 4번 기능은 이 PC |
| `hooks/notify.ps1` | 알림 훅 | 윈도우 |
| `skills/` | 직접 넣은 스킬 8개와 `synced/` | 아래 |
| `agents/` | `proofreader.md`, `r-reviewer.md` | 공통 |
| `desk/` | 폴더 사이 규칙·지도·주제 파일 | 이 PC |
| `projects/<슬러그>/memory/` | 폴더별 메모리 | 이 PC |

추적하지 않는 것: 대화 기록(`*.jsonl`), `.credentials.json`, `plugins/`, `*.bak*`. 복사하지 않는다.

### settings.json

| 키 | 값 | 뜻 |
|---|---|---|
| `env` | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `CLAUDE_CODE_NO_FLICKER=1`, `CLAUDE_CODE_THINKING_ANIMATION=simple` | 에이전트 팀, 화면 깜빡임 줄이기 |
| `attribution` | `commit` `""`, `pr` `""`, `sessionUrl` `false` | 커밋·PR에 Claude 표시를 넣지 않는다 |
| `permissions.defaultMode` | `bypassPermissions` | 권한 묻지 않음. `skipDangerousModePermissionPrompt`, `skipAutoPermissionPrompt`도 `true` |
| `hooks.Notification` | `pwsh -NoProfile -NonInteractive -File "$(cygpath -w "$HOME/.claude/hooks/notify.ps1")"` | 알림 |
| `hooks.SessionStart` | `node "$HOME/.claude/hooks/dev-start-hint.js"`, timeout 5 | 세션 시작 안내 |
| `statusLine` | `sh "$HOME/.claude/statusline-command.sh"` | |
| `enabledPlugins`, `extraKnownMarketplaces` | 아래 「플러그인」 | |
| `effortLevel` | `xhigh` | 기본 effort |
| `modelSettings` | `claude-opus-5-5` `xhigh`, `claude-fable-5-2` `high`, `claude-fable-5-1` `high` | 모델별 effort |
| `model` | 지금 없음 | 없으면 계정 기본 모델로 뜬다. `/model`에서 고르면 이 키가 생긴다 |
| `advisorModel` | `claude-fable-5-2` | advisor 검토 모델 |
| `autoUpdatesChannel` | `latest` | |
| `tui`, `theme` | `fullscreen`, `dark` | |
| `remoteControlAtStartup` | `true` | 세션을 다른 기기에서 이어 본다 |
| `switchModelsOnFlag`, `agentPushNotifEnabled` | `false`, `false` | |
| `remote.defaultEnvironmentId` | 값은 적지 않는다 | 계정의 클라우드 환경 ID다. 새 PC에 그대로 복사해도 되는지 확인 안 함 |

훅 명령은 `$HOME`과 `cygpath`를 쓴다. Git Bash가 없으면 돌지 않는다. 훅은 새 세션에서만 실린다.

### 플러그인

| 플러그인 | 마켓플레이스 (GitHub) | 버전 | 하는 일 |
|---|---|---|---|
| `superpowers` | `claude-plugins-official` (`anthropics/claude-plugins-official`) | 7.0.0 | 작업 절차 스킬(brainstorming, 계획, TDD, 디버깅, 리뷰). 세션 시작 때 안내를 넣는다 |
| `frontend-design` | 같음 | 1.1.1 | UI 디자인 지침 |
| `code-review` | 같음 | 1.0.1 | PR 리뷰 |
| `pyright-lsp` | 같음 | 1.0.0 | Python LSP |
| `claude-md-management` | 같음 | 1.0.0 | `CLAUDE.md` 점검·갱신 |
| `caveman` | `caveman` (`JuliusBrussee/caveman`) | `ec83e5b` | 짧게 답하는 모드, cavecrew 서브에이전트 셋 |
| `ponytail` | `ponytail` (`DietrichGebert/ponytail`) | 5.3.3 | 최소 변경 모드. 세션별 수준은 `~/.claude/ponytail-modes/` |
| `eli5` | `claude-community` (`anthropics/claude-plugins-community`) | 1.0.0 | 쉬운 설명 |
| `context7` | `anthropic-plugin-directory` | | 라이브러리 문서 MCP. 인증 전 |
| `skill-creator` | `anthropic-plugin-directory` | | 스킬 만들기·평가 |
| `cc-plugin-you-should-know` | `builtin` | | 켜져 있지만 설치 목록에는 없다 |

옮기는 법: `settings.json`의 `enabledPlugins`와 `extraKnownMarketplaces` 두 블록을 그대로 복사하고 새 PC에서 `/plugin`으로 설치됐는지 본다. 복사만으로 저절로 깔리는지는 시험하지 않았다.

출처를 확인 못 한 것: `anthropic-plugin-directory`는 `extraKnownMarketplaces`에도 `plugins/known_marketplaces.json`에도 없다. 세션에 보이는 `finance:*`, `cowork-plugin-management:*` 스킬은 `plugins/installed_plugins.json`에 없다. 둘 다 계정 쪽에서 오는 것으로 보이지만 확인하지 않았다.

### 스킬 (`~/.claude/skills`)

| 스킬 | 출처 | 하는 일 |
|---|---|---|
| `dev-start`, `dev-end` | 자작 (원본 claude-config, 윈도우·허브 모드로 고침) | 세션 캐치업과 마감. 폴더 메모리의 `devlog.md`, `next_todos.md`를 읽고 쓴다. `dev-end`는 커밋하지 않는다 |
| `dewrite` | 자작 | 한·영 AI 티 제거. `always-on.md`는 전역 `CLAUDE.md`가 불러와 늘 켜져 있다. `references/`, `scripts/gate.js` |
| `proofread`, `review-paper` | claude-config | 한국어 학술 문서 교정과 심사. `agents/proofreader.md`, `r-reviewer.md`와 짝 |
| `socratic-tutor` | `janestreet/agent_skills` 고정 사본 @7c6715c (MIT) | 가르치기와 이해 점검. 한국어 진행, 빠른 점검 절을 덧붙였다 |
| `writing-for-agents` | `mattpocock/skills` 고정 사본 @4ae2317 | 에이전트가 읽는 문서 쓰기. 이 PC 규칙(크기 상한, desk 한 곳 쓰기) 절을 덧붙였다 |
| `to-questionnaire` | 같은 사본 | 다른 사람에게 보낼 질문지. `/to-questionnaire`로만 켠다. 한국어로 고쳤다 |
| `synced/` | [계정] | docs, docx, google-workspace, import-memory, morning, pdf, pptx, skill-creator, xlsx |

고정 사본은 원본 링크가 아니다. 원본을 새로 받으면 덧붙인 절이 사라지니 `windows/` 것을 쓴다. `to-questionnaire`는 저장소에 없으니 이 PC에서 복사한다.

### 훅과 statusline

- `dev-start-hint.js`: (1) 새 세션 이름을 `<사용자>-<부모 폴더>-<폴더>`로 정한다. (2) 폴더 메모리에 `devlog.md`가 있으면 `/dev-start` 안내와 지난·오늘 기한 항목을 넣는다. (3) 대화가 압축된 직후에는 체크포인트 기록을 시킨다. (4) `desk/handoff.md`에서 이 폴더 앞으로 온 줄 수와 바뀐 desk 파일을 알린다. 4번은 Desktop 폴더 구조를 전제한다.
- `notify.ps1`: 짧은 beep과 BurntToast 토스트. 제목은 `ClaudeCode > <라벨>`이고 라벨은 `$env:CC_TAB`(`cc`·`ccl`로 연 창), 없으면 Desktop 기준 상대경로다. BurntToast가 없으면 풍선 알림으로 떨어진다.
- `statusline-command.sh`: 첫 줄은 위치(root › 경로, 브랜치, 날짜 시각), 둘째 줄은 모델(effort), 컨텍스트 %, 5시간·7일 사용량.

### 윈도우에서 고친 것

- 메모리 디렉토리 이름: Claude Code는 경로에서 영문·숫자 말고 전부 `-`로 바꾼다. 한글도 글자마다 `-` 하나다(`C:\Users\infomax\Desktop\업무` → `C--Users-infomax-Desktop---`). 이 규칙이 `dev-start-hint.js`와 `dev-start`·`dev-end` §0 세 곳에 들어 있다. Git Bash `tr`·`sed`는 바이트 단위라 한글이 `-` 셋이 되니 node로 계산한다.
- statusline: `date -r`(BSD 전용)을 `date -d "@epoch"`와 같이 쓰게, `C:\...` 백슬래시 경로를 슬래시로 바꾸고 `cygpath -m "$HOME"`으로 `~` 축약이 되게 고쳤다. 고친 뒤에는 샘플 JSON을 `sh statusline-command.sh`에 넣어 두 줄과 `↻HH:MM`이 나오는지 본다.
- 알림: 맥의 `afplay` + `osascript`를 beep + BurntToast로 바꿨다.
- 새 PC의 사용자 이름이나 폴더 위치가 다르면 `projects/` 아래 메모리 디렉토리 이름도 달라진다. 옮긴 메모리는 새 슬러그 이름으로 넣는다.

### 전역 지시와 desk, 메모리

- 전역 `CLAUDE.md`가 매 세션에 싣는 것: dewrite 글쓰기 규칙 12개(1.8KB), `desk/user.md`(사용자와 일하는 방식, 2KB), `desk/rules.md`(폴더 사이 규칙 8개, 2.8KB), 그리고 `rules.md`가 불러오는 `desk/map.md`(폴더 지도, 7.9KB).
- desk 주제 파일(`toolchain`, `infomax`, `workbook-style`, `business-data`, `lseg-data` 등)은 필요한 폴더의 `CLAUDE.md`가 `@~/.claude/desk/<파일>.md`로 불러온다. 목록과 크기 상한은 `desk/paths.md`.
- 폴더 메모리는 `~/.claude/projects/<슬러그>/memory/`에 `MEMORY.md`(색인), `devlog.md`, `next_todos.md`와 사실 하나에 파일 하나.
- `windows/claude/CLAUDE.md`는 dewrite 줄만 싣는다. 새 PC에서 같은 Desktop 폴더 구조를 쓰면 `desk/`를 따로 옮긴 뒤 `user.md`, `rules.md` 두 줄을 다시 넣는다. 다른 구조면 그대로 쓴다.

## 3. PowerShell 프로필 [윈도우]

`C:\Users\infomax\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`. 위에서부터:

1. `oh-my-posh init pwsh` (테마 지정 없음, 기본 테마)
2. PSReadLine: 추천 출처 `HistoryAndPlugin`, 보기 `ListView`, 편집 `Windows`, Tab은 `MenuComplete`
3. `zoxide init powershell`
4. 별칭 `ll`(Get-ChildItem), `g`(git)
5. `claude` 래퍼 함수: 세션 이름을 `<사용자>-<부모 폴더>-<폴더>`로 붙인다(`-n`, `-r`, `-c`, `-p`가 있으면 건드리지 않는다). `claude ds`는 첫 프롬프트로 `/dev-start`를 넣는다
6. `# >>> cc:` ~ `# <<< cc <<<` 블록
7. CompletionPredictor를 `PowerShell.OnIdle`에서 한 번만 불러오는 블록. 프로필에서 바로 Import하면 `pwsh -Command`나 `-File` 실행이 끝나지 않고 멈춘다

cc 블록의 명령:

| 명령 | 하는 일 |
|---|---|
| `cc <폴더> [이름] [색]` | 현재 창에 새 탭으로 Claude |
| `ccs <폴더> [이름] [색] [-H]` | 지금 pane 옆에 분할. `-H`면 아래로 |
| `ccl [프리셋]` | 프리셋 배치. 인자 없으면 전부 탭으로 |
| `ccl [프리셋] resume` | 모든 pane이 `claude ds`(`/dev-start`)로 시작. `ccl resume <프리셋>` 순서도 된다 |

- `<폴더>`는 있는 경로가 먼저고, 없으면 zoxide 검색어다(`ccs vault`).
- 색은 Catppuccin Mocha 이름(red, orange, yellow, green, teal, blue, purple, pink, gray)이나 `#RRGGBB`.
- 이름은 claude가 도는 동안만 `$env:CC_TAB`에 들어가 알림 제목에 쓰인다.
- Tab 완성: 프리셋, 색, 폴더(하위 폴더 먼저, 다음 zoxide 기록).

프리셋(`$CcLayouts`) [이 PC]:

| 프리셋 | pane |
|---|---|
| `monitor` | bondswap_monitor, fwdcd_monitor |
| `repo` | repo_fund |
| `hub` | Desktop, Vault |
| `lab` | project, study |
| `data` | market_feed, signals |
| `news` | ficc_news_alarm |
| `work` | 업무, mailbackup |

첫 항목이 왼쪽, 둘째가 오른쪽, 셋째부터는 오른쪽을 위아래로 쪼갠다. pane이 여럿인 탭은 `bondswap | fwdcd`처럼 합친 제목을 준다.

알아 둘 것:

- 프리셋 이름은 WT Fragments 프로필 `cc <이름>`과 맞아야 한다. 묶음을 바꾸면 `$CcLayouts`와 Fragments를 같이 고친다.
- 프로필을 고친 뒤 이미 열린 셸은 옛 `$CcLayouts`를 쥐고 있다. `. $PROFILE` 하거나 새 탭에서 친다.
- 프로필 27행 사용법 주석의 프리셋 이름(`project`, `mail`)은 옛것이다. 맞는 목록은 위 표다.
- zoxide 출력은 UTF-8로 읽는다. 콘솔 코드페이지 949로 읽으면 한글 경로가 깨진다.

## 4. Windows Terminal [윈도우]

- 설정 파일: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- `profiles.defaults.font.face` = `D2KodingLigature Nerd Font`. 프로필 하나에만 넣으면 그 프로필만 먹는다. 글리프 폭이 어긋나면 `… Nerd Font Mono`.
- 기본 프로필은 PowerShell 7이다.
- Fragments: `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\claude-cc\cc-projects.json`. 스킴 `cc Catppuccin Mocha`와 프로필 13개. 공통 프로필 `cc`(비활성 pane 흐림) 하나와 폴더별 12개다.

| 프로필 | 탭 색 |
|---|---|
| `cc bondswap_monitor` | green `#A6E3A1` |
| `cc fwdcd_monitor` | blue `#89B4FA` |
| `cc repo_fund` | red `#F38BA8` |
| `cc Desktop` | teal `#94E2D5` |
| `cc Vault` | mauve `#CBA6F7` |
| `cc project` | sapphire `#74C7EC` |
| `cc ficc_news_alarm` | pink `#F5C2E7` |
| `cc mailbackup` | peach `#FAB387` |
| `cc 업무` | yellow `#F9E2AF` |
| `cc study` | lavender `#B4BEFE` |
| `cc signals` | sky `#89DCEB` |
| `cc market_feed` | flamingo `#F2CDCD` |

- 폴더별 프로필의 `startingDirectory`는 `C:\Users\infomax\Desktop\...` 절대경로다 [이 PC]. 새 PC에서는 경로를 고친다.
- 배경은 Mocha 바탕과 같은 밝기·채도로 hue만 돌린 틴트다. 노랑·주황 계열은 어두운 배경에서 갈색이 돼서 틴트 없이 기본 바탕을 쓴다.
- WT는 Fragments를 처음 읽을 때 `settings.json`의 `profiles.list`에 `"source": "claude-cc"` 스텁을 스스로 써 넣는다. 원복하려면 프로필의 cc 블록, Fragments 폴더, 이 스텁을 모두 지운다.

## 5. 일하는 방식 [이 PC]

- 프로젝트는 `Desktop` 바로 아래나 `Desktop\task` 아래에 있고 폴더마다 세션 하나다. Desktop 루트는 허브 세션으로 지도·desk·터미널 설정만 맡는다. `task`(상위)와 홈 폴더에서는 세션을 열지 않는다.
- 아침에는 `ccl <프리셋> resume`으로 열어 `/dev-start` 캐치업을 받고, 끝낼 때 `/dev-end`로 devlog와 next_todos를 남긴다. 긴 세션이 압축되면 훅이 체크포인트를 시킨다.
- 세션은 자기 폴더만 고친다. 다른 폴더가 할 일은 `desk/handoff.md`에 한 줄로 남기고, 두 폴더 이상이 쓰는 사실은 desk 주제 파일 한 곳에만 적는다(`desk/rules.md`).
- 권한은 묻지 않는 모드다. 멈추고 묻는 것은 삭제, 원격 push, 외부 발송처럼 되돌리기 어려운 일이다(`desk/user.md`).
- 커밋과 PR에 Claude 표시를 넣지 않는다. 커밋은 사용자가 시킬 때만 한다.
- 설계 문서 초안은 Fable 모델 검토 에이전트로 피드백을 받는다.
- 작업 스케줄러 작업 여섯 개와 클라우드 루틴 둘은 `desk/schedule.md`에 있다.
- Excel 2016, 인포맥스, LSEG Workspace를 다루는 규칙은 `desk/toolchain.md`, `infomax.md`, `lseg-data.md`에 있다. 그 프로그램이 없는 PC에는 필요 없다.

## 6. 계정을 따라오는 것 [계정]

- claude.ai 커넥터: Notion, Todoist, Gmail, Google Calendar, Google Drive, Claude Docs. Canva는 인증 전이다. 새 PC에서 로그인하면 붙는다.
- `skills/synced/` 아래 스킬.
- 클라우드 루틴(RemoteTrigger): 데일리 브리핑, 위클리 리뷰.
- 로컬 MCP 서버는 없다(`~/.claude.json`의 `mcpServers`가 비어 있다). claude-config README의 caveman-shrink 등록 명령은 감쌀 서버 없이 프록시만 등록해 실패하니 따라 하지 않는다.

## 7. 새 PC에서 할 순서

1. 1절 도구를 깔고 폰트를 넣는다. WT `profiles.defaults.font.face`를 맞춘다.
2. Claude Code를 깔고 로그인한다.
3. `gh auth login`, `gh auth setup-git`, git 작성자 설정.
4. 같은 폴더 구조를 쓸 PC면 비공개 `claude-home`을 받아 `.git`만 빼고 `~/.claude`에 넣는다(desk, 메모리, 스킬, 전역 `CLAUDE.md`가 다 들어 있다). 다른 구조면 `claude-config`를 받아 `windows/claude/`를 넣는다.
5. 새 세션을 열어 `/plugin`으로 플러그인 열한 개가 깔렸는지 본다.
6. `Install-PSResource BurntToast, CompletionPredictor`.
7. 프로필을 복사하고 `$CcLayouts`를 새 PC 폴더에 맞게 고친다.
8. Fragments 파일을 복사하고 `startingDirectory`와 프로필 이름을 고친다.
9. 확인: statusline에 샘플 JSON을 넣어 두 줄이 나오는지, 새 세션 이름이 `<사용자>-<부모>-<폴더>`인지, 알림 토스트가 뜨는지, `ccl hub`가 탭 색과 제목대로 열리는지.

## 확인 안 한 것

- `enabledPlugins`만 복사해도 플러그인이 저절로 깔리는지.
- `anthropic-plugin-directory`, `finance:*`, `cowork-plugin-management:*`가 어디서 오는지.
- oh-my-posh를 어느 경로(스토어, winget)로 깔았는지.
- `remote.defaultEnvironmentId`를 새 PC에 그대로 써도 되는지.
- 맥이나 리눅스에서 이 PC 판 훅·statusline이 그대로 도는지(윈도우 분기만 넣고 맥에서 다시 돌려 보지 않았다).

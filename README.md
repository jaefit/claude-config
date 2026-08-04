# claude-config

개인 Claude Code 전역 설정. **공개물은 선언으로, 개인물만 파일로** 담는다.

## 새 머신 세팅 (3줄)

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
legacy/caveman-standalone/  (기본 미설치 — "중복" 항목 참고)
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
→ standalone 파일은 `legacy/` 에 보존만 해둠 (`--legacy` 로 설치 가능, hook 등록은 수동).

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

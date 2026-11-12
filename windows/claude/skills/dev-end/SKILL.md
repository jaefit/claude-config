---
name: dev-end
description: >
  Close out a coding session: record what was done, decisions (with why),
  open todos, and a git (or key-file) snapshot into the project's Claude memory
  dir — so a future session can catch up fast with /dev-start. Summarizes git
  state but NEVER commits. `/dev-end checkpoint` writes only a short devlog entry
  (end of a working day, or right after the conversation was compacted).
  Trigger: /dev-end, "끝낼게", "오늘 작업 정리", "wrap up session", "log this session".
---

# dev-end — 세션 마무리 기록

코딩 세션을 닫으며 **무엇을 했고 / 왜 그렇게 정했고 / 다음에 뭘 할지**를
프로젝트별 Claude memory 디렉토리에 적는다. 다음에 `/dev-start`로 빠르게 복귀하기 위함.

## 모드

- **`/dev-end`** (기본): §1~§7 전부.
- **`/dev-end checkpoint`**: §1·§3 만 — devlog 에 짧은 항목 하나 (한 일·다음 각 3줄 이내, 제목에 `checkpoint`).
  todo 정리·CLAUDE.md 정리는 하지 않는다. 쓰는 때: 여러 날 이어지는 세션의 하루 끝, 대화 압축 직후
  (압축 전 작업이 devlog 에 없을 때 — SessionStart 훅이 알려 준다). 같은 날 체크포인트가 이미 있으면 그 항목에 덧붙인다.
  다음 기본 `/dev-end` 는 그날 체크포인트들을 한 항목으로 합친다.

## 기록 역할 (한 사실은 한 곳에)

| 위치 | 담는 것 | 담지 않는 것 |
|---|---|---|
| `$DIR/devlog.md` | 날짜별 경과: 한 일·결정과 이유·다음 | 지금 유효한 규칙 전체 (그건 CLAUDE.md) |
| `$DIR/next_todos.md` | 열린 일만, 한 줄씩 | 끝난 일, 긴 배경 (배경은 링크로) |
| `~/.claude/desk/user.md` | 사용자 자신, 모든 폴더에 해당하는 일하는 방식 | 한 폴더 일에만 해당하는 피드백 |
| `~/.claude/desk/<주제>.md` | 두 폴더 이상이 쓰는 도구·자료 사실 (툴체인, 인포맥스, 엑셀 문체, 업무 자료, LSEG 등. 목록은 `~/.claude/desk/paths.md`) | 한 폴더만 쓰는 사실 |
| `~/.claude/desk/handoff.md` | 다른 폴더 세션이 할 일 (한 줄, 덧붙이기만) | 이 폴더가 할 일 |
| `$DIR/<topic>.md` + `MEMORY.md` | 이 폴더만 쓰는 비자명한 사실, 이 폴더 일에 대한 피드백 | 두 폴더 이상이 쓰는 사실 (desk 로), 공용 사실의 사본 |
| repo 의 `CLAUDE.md` (프로젝트가 이미 쓰는 경우만) | 지금 유효한 구조·규칙·"다시 제안 말 것" 결론 | 날짜별 경위, 옛 기록, 버전 목록 |

같은 내용을 여러 곳에 쓰지 않는다. 다른 곳에서는 `(세부: CLAUDE.md '절 이름')`, `[[topic]]`, `~/.claude/desk/<주제>.md` 처럼 가리키기만 한다. 다른 폴더의 메모리 디렉토리에는 쓰지 않는다 (설계: `~/.claude/desk/structure-design.md` 3.2).

## 0. 메모리 디렉토리 해석

**시스템 프롬프트에 memory 디렉토리 경로가 이미 주어져 있으면 그걸 쓴다.** 아래 계산은 없을 때의 폴백이다.

```bash
# Claude Code는 경로에서 영문·숫자 말고 전부 -로 바꿔 디렉토리 이름을 만든다.
# 한글도 글자마다 - 하나다 (2.1.321 실측 2026-11-10: Desktop\업무 → C--Users-infomax-Desktop---).
# [Windows] Git Bash의 pwd는 /c/Users/... 를 주지만 Claude Code는 윈도우 경로로
#   이름을 만든다 → cygpath -w 로 윈도우 표기를 얻은 뒤 치환해야 맞는다.
#   실측: C:\Users\infomax\Desktop → C--Users-infomax-Desktop (':' 와 '\' 가 각각 '-')
# tr·sed는 Git Bash에서 바이트 단위라 한글 한 글자가 - 셋이 된다. node로 바꾼다.
WINPWD=$(cygpath -w "$(pwd)" 2>/dev/null || pwd)
DIR="$HOME/.claude/projects/$(node -e "process.stdout.write(process.argv[1].replace(/[^A-Za-z0-9]/g,'-'))" "$WINPWD")/memory"
ls "$DIR" 2>/dev/null
date +%F   # 세션 날짜 (절대값으로 기록)
```

**`$DIR`이 없는데 이 프로젝트에서 전에 작업한 적이 있으면 `mkdir` 하기 전에 멈춘다.**
기록이 다른 이름에 남아 있을 수 있다 (손으로 만든 `C--Users-infomax-Desktop-업무`처럼
한글이 그대로 남은 이름, 다른 버전이 만든 이름). 기록 있는 프로젝트만 뽑아서 눈으로
대조해라. Claude Code 이름에서는 `-` 개수가 한글 글자 수와 맞고, 숫자·영문은 그대로 남아 앵커가 된다:

```bash
ls -d "$HOME"/.claude/projects/*/memory 2>/dev/null | sed 's#.*/projects/##; s#/memory##'
```

찾았으면 사용자 확인 뒤 `$DIR`로 복사하고 `$DIR`에 쓴다. 옛 이름에 append 하면
Claude Code가 다음 세션에 MEMORY.md를 싣지 않는다 (2026-11-10 업무 세션).
정말 처음이면 그때 `mkdir -p "$DIR"`.

devlog·todo·topic 메모리는 `$DIR` 에만 쓴다 (repo 안에 새 기록 파일을 만들지 않는다). repo 쪽은 프로젝트가 이미 쓰는 `CLAUDE.md` 의 정리(§6)만 한다. `$DIR/_retired/` 는 합쳐서 은퇴한 옛 사본이라 읽지도 쓰지도 않는다.

## 1. 세션 내용 수집 (대화에서)

이번 세션 대화를 돌아보고 추린다:
- **한 일** — 끝낸 작업 (파일/기능 단위, 커밋했으면 SHA)
- **결정 (why)** — 고른 접근 + 버린 대안 + 이유. "재시도 말 것" 류 함정 포함
- **다음** — 남은 일, 막힌 점, open question. 날짜가 정해진 일은 날짜를 붙인다
- **상태** — git 또는 핵심 파일 스냅샷 (아래)

대화가 압축된 세션이면 압축 요약과 그 뒤 대화를 함께 본다. 이미 체크포인트 항목이 있으면 그것도 읽어 합친다.

## 2. 상태 스냅샷 (요약만 — 커밋 금지)

git repo 면:
```bash
git branch --show-current
git status --short
git diff --stat
git log @{u}.. --oneline 2>/dev/null   # 안 푸시된 커밋 (upstream 있으면)
```
요약을 devlog 항목의 `git:` 줄에 적는다. **절대 commit/add/push 하지 않는다** — 커밋은 사용자가 명시 요청할 때만.

git 이 아니면 (`fatal: not a git repository`): git 명령을 더 돌리지 않고 `files:` 줄에 핵심 산출물 상태를 적는다 —
CLAUDE.md 에 '핵심 파일' 목록이 있으면 그 파일들의 저장 시각·버전, 없으면 이번 세션에 만든·바꾼 주요 파일과 직전 백업 이름.

## 3. `devlog.md`에 세션 항목 prepend

`$DIR/devlog.md` 없으면 헤더로 생성. 새 항목을 **맨 위**(헤더 바로 아래)에 끼운다 — 역순(최신 먼저):

```markdown
# Dev Log — <프로젝트명>

<!-- 최신 세션이 위. /dev-start는 맨 위 항목을 읽음. -->

## YYYY-MM-DD · <세션 한 줄 제목>
**한 일**
- ...
**결정 (why)**
- 결정 — 이유 (버린 대안 / 함정)
**다음**
- ...
**git**: `<branch>` · uncommitted N (요약) · unpushed M commits   (git 아니면 **files**: ...)
```

길이 상한: **한 일 5줄, 결정 3줄, 다음 3줄** (줄마다 2줄 넘기지 않기). 숫자는 결과 확인에 필요한 것만.
더 긴 내용은 해당 문서(CLAUDE.md, docs, topic 메모리)에 쓰고 항목에서는 가리킨다.
여러 날에 걸친 세션은 날짜별 항목으로 나눈다 (`YYYY-MM-DD ~ DD` 하나로 뭉치지 않기).
같은 날 여러 세션이면 별도 항목으로 (시간/주제로 구분).

## 4. `next_todos.md` 갱신

`$DIR/next_todos.md` 는 **열린 일만, 한 줄씩**:

```markdown
## 기한 있음 (가까운 날짜 순)
- [ ] due YYYY-MM-DD · <제목> — <한 줄> (세부: <위치>)
## 기한 없음
- [ ] <제목> — <한 줄> (세부: <위치>)
## 사용자 답 대기
- [ ] <질문> (YYYY-MM-DD 물음)
```

- 이번에 끝낸 항목은 지운다 (경위는 devlog 에). "닫힘" 목록을 todo 파일에 쌓지 않는다.
- 배경·순서·함정이 길면 CLAUDE.md 나 docs 에 두고 `(세부: …)` 로 가리킨다.
- 날짜가 정해진 일(복귀일, 만기일, 기준일 등)은 `due` 를 붙인다 — `/dev-start` 와 SessionStart 훅이 이걸로 오늘·지난 기한을 먼저 보여 준다. 날짜는 ISO (`2026-10-15`).
- 기존 frontmatter·`[[링크]]` 보존.

## 4b. 폴더 사이 할 일 (`~/.claude/desk/handoff.md`)

- 이번 세션에서 다른 폴더가 고쳐야 할 것을 찾았으면 파일 **끝에** 한 줄 덧붙인다:
  `- [ ] YYYY-MM-DD · <보낸 폴더> → <받는 폴더> · <할 일> (근거: <경로>)`. 폴더 이름은 지도(`~/.claude/desk/map.md`) 「폴더」 열 표기(`task/repo_fund`, `signals`, 허브는 `Desktop`).
- 이 폴더 앞으로 온 `[ ]` 줄을 next_todos 로 옮겼으면 그 줄을 지우지 않고 `[x]` 로 바꾼다.
- 허브(Desktop) dev-end 는 분기 첫 세션에 `[x]` 줄을 지운다.

## 5. durable fact만 별도 메모리로

세션에서 **재사용 가능한 비자명한 사실**(외부 시스템 사용법, 함정, 외부 리소스)이 나왔으면 쓰기 전에 위치부터 고른다 (위에서부터 처음 맞는 곳):
1. 사용자·모든 폴더의 일하는 방식 → `~/.claude/desk/user.md` (2KB 상한, 매 세션 실림)
2. 두 폴더 이상이 쓰는 사실 → `~/.claude/desk/` 주제 파일. 먼저 `grep -ril <주제어> ~/.claude/desk/*.md` 로 찾아 있으면 그 파일을 고친다. 없으면 새 주제 파일을 만들고 `~/.claude/desk/paths.md` 주제 파일 목록에 한 줄. 불러오는 파일에는 매 세션 행동을 바꾸는 것만, 찾아볼 때만 필요한 세부는 짝 파일 `<주제>-ref.md`
3. 이 폴더만 쓰는 사실 → `$DIR/`에 topic 파일 생성/갱신 + `MEMORY.md` 인덱스에 한 줄
다른 폴더 메모리에는 쓰지 않는다. 이 프로젝트에서만 쓰는 운영 규칙은 CLAUDE.md 쪽 (프로젝트가 쓰는 경우). 코드/깃 히스토리로 알 수 있는 건 적지 않는다. desk 파일을 고쳤으면 devlog 에 한 줄 남긴다.

## 6. repo `CLAUDE.md` 정리 (프로젝트가 쓰는 경우)

이번 세션에 CLAUDE.md 를 고쳤거나 파일이 20KB 를 넘으면 점검한다. 이 파일이 `@` 로 불러오는 desk 파일(상위 `task/CLAUDE.md` 가 불러오는 것 포함)도 합쳐 24KB 안인지 잰다. 산출물 모양·경로를 바꿨으면 지도의 해당 행과 `~/.claude/desk/paths.md` 를 같이 고친다 (데스크 규칙 6):
- 날짜별 경위, '(옛 기록)', 버전·백업 목록, 이미 바뀐 규칙의 옛 설명 → 프로젝트 문서 폴더의 결정 기록 파일(예: `docs/decisions.md`)로 **원문 그대로** 옮긴다. CLAUDE.md 에는 지금 유효한 구조·규칙·결론만 남기고 그 파일을 가리킨다.
- 옮기기 전에 사용자에게 범위를 말하고, 옮긴 뒤 문장 단위로 빠진 것이 없는지 대조한다 (원래 문장이 둘 중 한 파일에 있어야 한다).
- 다른 기록(devlog·todo·메모리)과 겹치는 문장은 한 곳만 남긴다.

## 7. 사용자에게 리캡

3~6줄로: 이번에 뭐 했는지 · 기록한 위치 · `/dev-start`로 복귀 가능하다는 안내. 커밋 안 한 변경 있으면 알린다.

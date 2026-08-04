---
name: dev-end
description: >
  Close out a coding session: record what was done, decisions (with why),
  open todos, and a git snapshot into the project's Claude memory dir — so a
  future session can catch up fast with /dev-start. Summarizes git state but
  NEVER commits. Trigger: /dev-end, "끝낼게", "오늘 작업 정리", "wrap up session",
  "log this session".
---

# dev-end — 세션 마무리 기록

코딩 세션을 닫으며 **무엇을 했고 / 왜 그렇게 정했고 / 다음에 뭘 할지**를
프로젝트별 Claude memory 디렉토리에 적는다. 다음에 `/dev-start`로 빠르게 복귀하기 위함.

## 0. 메모리 디렉토리 해석

**시스템 프롬프트에 memory 디렉토리 경로가 이미 주어져 있으면 그걸 쓴다.** 아래 계산은 없을 때의 폴백이다.

```bash
# Claude Code는 경로의 / . _ 공백을 전부 -로 바꿔 디렉토리 이름을 만든다.
# / 만 바꾸면 Note_Obsidian 같은 경로에서 엉뚱한 빈 디렉토리를 가리킨다.
# 한글은 현재 버전이 보존한다 (구버전은 글자마다 -로 뭉갰다 — 옛 디렉토리가 남아 있을 수 있다).
DIR="$HOME/.claude/projects/$(pwd | sed 's#[/._ ]#-#g')/memory"
ls "$DIR" 2>/dev/null
date +%F   # 세션 날짜 (절대값으로 기록)
```

**`$DIR`이 없는데 이 프로젝트에서 전에 작업한 적이 있으면 `mkdir` 하기 전에 멈춘다.**
이름 규칙이 바뀌어 기록이 다른 이름에 남아 있을 수 있다 (구버전은 한글을 글자마다
`-` 하나로 뭉갰다). 기록 있는 프로젝트만 뽑아서 눈으로 대조해라 — `-` 개수가
한글 글자 수와 맞고, 숫자·영문은 그대로 남아 앵커가 된다:

```bash
ls -d "$HOME"/.claude/projects/*/memory 2>/dev/null | sed 's#.*/projects/##; s#/memory##'
```

찾았으면 **거기에 append** 한다. 새로 만들면 `/dev-start`가 절반만 읽는다.
정말 처음이면 그때 `mkdir -p "$DIR"`.

이 `$DIR`이 이 프로젝트의 기록 저장소다. **repo 안에 아무것도 쓰지 않는다** (코드 트리 안 더럽힘, 비공개 유지).

## 1. 세션 내용 수집 (대화에서)

이번 세션 대화를 돌아보고 추린다:
- **한 일** — 끝낸 작업 (파일/기능 단위, 커밋했으면 SHA)
- **결정 (why)** — 고른 접근 + 버린 대안 + 이유. "재시도 말 것" 류 함정 포함
- **다음** — 남은 일, 막힌 점, open question
- **git 상태** — 커밋 안 한 작업 스냅샷 (아래)

## 2. git 스냅샷 (요약만 — 커밋 금지)

```bash
git branch --show-current
git status --short
git diff --stat
git log @{u}.. --oneline 2>/dev/null   # 안 푸시된 커밋 (upstream 있으면)
```

요약을 devlog 항목의 `git:` 줄에 적는다. **절대 commit/add/push 하지 않는다** — 커밋은 사용자가 명시 요청할 때만.

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
**git**: `<branch>` · uncommitted N (요약) · unpushed M commits
```

같은 날 여러 세션이면 별도 항목으로 (시간/주제로 구분). 항목은 **짧게** — 캐치업용 요약이지 일기가 아님.

## 4. `next_todos.md` 갱신

`$DIR/next_todos.md`의 열린 todo를 정리:
- 이번에 끝낸 항목 → 제거 (또는 devlog로 이전). open 항목만 남긴다
- 새로 생긴 todo / 백로그 추가
- 기존 frontmatter·`[[링크]]` 보존

## 5. durable fact만 별도 메모리로

세션에서 **재사용 가능한 비자명한 사실**(아키텍처 결정, 함정, 외부 리소스)이 나왔으면 — 시스템 메모리 규칙대로 `$DIR/`에 topic 파일 생성/갱신 + `MEMORY.md` 인덱스에 한 줄. 코드/깃 히스토리로 알 수 있는 건 적지 않는다.

## 6. 사용자에게 리캡

3~6줄로: 이번에 뭐 했는지 · 기록한 위치 · `/dev-start`로 복귀 가능하다는 안내. 커밋 안 한 변경 있으면 알린다.

---
name: dev-start
description: >
  Catch up at the start of a coding session. On the FIRST run in a project (no
  dev-log yet) it does a deep codebase-understanding pass and seeds the project
  memory; on later runs it reads the last session summary + open todos and gives
  a tight briefing, then proposes where to resume. Pairs with /dev-end.
  Trigger: /dev-start, "이어서 하자", "어디까지 했지", "catch me up", "resume work".
---

# dev-start — 세션 복귀 브리핑

두 모드. **최초 실행**(이 프로젝트 기록 없음) = 깊은 코드베이스 이해 + 메모리 시드.
**이후 실행** = 지난 세션 요약 + 열린 todo 빠른 캐치업.

## 0. 메모리 디렉토리 해석

**시스템 프롬프트에 memory 디렉토리 경로가 이미 주어져 있으면 그걸 쓴다.** 아래 계산은 없을 때의 폴백이다.

```bash
# Claude Code는 경로의 구분자(/ 또는 \)와 : . _ 공백을 전부 -로 바꿔 디렉토리 이름을 만든다.
# / 만 바꾸면 my_notes 처럼 _ 가 든 경로에서 엉뚱한 빈 디렉토리를 가리킨다.
# 한글은 현재 버전이 보존한다 (구버전은 글자마다 -로 뭉갰다 — 옛 디렉토리가 남아 있을 수 있다).
DIR="$HOME/.claude/projects/$(pwd | sed 's#[/\\:._ ]#-#g')/memory"
ls "$DIR" 2>/dev/null
```

`mkdir` 는 여기서 하지 않는다. 경로가 틀린 채로 만들면 빈 디렉토리가 생기고
아래 모드 판별이 FIRST-RUN으로 잘못 빠진다.

**Windows 주의.** Git Bash 의 `pwd` 는 `/c/Users/...` 를 주지만 Claude Code 는
`C--Users-...` 처럼 드라이브 문자 기준으로 이름을 만든다. 위 계산이 빗나가므로
Windows 에서는 아래 폴백 스캔이 사실상 기본 경로다.

### `$DIR`이 없으면 — 고아 메모리부터 찾는다

Claude Code 버전에 따라 디렉토리 이름 규칙이 달라졌다. **구버전은 한글을 글자마다
`-` 하나로 뭉갰다.** `~/사내교육/03_최종프로젝트` 가 `-Users-<user>------03--------`
로 남아 있는 식이다. 이름만 보면 원본을 못 알아본다.

기록이 있는 프로젝트만 뽑아서 눈으로 찾는다 — 목록이 짧아 정규식보다 빠르고 정확하다:

```bash
ls -d "$HOME"/.claude/projects/*/memory 2>/dev/null | sed 's#.*/projects/##; s#/memory##'
```

대조 요령: **`-` 개수가 한글 글자 수와 맞는다.** `사내교육`(4자) → `----`,
`최종프로젝트`(6자) → `------`. 숫자와 영문은 그대로 남으므로 그걸 앵커로 잡아라.

### 고아를 찾았을 때

**사용자에게 확인부터 받는다. 말없이 옮기지 않는다.** 승인하면 복사한다:

```bash
cp -R "$OLD/memory" "$DIR"     # 원본은 남긴다. mv 하지 않는다
```

`mv`나 삭제는 하지 않는다. 옛 디렉토리에는 세션 트랜스크립트도 같이 들어 있고,
잘못 짚었을 때 되돌릴 방법이 없어진다. 아카이브로 끝난 프로젝트면 **그냥 두는 게 맞다.**

## 1. 모드 판별

- `$DIR/devlog.md` 존재 + 내용 있음 → **CATCH-UP 모드** (§3)
- 없음 / 비어있음 → **FIRST-RUN 모드** (§2)

> **FIRST-RUN으로 판단하기 전에 위의 고아 탐색을 반드시 돌린다.** 코드베이스에
> 커밋이 여러 개 쌓여 있는데 기록이 없다면 십중팔구 이름 규칙이 바뀐 것이다.
> 잘못 짚으면 전체 재분석에 시간을 태우고 메모리가 두 곳으로 갈린다.
> FIRST-RUN이 맞다고 확인된 뒤에 `mkdir -p "$DIR"` 한다.

---

## 2. FIRST-RUN — 깊은 코드베이스 이해

기록이 없으면 따라잡을 과거가 없다 → 대신 **코드베이스 자체를 깊이 이해**하고 그 이해를 메모리로 남긴다.
이후 세션부터 이 지도 위에서 빠르게 작업. 목표: *"모든 조각이 어떻게 맞물리는지 조용히 가르치는 지도"*
(방법론 출처: github.com/Egonex-AI/Understand-Anything — 구조 사실 먼저, 의미 요약 나중).

이 패스는 **깊게** 한다. 큰 repo면 서브에이전트(Explore/general-purpose)를 **병렬 fan-out** 해서 영역별로 읽고 합친다.

### 단계 (구조 → 의미 순)

**A. Discovery (스택·진입점)** — 매니페스트부터. 결정론적 고신호 먼저:
- `git ls-files | head -200`, 디렉토리 트리, 파일 수/언어 분포
- 매니페스트/설정: package.json·pyproject·go.mod·Cargo.toml·*.config.* — 의존성, 스크립트(build/test/dev/deploy), 프레임워크
- 진입점: main/index/app, 라우트, CLI, 서버 부트

**B. 구조 지도 (디렉토리 → 책임)** — 각 top-level 디렉토리가 *무엇을* 담는지. 핵심 모듈, 데이터 흐름(입력→처리→저장→출력), 모듈 간 의존 방향. 큰 repo는 영역마다 서브에이전트 1개씩 병렬로 돌려 파일 인용(`path:line`)과 함께 요약 받기.

**C. 아키텍처 레이어** — 코드를 레이어로 분류 + 연결: UI / 상태·도메인 / 데이터·영속 / 서비스·외부연동 / 빌드·배포 / 유틸. "무엇이 무엇을 호출하나".

**D. 의존성순 학습 투어** — 가장 가치 있는 산출물. **"여기부터 읽어라 → 다음 → 다음"** 순서로, 의존성 낮은 핵심부터 위로. 새 사람(또는 미래의 나)이 이 순서로 따라가면 코드베이스를 이해하게 되는 경로 5~10스텝.

**E. 검증 (QA)** — 빠진 핵심 모듈 없나, 주장이 코드와 맞나 빠르게 점검. 불확실/위험/사용자에게 물어야 할 것 = open question으로 모음.

**F. 메모리 시드** — 위 이해를 `$DIR/`에 마크다운으로 남긴다 (repo 안 X):
- `project_overview.md` — 스택·실행법·디렉토리 책임 (이미 있으면 갱신·보강)
- `architecture.md` — 레이어 지도 + 데이터 흐름 + **학습 투어** + open questions
- `MEMORY.md` — 위 파일들 인덱스 한 줄씩
- `next_todos.md` — 비었으면 초기 todo/관찰 시드 (없으면 생략)
- `devlog.md` — 첫 항목 생성: "초기 이해 패스 — 무엇을 파악했나 / 다음" (역순 헤더 포함, `/dev-end` 포맷)

durable·비자명한 것만. 코드/깃으로 자명한 건 적지 않는다.

### FIRST-RUN 출력
사용자에게: 스택 1~2줄 · 아키텍처 핵심 · **학습 투어 순서** · open question 2~3개 · "이제 메모리에 지도 깔았으니 다음부터 `/dev-start`는 빠르게 캐치업" 안내. 그리고 §4 재개 제안.

---

## 3. CATCH-UP — 빠른 복귀 (기록 있을 때)

읽기:
- `$DIR/devlog.md` **맨 위(최신) 항목** — 지난 세션 한 일/결정/다음
- `$DIR/next_todos.md` — 열린 todo / 미완성 / 백로그
- `$DIR/MEMORY.md`는 세션 시작 시 이미 컨텍스트 로드됨 — 배경으로 활용

가벼운 현재 위치:
```bash
git branch --show-current
```

출력 (범위 = 지난 세션 요약 + 열린 todo):
```
📍 <프로젝트> · `<branch>`

지난 세션 (<날짜>):
- <한 일 핵심 2~4줄>
- 결정: <중요하면>

열린 할 일:
- [ ] <todo>
- [ ] <todo>

▶ 제안: <어디서 이어갈지 1~2줄>
```

---

## 4. 재개 제안 (공통)

열린 todo·지난 "다음"·(first-run이면)open question 근거로 **이번 세션 뭐부터** 1~2개 제안. 사용자 확정 전 작업 시작하지 않는다.

## 규칙
- CATCH-UP은 읽기 전용·기록에 있는 것만(창작 X). 비면 비었다고 한다.
- FIRST-RUN은 메모리에 **쓴다**(§2-F). 단 repo 파일은 안 만진다.
- git 커밋 로그·빌드 상태는 캐치업에선 깊이 안 판다(사용자가 범위를 요약+todo로 한정). FIRST-RUN 이해 패스는 예외 — 깊게.

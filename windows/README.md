# windows/

윈도우 11 PC에서 쓰는 Claude Code 설정을 그대로 떠 온 것이다(2026-11-12, Claude Code 2.1.322). 저장소 루트는 맥 판이고 `install.sh`는 이 폴더를 건드리지 않는다.

## 맥을 이 세팅으로 맞추기

맥의 Claude Code 세션에 이 한 줄:

```
claude-config 클론에서 git pull 하고 windows/setup-agent.md 의 M 부분대로 해줘.
```

새 스킬 셋(`dewrite`, `socratic-tutor`, `writing-for-agents`), 고친 `dev-start`·`dev-end`, 세션 훅, statusline, 설정 키를 맥에 넣는다. 알림 훅과 맥 전용 설정은 그대로 둔다.

## 새 윈도우 PC에 올리기

Claude Code 첫 세션에 이 한 줄:

```
https://github.com/jaefit/claude-config 를 받아서 windows/setup-agent.md 의 B 부분대로 해줘.
```

사람이 읽을 설명은 `setup.md`에 있다(깔 것, 설정 값의 뜻, PowerShell 프로필의 `cc`·`ccs`·`ccl`, Windows Terminal).

## 담긴 것

```
setup.md          사람용 정리
setup-agent.md    에이전트용 런북 (A 올리기, B 새 윈도우 PC, M 맥 갱신)
export.sh         이 폴더를 다시 만드는 스크립트. 올릴 파일 목록이 여기 있다
claude/           ~/.claude 에 넣을 것: CLAUDE.md, settings, statusline, 훅 2, 스킬 5
pwsh/             PowerShell 프로필 (claude 래퍼, cc 블록)
wt/               Windows Terminal Fragments (탭 색, 스킴)
```

`agents/`, `skills/proofread`, `skills/review-paper`는 루트 것과 같아서 여기에 다시 넣지 않았다.

## 담지 않은 것

`~/.claude/desk/`의 업무 파일, 폴더별 메모리, 대화 기록, 계정 쪽 값(`remote`, `model` 키)은 PC에만 둔다. 프로필과 Fragments에 든 폴더 이름과 경로는 원래 PC 것이니 새 PC에 맞게 고친다(런북 B7, B8).

## 갱신

원래 PC의 Git Bash에서 `sh windows/export.sh`를 돌리고 `git diff`를 읽은 뒤 커밋한다. 스크립트는 키처럼 생긴 문자열이나 메일 주소가 보이면 멈춘다.

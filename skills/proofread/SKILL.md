---
name: proofread
description: 한국어 학술 문서 정독 검토 (학부논문·학회지·연구계획서). 문법·오탈자·등급 표현 일관성·인용 형식·외래어 표기·산문 흐름 검토 후 보고서 산출 (파일 수정 X). Use when user says "정독", "교정", "오탈자 찾아", "톤 검토", "proofread".
argument-hint: "[파일명 또는 'all']"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Agent"]
---

# Proofread (한국어 학술 문서 정독)

지정된 파일에 대해 proofreader agent를 실행하여 모든 issue를 상세 보고. **수정은 별도 단계에서 사용자 확인 후 적용**.

## Steps

1. **검토 대상 식별:**
   - `$ARGUMENTS`가 특정 파일명이면 그 파일만
   - `$ARGUMENTS`가 'all'이면 본문 draft + 부록 .md 일체 (프로젝트 구조는 해당 repo의 `CLAUDE.md` 참조)
   - 인자 없으면 사용자에게 어느 파일인지 질문

2. **proofreader agent 실행 (Agent tool):**
   - subagent_type: 사용자 정의 `proofreader` (없으면 general-purpose)
   - 8 카테고리 검토 (문법, 오탈자, 등급 표현, 인용 형식, 외래어 표기, 산문 흐름, 통계 표기, 학술 톤)

3. **보고서 저장:**
   - `quality_reports/<파일명>_proofread_<YYYY-MM-DD>.md`
   - 디렉토리 없으면 생성

4. **사용자에게 요약 제시:**
   - 카테고리별 issue 수
   - Critical issue top 3
   - 수정 우선순위 (회신 전 vs 후)

5. **중요: 파일 직접 수정 X.** 보고서만 작성. 사용자 확인 후 별도 단계에서 fix.

## Tips

프로젝트별 컨텍스트(문서 종류·제출 일정·등급 표현 기준·기존 정정 이력)는 **해당 프로젝트의
`CLAUDE.md` 또는 검토 로그**에서 읽는다. 이 스킬에 하드코딩하지 않는다 — 전역 스킬이라
다른 프로젝트에서도 로드되고, 프로젝트가 바뀌면 그대로 stale 해진다.

세션 시작 시 확인할 것:
- 등급 표현(G1 사다리)의 권위 기준 파일이 프로젝트에 있는지 (`CRITICAL_REVIEW_LOG.md` 등)
- 이전 검토에서 정정된 인용이 있는지 → 재발 여부 확인

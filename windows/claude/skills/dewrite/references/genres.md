# Genre profiles

Pick one per document. Auto-estimate from the first 200 chars and the shape (see SKILL.md step 2); `--genre` overrides.

| genre | typical input | normal here (do not flag) | stricter here |
|---|---|---|---|
| **memo** | 메일, 슬랙 긴 메시지, 짧은 공지 | 인사말·맺음말, 짧은 문단, 불릿 2~3개 | 결산 라벨(KO-D1), hype(KO-D4/EN-16), 볼드 |
| **report** | 시장·규제·손익 정리, 팀 보고, 회의록 | 표, 불릿, 헤딩, 굵은 수치 하나, 조사 생략 헤더, "확인 필요" 목록, 미확인 표기 | 대시 남용, 의의 과장, 분열문("핵심은 ~이다"), "~하는 이유다", 모든 문단이 요약문으로 시작 |
| **paper** | 논문·연구계획서·학회지 초안 | 피동, 접속사("따라서·그러나"), "~적", 괄호 영어 병기, 완곡 한 단계, 관계절 수식, 반론 다루기 | 대구 반복, 삼항 강박, 결산 공식 |
| **chat** | 슬랙 짧은 답, 댓글, 카톡 | 구어, 파편문, 이모지 1~2개 | 헤딩·불릿·볼드 전부, 결산 라벨, 안내문 |
| **note** | 옵시디언 개인 노트, 학습 메모 | 파편문, 반복 주어, 이전 버전 언급, 불릿 | 이모지, 대시, "결론적으로" |

Rules:
- A genre moves severity by at most one step, or turns a pattern off. It never adds a pattern.
- `report` is the default for anything with 2+ tables or 3+ headings.
- Mixed genres (memo wrapping a report): take the inner one.

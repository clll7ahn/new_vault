---
title: "Docs 폴더 운영 규칙"
doc_type: "policy"
created: "2025-10-13"
updated: "2025-10-13"
owner: "Kein"
summary: "0. Docs 폴더의 문서 작성 및 관리 규칙"
scope: "0. Docs 폴더 내 모든 문서"
audience: "본인(kamwoo)"
keywords: ["documentation", "frontmatter", "changelog", "flat-structure"]
related: ["CLAUDE.md"]
status: "active"
---

# 0. Docs 폴더 운영 규칙

## 개요

`0. Docs` 폴더는 **운영 규칙, 정책, 프로세스 문서**를 보관합니다.

### 핵심 원칙

1. **평면 구조**: 하위 폴더 없이 모든 문서를 한 곳에
2. **메타데이터 분류**: Frontmatter의 `doc_type`, `keywords`로 분류
3. **마이크로 Changelog**: 문서 하단에 변경 이력 간단히 기록

---

## Frontmatter 규칙

### 템플릿

```yaml
---
# 필수 (4개)
title: "<문서 제목>"
doc_type: "policy|procedure|howto|reference|decision"
updated: "YYYY-MM-DD"
owner: "kamwoo"

# 권장 (5개) - 문맥 확보용
summary: "<1-2문장 요약>"
scope: "<적용 범위>"
audience: "본인|팀|전사"
keywords: ["<검색어1>", "<검색어2>"]
related: ["<연관 문서>"]

# 선택 (필요시에만)
status: "active|deprecated"
version: "1.0.0"
notes: "<짧은 주석>"
---
```

### doc_type 설명

- `policy`: 원칙, 가이드라인
- `procedure`: 절차, 프로세스
- `howto`: 실행 가이드, 튜토리얼
- `reference`: 참고 자료, 용어집
- `decision`: 의사결정 기록 (ADR)

### 작성 팁

- **title/summary/scope**만 잘 써도 문맥 80% 확보
- **version**은 파괴적 변화(구조/절차 변경)에만 사용
- **status**는 `active/deprecated`만 사용 (검토/승인 흐름 없음)

### `updated` 갱신 규칙 ⭐

**✅ `updated` 갱신 대상**:
- 본문 내용 수정 (절차 변경, 정책 보강)
- 새로운 섹션 추가
- 예시 추가/변경
- Changelog 항목 추가 (단, Changelog 추가와 동시에 본문도 변경된 경우)

**❌ `updated` 갱신 금지** (내용 변화 아님):
- 오타/맞춤법 수정만
- 키워드(`keywords`) 추가만
- 포맷팅 변경 (줄바꿈, 들여쓰기)
- Changelog 항목만 추가 (본문 변경 없이)

**규칙**: *실질적 내용 변화가 있을 때만* `updated` 갱신

---

## Changelog 규칙

문서 하단에 **최대 5개 항목**만 유지:

```markdown
## Changelog
- YYYY-MM-DD: 무엇을 변경 + 왜 (1줄)
- YYYY-MM-DD: 다음 변경 사항 (1줄)
```

**규칙**:
- 무엇을 + 왜를 1줄로 요약
- 오래된 항목은 삭제
- 월간 집계 불필요 (개인 vault)

---

## 작성 예시

```markdown
---
title: "Git Commit 컨벤션"
doc_type: "procedure"
created: "2025-10-13"
updated: "2025-10-13"
owner: "kamwoo"
summary: "커밋 메시지 작성 규칙"
scope: "모든 프로젝트"
audience: "본인"
keywords: ["git", "commit", "convention"]
status: "active"
---

# Git Commit 컨벤션

## 형식
```
type(scope): subject
```

## type 종류
- feat: 새 기능
- fix: 버그 수정
- docs: 문서 수정
- refactor: 리팩토링

## Changelog
- 2025-10-13: 초기 작성 (Conventional Commits 기반)
```

---

## Dataview 활용

### 문서 타입별 보기
```dataview
TABLE doc_type, summary, updated
FROM "0. Docs"
SORT doc_type ASC, updated DESC
```

### 최근 업데이트된 문서
```dataview
TABLE doc_type, updated
FROM "0. Docs"
SORT updated DESC
LIMIT 10
```

### 키워드 검색
```dataview
LIST
FROM "0. Docs"
WHERE contains(keywords, "검색어")
```

---

## Changelog
- 2025-10-13: 초기 버전 - 간결하게 재작성 (불필요한 섹션 제거)

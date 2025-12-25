---
type: doc
status: approved
tags: [policy, zettelkasten]
---

# 5. Zettelkasten 폴더 운영 지침 (CLAUDE.md)

## 문서 목적
- ✅ Claude Code(저)를 위한 컨텍스트 제공
- ✅ `5. Zettelkasten/` 폴더의 목적·구조·규칙을 빠르게 이해
- ✅ 작업 시 자동 참조되어 맥락 파악 가속

---

## 폴더 역할 (지식 발전소)
- **Zettelkasten = 시간 독립적 영구 지식 저장소**
- 원칙: **One Idea per Note · 최소 2개 연결 · Literature → Permanent 흐름 · Archive 이동 금지**
- 목적: PARA의 작업 실행과 분리된 순수 지식 발전

---

## 하위 구조

### 00. Inbox/
- **역할**: 빠른 메모 수집함
- **정리**: 주 1회 (Literature 또는 Permanent로 승격)
- **특징**: 완벽하지 않아도 OK, 연결 없어도 OK

### 10. Literature/
- **역할**: 문헌 노트 (저자의 생각)
- **내용**: 책/글/영상에서 얻은 원천 자료를 객관적으로 요약
- **특징**: 저자의 주장을 내 언어로 번역 (해석 금지)

### 20. Permanent/
- **역할**: 영구 노트 (내 통찰)
- **내용**: Literature를 바탕으로 내가 재해석한 아이디어
- **특징**: 하나의 명확한 주장, 최소 2개 이상 다른 노트와 연결

---

## 핵심 원칙

### 1. One Idea per Note
- 하나의 노트에 하나의 아이디어만
- 제목은 명확한 주장 또는 개념
- 예: "원자적 사고의 힘", "연결이 만드는 통찰"

### 2. 최소 2개 이상 연결 (고아 노트 방지)
- 모든 Permanent 노트는 최소 2개 이상의 다른 노트와 연결
- `related[]` 필드에 명시
- 본문에도 `[[링크]]`로 연결

### 3. Literature → Permanent 흐름
```
읽기 → 00. Inbox (빠른 메모)
     → 10. Literature (원천 정리)
     → 20. Permanent (내 생각으로 재구성)
```

### 4. Archive 이동 금지
- Zettelkasten 노트는 **영구 보관**
- 완료 개념 없음 (계속 진화)
- 삭제 금지, 수정만 가능

---

## 프론트매터 규칙 (ZK 전용)

### Literature 노트

```yaml
type: literature
status: active
created: 2025-10-14      # 허용 (지식 진화 추적)
updated: 2025-10-14      # 허용 (지식 진화 추적)
source: ""               # 출처 URL/서지
author: ""               # 저자/출처 주체
# tags: [literature]
```

**필수 필드**:
- `type: literature` - 고정
- `status: active` - 고정
- `created`, `updated` - Templater 자동 입력
- `source` - 출처 명시
- `author` - 저자 명시

**금지 필드**:
- ❌ `related` - Literature는 관계 정의 안 함

### Permanent 노트

```yaml
type: permanent
status: active
created: 2025-10-14      # 허용 (지식 진화 추적)
updated: 2025-10-14      # 허용 (지식 진화 추적)
tags: []
related: []              # 최소 2개 이상 권장
```

**필수 필드**:
- `type: permanent` - 고정
- `status: active` - 고정
- `created`, `updated` - Templater 자동 입력
- `related` - **최소 2개 이상** 노트 링크

**금지 필드**:
- ❌ `due` - 완료 개념 없음
- ❌ `source`, `author` - Permanent는 본문에 출처 표기

### `updated` 갱신 규칙 ⭐

**ZK 노트는 지식 진화를 추적하므로 `updated` 갱신이 중요합니다.**

**✅ `updated` 갱신 대상**:
- 본문 내용 수정 (아이디어 발전, 생각 정제)
- 새로운 섹션 추가
- 인사이트 보강
- 연결(`related`) 추가/변경
- 출처(`source`) 보강

**❌ `updated` 갱신 금지** (지식 진화 아님):
- 오타/맞춤법 수정만
- 태그만 추가/삭제
- 포맷팅 변경 (줄바꿈, 들여쓰기)
- Obsidian 링크 문법 수정

**규칙**: *내용적 변화가 있을 때만* `updated` 갱신

---

## PARA vs ZK 프론트매터 비교표

| 필드 | PARA (P/A/R/Ar) | ZK Literature | ZK Permanent |
|------|-----------------|---------------|--------------|
| `type` | ✅ | ✅ | ✅ |
| `status` | ✅ | ✅ | ✅ |
| `created` | ❌ OS 메타 | ✅ 진화 추적 | ✅ 진화 추적 |
| `updated` | ❌ OS 메타 | ✅ 진화 추적 | ✅ 진화 추적 |
| `due` | ✅ Projects만 | ❌ | ❌ |
| `source` | ❌ | ✅ | ❌ |
| `author` | ❌ | ✅ | ❌ |
| `related` | ❌ 본문 링크 | ❌ | ✅ 최소 2개 |
| `tags` | ✅ 선택 | ✅ 선택 | ✅ 선택 |

### 핵심 차이점

**PARA**: 시간 제약적 실행 → OS 메타 활용 (관리 비용 0)
**ZK**: 시간 독립적 지식 → 명시적 필드 (진화 과정 추적)

---

## ZK → PARA 이동 원칙 (복제본만) ⭐

### 원칙
- **ZK 원본은 절대 이동 금지** (영구 보관)
- PARA에서 활용 필요 시 **복제본만 생성**
- 복제본은 PARA 규칙 따름 (`created`/`updated`/`related` 제거)

### 시나리오 예시

#### 상황 1: Literature 노트를 Resource로 활용
```
1. 5. Zettelkasten/10. Literature/책제목.md (원본 유지)
2. 복제 → 3. Resources/프로그래밍/책제목.md
3. Frontmatter 수정:
   - type: resource
   - created/updated 삭제
   - category 추가
```

#### 상황 2: Permanent 노트를 프로젝트 문서로 활용
```
1. 5. Zettelkasten/20. Permanent/개념.md (원본 유지)
2. 복제 → 1. Projects/프로젝트명/개념-적용.md
3. Frontmatter 수정:
   - type: project (또는 문서 타입)
   - created/updated/related 삭제
   - due 추가 (필요 시)
```

### 금지 사항
- ❌ ZK 노트를 PARA로 이동 (잘라내기)
- ❌ ZK 노트에 PARA 규칙 적용 (`due` 추가 등)
- ❌ ZK 노트를 Archive로 이동

---

## Claude 작업 지침

* **템플릿 사용**: `6. Templates/literature.md`, `6. Templates/permanent.md`
* **One Idea per Note**: Permanent 노트는 하나의 명확한 주장만
* **최소 2개 연결**: Permanent 노트 생성 시 `related[]` 필드에 최소 2개 링크
* **Literature → Permanent**: Inbox 또는 Literature에서 시작, Permanent로 승격
* **Archive 금지**: Zettelkasten 노트는 절대 Archive 이동 안 함
* **복제본 원칙**: PARA 활용 시 복제본만, 원본은 ZK 유지

---

## 관련 폴더 연계

### 1. Projects/ & 2. Areas/ & 3. Resources/
- **참조 방향**: PARA → ZK (일방향)
- **방법**: 본문에 `[[5. Zettelkasten/노트명]]` 링크
- **복제본**: 필요 시 ZK에서 복제 → PARA로 이동

### 4. Archive/
- **ZK → Archive 이동 금지**
- ZK는 영구 보관 전용
- 삭제 필요 없음 (계속 진화)

---

## Dataview 활용 예시

### Inbox 정리 대상 (7일 이상)

```dataview
TABLE file.ctime as "생성일"
FROM "5. Zettelkasten/00. Inbox"
WHERE file.ctime < date(today) - dur(7 days)
SORT file.ctime ASC
```

### 고아 노트 (연결 < 2)

```dataview
LIST
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent" AND length(related) < 2
```

### Literature → Permanent 후보 (14일 이상)

```dataview
TABLE file.ctime as "생성일", source, author
FROM "5. Zettelkasten/10. Literature"
WHERE type = "literature"
  AND file.ctime < date(today) - dur(14 days)
SORT file.ctime ASC
```

### 최신 Permanent (10개)

```dataview
TABLE file.ctime as "생성일", length(related) as "연결 수"
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent"
SORT file.ctime DESC
LIMIT 10
```

### 저자별 Literature

```dataview
TABLE author, count(rows) as "노트 수"
FROM "5. Zettelkasten/10. Literature"
WHERE type = "literature"
GROUP BY author
SORT count(rows) DESC
```

### 연결이 많은 Permanent (허브 노트)

```dataview
TABLE length(related) as "연결 수", tags
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent"
SORT length(related) DESC
LIMIT 20
```

### 최근 업데이트된 Permanent (활발히 진화 중)

```dataview
TABLE updated, length(related) as "연결 수"
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent"
SORT updated DESC
LIMIT 10
```

### 지식 진화 추적 (최초-최신 간격) ⭐

```dataview
TABLE
  created as "생성",
  updated as "최종 갱신",
  round((date(updated) - date(created)).days, 0) + "일" as "진화 기간"
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent"
SORT (date(updated) - date(created)).days DESC
LIMIT 20
```

**효과**: 어떤 Permanent 노트가 오랫동안 발전했는지 확인 (지식 진화 가시화)

### 장기 미갱신 노트 (휴면 상태) ⭐

```dataview
TABLE
  updated as "최종 갱신",
  round((date(today) - date(updated)).days, 0) + "일 전" as "경과"
FROM "5. Zettelkasten/20. Permanent"
WHERE type = "permanent"
  AND date(updated) < date(today) - dur(90 days)
SORT updated ASC
LIMIT 20
```

**효과**: 90일 이상 미갱신 노트 발견 → 재검토 기회

---

## 태그 사용 원칙

* **필요할 때만**: 실제 Dataview 쿼리·검색에 쓰일 때만 태깅
* **최대 3개**: 한 노트당 태그 0–3개
* **주제 중심**: `#thinking`, `#knowledge-work`, `#atomicity` 형식

### Zettelkasten 폴더 — 허용 태그 집합

* Literature: `#literature`, `#book`, `#article`, `#video`
* Permanent: `#concept`, `#principle`, `#method`, `#observation`
* 주제별: `#productivity`, `#learning`, `#writing`, `#programming`

**금지**: `#permanent/active`, `#status/*` (Frontmatter와 중복)

---

## 베스트 프랙티스

### 1. Inbox 주간 정리
- 매주 일요일 Inbox 비우기
- 7일 이상 된 메모 → Literature 또는 Permanent로 승격
- 가치 없는 메모는 삭제

### 2. Literature는 객관적으로
- 저자의 주장을 있는 그대로 정리
- 내 의견은 Permanent로 분리
- 인용 필수 (출처 추적)

### 3. Permanent는 명확하게
- 제목이 주장을 담아야 함
- 예: "원자적 사고의 힘" (O), "생산성" (X)
- 하나의 아이디어만 (One Idea per Note)

### 4. 연결 먼저, 완성은 나중에
- 완벽한 노트보다 연결된 노트가 더 가치 있음
- 초안 상태로 두고 연결부터 만들기
- 시간이 지나면서 자연스럽게 정제

### 5. 주기적 연결 강화
- 월 1회: 고아 노트 찾아 연결 추가
- 분기 1회: 허브 노트 (연결 많은 노트) 확인
- 그래프 뷰로 연결 패턴 시각화

### 6. 태그보다 링크
- 태그는 보조 수단
- 주된 연결은 `[[링크]]`와 `related[]` 필드
- 태그는 주제 분류 정도만

---

## Literature vs Permanent 구분

| 항목 | Literature | Permanent |
|------|------------|-----------|
| **목적** | 원천 보존 | 통찰 생성 |
| **내용** | 저자의 생각 | 내 생각 |
| **어조** | 객관적 요약 | 주장/해석 |
| **연결** | 최소 (관련 P만) | 최소 2개 이상 |
| **인용** | 필수 | 선택 |
| **완성도** | 읽은 즉시 작성 | 시간 두고 정제 |

---

## Zettelkasten 워크플로우

### 단계 1: 수집 (Inbox)
```
읽기/시청 → 00. Inbox에 빠른 메모
- 완벽하지 않아도 OK
- 핵심만 캡처
```

### 단계 2: 정리 (Literature)
```
주 1회 Inbox 정리
→ 10. Literature에 객관적 요약 작성
- 저자의 주장 정리
- 출처/저자 명시
- 인용 포함
```

### 단계 3: 통찰 (Permanent)
```
Literature 읽고 내 생각 정리
→ 20. Permanent에 통찰 작성
- 내 언어로 재구성
- 최소 2개 노트와 연결
- 하나의 아이디어만
```

### 단계 4: 진화
```
시간이 지나면서 Permanent 노트 업데이트
- 새로운 연결 발견
- 생각 정제
- 발전 방향 추가
```

---

## 금지/주의(안티패턴)

* ZK 노트를 Archive로 이동 (영구 보관 전용)
* Permanent에 여러 아이디어 혼합 (One Idea 위반)
* Literature에 내 의견 포함 (객관성 상실)
* 연결 없는 Permanent (고아 노트)
* ZK 노트를 PARA로 이동 (복제본 원칙 위반)
* `created`/`updated`/`related` 필드 삭제 (ZK는 허용)
* 완벽주의 (초안 상태로 시작, 점진적 정제)

---

## 유지보수 체크리스트(주/월 1회)

### 주간 (매주 일요일)
* [ ] Inbox 비우기 (7일 이상 메모 정리)
* [ ] Literature 노트 최소 1개 작성
* [ ] Permanent 노트 최소 1개 작성

### 월간 (매월 첫 주)
* [ ] 고아 노트 (연결 < 2) 찾아 연결 추가
* [ ] Literature → Permanent 후보 확인 (14일+ 경과)
* [ ] 허브 노트 (연결 많은 노트) 검토
* [ ] 그래프 뷰로 연결 패턴 확인

### 분기 (3개월마다)
* [ ] 전체 Permanent 노트 리뷰
* [ ] 태그 정리 (미사용/중복 태그 제거)
* [ ] 연결 강화 (새로운 관계 발견)
* [ ] 시스템 회고 (개선 사항 도출)

---

## Hub 파일

`00_ZK_Hub.md` 사용법: [[0. Docs/Hub-운영-가이드]]

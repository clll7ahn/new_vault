# 빠른 시작 가이드

5분 안에 Docker 환경을 설정하고 초기 데이터를 생성하세요.

## 전제 조건

```bash
docker --version      # Docker 20.10 이상
docker-compose --version  # Docker Compose 1.29 이상
npm --version         # Node.js 패키지 관리자
```

## 1단계: 시작 (2분)

### 1.1 컨테이너 시작
```bash
cd /home/user/new_vault/1.\ Projects/병원-앱/code/backend

npm run docker:up
```

**무엇이 실행됨:**
- NestJS API (포트 3000)
- PostgreSQL 데이터베이스 (포트 5432)
- Redis 캐시 (포트 6379)

### 1.2 컨테이너 준비 확인 (30초 대기)
```bash
sleep 30

npm run docker:logs    # 로그 확인
```

**정상 신호:**
```
api        | [Nest] X  - 04/14/2025, 11:00:00 AM     LOG [NestFactory] Starting Nest application...
postgres   | database system is ready to accept connections
redis      | Ready to accept connections
```

## 2단계: 초기 데이터 생성 (2분)

### 2.1 Seed 데이터 생성
```bash
npm run docker:seed
```

**출력 예시:**
```
✓ Database connection established
[1/7] Creating hospital...
✓ Hospital created: 예시내과의원
[2/7] Creating departments...
✓ Departments created: 내과, 피부과, 정형외과
[3/7] Creating admin user...
✓ Admin user created: admin@hospital.com
[4/7] Creating doctors...
✓ Doctors created: 김내과, 이피부, 박정형
[5/7] Creating patient users...
✓ Patient users created: 환자1, 환자2
[6/7] Creating schedule slots...
✓ Schedule slots created: 480 slots
[7/7] Creating sample appointments...
✓ Sample appointments created: 5 appointments

✓ SEED DATA COMPLETED SUCCESSFULLY
```

## 3단계: 확인 (1분)

### 3.1 API 헬스 체크
```bash
curl http://localhost:3000
```

**예상 응답:** `{"message":"Welcome to Hospital App"}`

### 3.2 테스트 계정 확인
| 역할 | 이메일 | 비밀번호 |
|------|--------|---------|
| 관리자 | admin@hospital.com | admin123 |
| 의사 (내과) | doctor1@hospital.com | doctor123 |
| 의사 (피부과) | doctor2@hospital.com | doctor123 |
| 의사 (정형외과) | doctor3@hospital.com | doctor123 |
| 환자 | patient1@test.com | patient123 |
| 환자 | patient2@test.com | patient123 |

## 4단계: 개발 시작 (선택사항)

### 4.1 핫 리로드로 로컬 개발
```bash
# 터미널 1: DB와 Redis는 Docker에서 실행
docker-compose up -d postgres redis

# 터미널 2: 로컬에서 앱 실행 (핫 리로드)
npm run start:dev
```

### 4.2 코드 수정 후 마이그레이션 생성
```bash
# 엔티티 수정 후
npm run migration:generate -- --name=YourMigrationName

# 마이그레이션 실행
npm run migration:run
```

## 자주 사용하는 명령어

### 컨테이너 관리
```bash
npm run docker:up           # 시작
npm run docker:down         # 중지
npm run docker:logs         # 로그 확인
docker-compose ps           # 상태 확인
```

### 데이터 관리
```bash
npm run docker:seed         # Seed 데이터 재생성 (주의: 기존 데이터 삭제)
npm run migration:run       # 마이그레이션 실행
npm run migration:generate -- --name=YourName  # 새 마이그레이션 생성
```

### 데이터베이스 접속
```bash
# PostgreSQL
docker-compose exec postgres psql -U hospital -d hospital_app

# Redis
docker-compose exec redis redis-cli
```

### 개발 명령어
```bash
npm run start:dev           # 핫 리로드로 실행
npm test                    # 테스트 실행
npm run build               # 프로덕션 빌드
npm run lint                # 린트 체크
npm run format              # 코드 포맷
```

## 문제 해결

### 포트 이미 사용 중
```bash
# 사용 중인 프로세스 확인
lsof -i :3000

# 프로세스 종료
kill -9 <PID>
```

### 데이터베이스 연결 실패
```bash
# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs postgres

# 재시작
docker-compose restart postgres
```

### Seed 생성 실패
```bash
# 데이터베이스 초기화
docker-compose down -v

# 다시 시작
docker-compose up -d
sleep 30
npm run docker:seed
```

## 다음 단계

1. **API 문서 확인**: `http://localhost:3000/api/docs` (Swagger)
2. **비즈니스 로직 개발**: `src/modules/` 폴더에서 작업
3. **마이그레이션 관리**: `database/migrations/` 폴더에서 관리
4. **테스트 작성**: `src/**/*.spec.ts` 파일 추가

## 추가 가이드

| 주제 | 문서 |
|------|------|
| Docker 상세 가이드 | [DOCKER_SETUP.md](./DOCKER_SETUP.md) |
| 마이그레이션 관리 | [DATABASE_MIGRATIONS.md](./DATABASE_MIGRATIONS.md) |
| Seed 데이터 상세 | [SEED_DATA.md](./SEED_DATA.md) |
| 전체 아키텍처 | [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) |

## 팁 & 트릭

### 빠른 데이터 확인
```bash
# 모든 사용자 보기
docker-compose exec postgres psql -U hospital -d hospital_app -c "SELECT email, role FROM users;"

# 예약 보기
docker-compose exec postgres psql -U hospital -d hospital_app -c "SELECT * FROM appointments;"

# 의사 정보
docker-compose exec postgres psql -U hospital -d hospital_app -c "SELECT name, yearsOfExperience FROM doctors;"
```

### 개발 중 데이터 초기화
```bash
# 모든 데이터 삭제 및 재생성
docker-compose down -v
docker-compose up -d
sleep 30
npm run docker:seed
```

### 프로덕션 시뮬레이션
```bash
# .env에서 NODE_ENV=production으로 변경
NODE_ENV=production npm run docker:build
NODE_ENV=production npm run docker:up
```

## 성공 체크리스트

- [ ] Docker 및 docker-compose 설치됨
- [ ] `npm run docker:up` 완료
- [ ] `npm run docker:seed` 완료
- [ ] `curl http://localhost:3000` 성공
- [ ] 테스트 계정으로 로그인 가능

---

**질문이 있으신가요?** 상세 가이드를 참고하세요:
- [DOCKER_SETUP.md](./DOCKER_SETUP.md) - Docker 명령어 및 문제 해결
- [DATABASE_MIGRATIONS.md](./DATABASE_MIGRATIONS.md) - 마이그레이션 워크플로우
- [SEED_DATA.md](./SEED_DATA.md) - Seed 데이터 상세 정보
- [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) - 전체 아키텍처 설명

**마지막 업데이트:** 2025년 4월 14일

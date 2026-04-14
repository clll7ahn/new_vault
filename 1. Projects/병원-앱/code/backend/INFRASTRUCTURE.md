# 인프라 구성 가이드

이 문서는 병원 앱의 완전한 인프라 구성을 설명합니다.

## 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                   클라이언트 (웹/모바일)                      │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTP/REST
                             ▼
┌─────────────────────────────────────────────────────────────┐
│               Docker Compose Network                         │
│                                                               │
│  ┌──────────────────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ NestJS API (port 3000) │ Postgres  │  │ Redis        │  │
│  │ • Express Server     │ │(5432)    │  │ (6379)       │  │
│  │ • Entity Management  │ │ • DB     │  │ • Cache      │  │
│  │ • Route Handling     │ │ • Data   │  │ • Sessions   │  │
│  │ • Auth (JWT/Local)   │ │ • Schema │  │ • Queues     │  │
│  │ • Business Logic     │ │         │  │              │  │
│  └──────────────────────┘  └──────────┘  └──────────────┘  │
│         │                        │              │            │
│         └────────────┬───────────┴──────────────┘            │
│                      │                                       │
│         TypeORM (객체-관계 매핑)                             │
│                      │                                       │
└──────────────────────┼───────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
    .env              docker-compose.yml
    파일              (서비스 정의)
```

## 폴더 구조

```
backend/
├── Dockerfile              # 애플리케이션 컨테이너 정의
├── .dockerignore           # Docker 빌드 제외 파일
├── docker-compose.yml      # 멀티 컨테이너 오케스트레이션
├── ormconfig.ts            # TypeORM 설정 (마이그레이션용)
│
├── .env                    # 환경 변수 (개발용)
├── .env.example            # 환경 변수 템플릿
│
├── src/
│   ├── main.ts            # 애플리케이션 진입점
│   ├── app.module.ts      # 루트 모듈
│   ├── config/
│   │   ├── database.config.ts      # DB 설정
│   │   └── jwt.config.ts           # JWT 설정
│   └── modules/           # 비즈니스 로직
│       ├── common/        # 공통 모듈
│       │   ├── auth/
│       │   ├── hospital-info/
│       │   ├── appointment/
│       │   └── ...
│       └── specialty/     # 진료과별 모듈
│           ├── internal-medicine/
│           ├── dermatology/
│           └── ...
│
├── database/
│   ├── migrations/        # TypeORM 마이그레이션 스크립트
│   │   └── .gitkeep
│   └── seeds/            # 초기 데이터 생성 스크립트
│       └── seed.ts        # 메인 seed 스크립트
│
├── test/                 # 테스트 파일
├── package.json          # NPM 의존성 및 스크립트
├── package-lock.json     # 의존성 잠금 파일
├── tsconfig.json         # TypeScript 설정
│
├── DOCKER_SETUP.md       # Docker 사용 가이드
├── DATABASE_MIGRATIONS.md # 마이그레이션 가이드
├── SEED_DATA.md          # Seed 데이터 가이드
└── INFRASTRUCTURE.md     # 이 파일

```

## 주요 컴포넌트 설명

### 1. Dockerfile (Multi-stage Build)

**목적**: 애플리케이션을 Docker 이미지로 패키징

**빌드 단계**:
- **Builder Stage**: TypeScript → JavaScript 컴파일
- **Production Stage**: 필요한 파일만 복사, 최소 이미지 생성

**이점**:
- 최종 이미지 크기 약 50% 감소
- 빌드 도구 제외 (dist와 node_modules만 포함)

```dockerfile
# 빌드 스테이지
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 프로덕션 스테이지
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main"]
```

### 2. docker-compose.yml (오케스트레이션)

**역할**: 3개 서비스 정의 및 관리

#### a. API 서비스
```yaml
api:
  build: .                          # Dockerfile 빌드
  ports: ["3000:3000"]            # 포트 매핑
  environment:                      # 환경 변수 주입
    DB_HOST: postgres              # DNS 자동 해석
    REDIS_HOST: redis
  depends_on:
    postgres:
      condition: service_healthy   # 헬스 체크 대기
```

**특징**:
- 자동 재시작 (restart: unless-stopped)
- 볼륨 마운트 (개발 시 핫 리로드)
- 네트워크 격리

#### b. PostgreSQL 서비스
```yaml
postgres:
  image: postgres:16-alpine        # 경량 이미지
  environment:
    POSTGRES_DB: hospital_app
    POSTGRES_USER: hospital
  volumes: ["pgdata:/var/lib/postgresql/data"]
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U hospital"]
    interval: 10s
```

**특징**:
- 데이터 볼륨 영구 보존
- 헬스 체크로 신뢰성 향상
- 환경 변수로 설정 관리

#### c. Redis 서비스
```yaml
redis:
  image: redis:7-alpine
  ports: ["6379:6379"]
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
```

**특징**:
- 캐싱 및 세션 관리
- 경량 메모리 데이터베이스
- 빠른 응답 시간

### 3. .env 파일

**역할**: 환경 변수 중앙화 관리

```bash
# 환경
NODE_ENV=development

# 데이터베이스
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=hospital
DB_PASSWORD=password
DB_DATABASE=hospital_app

# 보안
JWT_SECRET=your-super-secret-jwt-key-change-in-production-12345

# 외부 서비스
REDIS_HOST=localhost
REDIS_PORT=6379
```

**보안 주의**:
- `.env`는 `.gitignore`에 포함 (Git 추적 제외)
- 프로덕션에서는 환경 변수로 주입
- JWT_SECRET은 복잡하게 설정

### 4. ormconfig.ts (TypeORM 설정)

**역할**: 데이터베이스 연결 및 마이그레이션 관리

```typescript
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  entities: ['src/**/*.entity{.ts,.js}'],
  migrations: ['database/migrations/*.{ts,js}'],
  synchronize: process.env.NODE_ENV !== 'production',
  migrationsRun: true,
});
```

**특징**:
- 환경별 동기화 모드 전환
- 자동 마이그레이션 실행
- 엔티티 자동 감지

### 5. database/seeds/seed.ts (초기 데이터)

**역할**: 개발/테스트용 초기 데이터 자동 생성

**생성 순서**:
1. 병원 (1개)
2. 진료과 (3개)
3. 관리자 (1명)
4. 의사 (3명)
5. 환자 (2명)
6. 일정 슬롯 (480개)
7. 샘플 예약 (5개)

**암호화**: bcrypt로 비밀번호 해싱

## 네트워킹 구조

### Docker 네트워크 (hospital-network)

```
┌─────────────────────────────────────────┐
│      hospital-network (bridge)          │
│                                         │
│  api:3000      postgres:5432  redis:6379
│    │───────────────│──────────────│
│         모두 같은 네트워크에 연결
└─────────────────────────────────────────┘
```

**이점**:
- 서비스명으로 자동 DNS 해석 (예: postgres → 172.18.0.2)
- 포트 노출 없이 내부 통신 (postgres는 외부 5432만 열림)
- 격리된 환경 (다른 컨테이너와 영향 없음)

## 환경별 구성

### 개발 환경
```bash
NODE_ENV=development
# Synchronize 모드: 엔티티 변경 시 자동 동기화
# 핫 리로드: 코드 변경 시 자동 재실행
# 상세 로깅: 모든 SQL 쿼리 출력
```

**명령어**:
```bash
npm run docker:up      # 컨테이너 시작
npm run start:dev      # 핫 리로드로 앱 실행
npm run docker:seed    # 초기 데이터 생성
```

### 스테이징 환경
```bash
NODE_ENV=staging
# Synchronize 모드 OFF: 마이그레이션 사용
# 자동 마이그레이션: 시작 시 마이그레이션 실행
# 사용자 로깅: 중요 이벤트만 기록
```

**배포 절차**:
```bash
npm run docker:build               # 이미지 빌드
docker-compose up -d               # 컨테이너 시작
npm run migration:run              # 마이그레이션 실행
npm run docker:seed                # 초기 데이터 (첫 배포만)
```

### 프로덕션 환경
```bash
NODE_ENV=production
# Synchronize 모드 OFF: 마이그레이션만 사용
# 헬스 체크: 활성화
# 로깅: 최소 (오류만)
# 리소스 제한: CPU/메모리 할당
```

**배포 절차**:
```bash
npm run migration:run              # 마이그레이션 (Seed 금지)
docker-compose -f docker-compose.prod.yml up -d
```

## 데이터 흐름

### 요청-응답 흐름

```
Client Request (HTTP)
       │
       ▼
┌──────────────────┐
│ NestJS API       │
│ • Route Handler  │
│ • Validation     │
│ • Business Logic │
└────────┬─────────┘
         │
         ▼
    ┌────────────┐
    │ TypeORM    │
    │ Repository │
    └────┬───────┘
         │
         ▼
    ┌──────────────┐
    │ PostgreSQL   │
    │ • Query      │
    │ • Persist    │
    └──────┬───────┘
           │
         (결과 반환)
           │
           ▼
    ┌──────────────┐
    │ API Response │
    │ (JSON)       │
    └──────┬───────┘
           │
           ▼
      Client (JSON)
```

### 캐싱 흐름 (Redis 활용)

```
요청
  │
  ├─► Redis 캐시 확인
  │     │
  │     ├─ 있음 → 즉시 반환 (빠름)
  │     │
  │     └─ 없음 → DB 조회
  │               │
  │               ▼
  │          PostgreSQL 쿼리
  │               │
  │               ▼
  │        Redis 캐시 저장
  │               │
  │               ▼
  │          클라이언트 반환
```

## 보안 구성

### 1. 네트워크 격리
- 각 서비스는 호스트 포트만 노출
- 내부 통신은 Docker 네트워크를 통해 격리

### 2. 암호 보안
- bcrypt로 사용자 비밀번호 해싱
- JWT_SECRET은 환경 변수로 관리

### 3. 데이터베이스 보안
```bash
# 강력한 비밀번호 사용
DB_PASSWORD=strong_password_here

# 데이터베이스 이름 지정
DB_DATABASE=hospital_app
```

### 4. 환경 변수 관리
```bash
# .env 파일은 Git에 커밋하지 않음
echo ".env" >> .gitignore

# 프로덕션: GitHub Secrets 또는 환경 변수로 주입
docker run -e DB_PASSWORD=${{ secrets.DB_PASSWORD }} ...
```

## 성능 최적화

### 1. 이미지 최적화
- Multi-stage 빌드: 400MB → 200MB로 감소
- Alpine Linux: 경량 기본 이미지
- 번들 크기 최소화

### 2. 데이터베이스 최적화
```typescript
// 인덱스 생성
@Index('IDX_appointments_doctor_date')
@Column()
doctorId: string;

@Column()
appointmentDate: Date;
```

### 3. 캐싱 전략
- Redis로 자주 접근하는 데이터 캐싱
- TTL 설정으로 자동 만료

### 4. 리소스 제한
```yaml
# docker-compose.yml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

## 모니터링

### 1. 헬스 체크
```bash
# API 헬스 체크
curl http://localhost:3000/health

# 데이터베이스 확인
docker-compose exec postgres pg_isready -U hospital

# Redis 확인
docker-compose exec redis redis-cli ping
```

### 2. 로그 확인
```bash
# 실시간 로그
npm run docker:logs

# 특정 서비스만
docker-compose logs -f api
docker-compose logs -f postgres
```

### 3. 성능 모니터링
```bash
# Docker 통계
docker stats

# 메모리 사용량
docker-compose exec api node -e "console.log(require('os').freemem())"
```

## 문제 해결

### 포트 충돌
```bash
# 사용 중인 포트 확인
lsof -i :3000

# Docker 네트워크 이슈
docker network inspect hospital-network
```

### 데이터베이스 연결 실패
```bash
# 연결 테스트
docker-compose exec api node -e "
  const pg = require('pg');
  new pg.Client({...}).connect().then(() => console.log('OK'));
"
```

### 메모리 부족
```bash
# Docker 메모리 설정 증가
# (Docker Desktop 설정에서 Resources 탭)

# 또는 스왑 설정
docker-compose exec api free -h
```

## 확장성 고려사항

### 수평 확장 (다중 API 서버)
```yaml
# Load Balancer가 필요함
services:
  api-1:
    build: .
  api-2:
    build: .
  api-3:
    build: .
  # 모두 같은 postgres/redis 공유
```

### 데이터베이스 레플리카
```yaml
# Read Replica 구성
services:
  postgres-primary:
    image: postgres:16-alpine
  postgres-replica:
    image: postgres:16-alpine
    # Replication 설정
```

## 참고 명령어 요약

```bash
# 시작/중지
npm run docker:up              # 시작
npm run docker:down            # 중지

# 빌드
npm run docker:build           # 이미지 재빌드
docker-compose build --no-cache # 캐시 무시하고 빌드

# 데이터 관리
npm run docker:seed            # Seed 데이터 생성
npm run migration:run          # 마이그레이션 실행
npm run migration:generate     # 새 마이그레이션 생성

# 모니터링
npm run docker:logs            # 로그 확인
docker-compose ps              # 상태 확인
docker stats                   # 리소스 사용량

# 데이터베이스
docker-compose exec postgres psql -U hospital -d hospital_app

# 청소
docker-compose down -v         # 컨테이너 및 볼륨 제거
docker system prune -a         # 사용하지 않는 이미지 제거
```

## 다음 단계

1. **초기화**: `npm run docker:up` 및 `npm run docker:seed`
2. **테스트**: `http://localhost:3000`에서 API 확인
3. **개발**: 엔티티 수정 후 마이그레이션 생성
4. **배포**: 마이그레이션 실행 후 컨테이너 시작

---

**마지막 업데이트:** 2025년 4월 14일

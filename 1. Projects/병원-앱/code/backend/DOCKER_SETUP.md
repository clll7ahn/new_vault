# Docker 환경 설정 가이드

이 문서는 NestJS 병원 앱을 Docker와 docker-compose로 실행하는 방법을 설명합니다.

## 파일 구조

```
backend/
├── Dockerfile                 # 애플리케이션 컨테이너 이미지 정의
├── docker-compose.yml        # 멀티 컨테이너 오케스트레이션
├── .dockerignore             # Docker 빌드 시 제외할 파일
├── .env                      # 환경 변수 설정 (개발용)
├── database/
│   └── seeds/
│       └── seed.ts          # 초기 데이터 생성 스크립트
└── ... (other files)
```

## 사전 준비

### 필수 설치 항목
- Docker (버전 20.10 이상)
- Docker Compose (버전 1.29 이상)

### 설치 확인
```bash
docker --version      # Docker 버전 확인
docker-compose --version  # Docker Compose 버전 확인
```

## 빠른 시작

### 1. 환경 설정
.env 파일이 이미 생성되어 있습니다. 필요에 따라 수정하세요.

```bash
# .env 파일 확인
cat .env

# 필요시 환경 변수 수정
# DB_HOST, DB_PORT, JWT_SECRET 등을 변경할 수 있습니다.
```

### 2. Docker 컨테이너 시작
```bash
# 컨테이너 빌드 및 시작 (백그라운드 모드)
npm run docker:up

# 또는
docker-compose up -d
```

**생성되는 서비스:**
- **api** (port 3000): NestJS API 서버
- **postgres** (port 5432): PostgreSQL 데이터베이스
- **redis** (port 6379): Redis 캐시 서버

### 3. 초기 데이터 생성 (Seed)

#### 방법 1: docker-compose 통해 실행 (권장)
```bash
npm run docker:seed

# 또는
docker-compose exec api npm run seed
```

#### 방법 2: 로컬에서 실행 (PostgreSQL이 실행 중일 때)
```bash
npm run seed:dev
```

### 4. 서비스 상태 확인
```bash
# 실행 중인 컨테이너 확인
docker-compose ps

# 출력 예시:
# NAME                   COMMAND                  SERVICE      STATUS
# hospital-app-api      node dist/main           api          Up 2 minutes
# hospital-app-db       postgres ...             postgres     Up 2 minutes  
# hospital-app-cache    redis-server ...         redis        Up 2 minutes
```

### 5. 로그 확인
```bash
# 모든 서비스 로그 확인
npm run docker:logs

# 특정 서비스만 확인
docker-compose logs api
docker-compose logs postgres
docker-compose logs redis
```

### 6. API 테스트
```bash
# API 헬스체크
curl http://localhost:3000

# 또는 브라우저에서
http://localhost:3000
```

## 테스트 계정

초기 데이터 생성 후 다음 계정으로 로그인할 수 있습니다:

### 관리자
- **Email:** admin@hospital.com
- **Password:** admin123

### 의사
- **Email:** doctor1@hospital.com (내과)
- **Email:** doctor2@hospital.com (피부과)
- **Email:** doctor3@hospital.com (정형외과)
- **Password:** doctor123

### 환자
- **Email:** patient1@test.com
- **Email:** patient2@test.com
- **Password:** patient123

## 주요 NPM 스크립트

```bash
# Docker 관련 명령어
npm run docker:up         # 컨테이너 시작
npm run docker:down       # 컨테이너 중지 및 제거
npm run docker:build      # 이미지 재빌드
npm run docker:logs       # 로그 확인 (실시간)
npm run docker:seed       # 초기 데이터 생성

# 시드 관련 명령어
npm run seed              # 시드 데이터 생성
npm run seed:dev          # 개발 환경에서 시드 실행

# 기본 NestJS 명령어
npm run build            # 애플리케이션 빌드
npm run start            # 애플리케이션 실행
npm run start:dev        # 개발 모드 실행 (핫 리로드)
npm run start:prod       # 프로덕션 모드 실행
npm test                 # 테스트 실행
```

## 데이터베이스 접속

### PostgreSQL 직접 접속
```bash
# docker-compose 통해 접속
docker-compose exec postgres psql -U hospital -d hospital_app

# 또는 psql 클라이언트로 직접 접속
psql -h localhost -U hospital -d hospital_app
# 비밀번호: password

# 주요 명령어
\dt                    # 모든 테이블 조회
SELECT * FROM users;   # 사용자 테이블 조회
SELECT * FROM doctors; # 의사 테이블 조회
\q                     # 종료
```

### pgAdmin (선택사항)
docker-compose.yml에 pgAdmin을 추가하고 싶으면:
```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@pgadmin.com
    PGADMIN_DEFAULT_PASSWORD: admin
  ports:
    - "5050:80"
  depends_on:
    - postgres
```

## 컨테이너 정지 및 정리

```bash
# 컨테이너 중지
npm run docker:down

# 또는
docker-compose down

# 볼륨 포함하여 완전히 제거 (데이터도 삭제됨)
docker-compose down -v

# 이미지 제거
docker-compose down --rmi all
```

## 문제 해결

### 포트 충돌
```bash
# 특정 포트 사용 중인 프로세스 확인
lsof -i :3000  # API 포트
lsof -i :5432  # DB 포트
lsof -i :6379  # Redis 포트

# 프로세스 종료
kill -9 <PID>
```

### 데이터베이스 연결 실패
```bash
# PostgreSQL 정상 여부 확인
docker-compose logs postgres

# 컨테이너 다시 시작
docker-compose restart postgres

# 헬스체크 확인
docker-compose ps  # STATUS에 "healthy" 표시 여부
```

### 볼륨 문제
```bash
# 모든 이상한 볼륨 제거
docker volume prune

# 특정 볼륨 확인
docker volume ls
docker volume inspect hospital-app-backend_pgdata
```

### 메모리 부족
```bash
# Docker 데스크톱 설정에서 메모리 할당 증가
# 또는 특정 서비스의 리소스 제한 수정
docker-compose down
# docker-compose.yml에서 resources 섹션 수정 후
docker-compose up -d
```

## 개발 워크플로우

### 로컬 개발 (Docker 없이)
```bash
# 1. 로컬 PostgreSQL과 Redis 시작
# (또는 docker-compose로 DB만 실행)
docker-compose up -d postgres redis

# 2. 환경 변수 설정
# .env 파일에서 DB_HOST를 localhost로 설정

# 3. 초기 데이터 생성
npm run seed:dev

# 4. 개발 서버 실행 (핫 리로드)
npm run start:dev
```

### 프로덕션 빌드
```bash
# 1. 이미지 빌드
npm run docker:build

# 2. 컨테이너 시작
npm run docker:up

# 3. 헬스 체크
curl http://localhost:3000/health
```

## 성능 최적화

### 다중 스테이지 빌드
Dockerfile은 이미 다중 스테이지 빌드를 사용하여:
- 빌드 단계와 프로덕션 단계 분리
- 최종 이미지 크기 최소화 (약 200MB 이상 절감)

### 네트워크 최적화
docker-compose.yml에서 커스텀 네트워크 사용:
- 서비스 간 DNS 자동 해석
- 격리된 네트워크 환경

### 헬스 체크
각 서비스에 헬스 체크 설정:
```bash
# 헬스 체크 상태 확인
docker-compose ps
```

## CI/CD 통합

### GitHub Actions 예시
```yaml
name: Docker Build & Deploy

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker image
        run: docker-compose build
      - name: Run tests
        run: docker-compose run api npm test
      - name: Deploy
        run: docker-compose up -d
```

## 참고 문서

- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Compose 공식 문서](https://docs.docker.com/compose/)
- [NestJS 공식 문서](https://docs.nestjs.com/)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)

## 추가 팁

### 환경별 설정
```bash
# 개발 환경
NODE_ENV=development docker-compose up -d

# 프로덕션 환경
NODE_ENV=production docker-compose up -d

# 테스트 환경
NODE_ENV=test docker-compose up -d
```

### 커스텀 스크립트
docker-compose.yml에서 서비스별로 환경 변수 주입:
```yaml
environment:
  NODE_ENV: ${NODE_ENV:-development}
  LOG_LEVEL: ${LOG_LEVEL:-debug}
```

### 백업 및 복구
```bash
# 데이터베이스 백업
docker-compose exec postgres pg_dump -U hospital -d hospital_app > backup.sql

# 데이터베이스 복구
docker-compose exec -T postgres psql -U hospital -d hospital_app < backup.sql
```

---

**마지막 업데이트:** 2025년 4월 14일

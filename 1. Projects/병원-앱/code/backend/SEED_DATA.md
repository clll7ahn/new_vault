# 초기 데이터(Seed Data) 가이드

이 문서는 병원 앱의 초기 데이터 구조와 생성 방법을 설명합니다.

## 개요

seed.ts 스크립트는 다음 초기 데이터를 생성합니다:

- **1개 병원** (예시내과의원)
- **3개 진료과** (내과, 피부과, 정형외과)
- **3명의 의사** (각 진료과별 1명)
- **1명의 관리자**
- **2명의 환자**
- **진료 일정 슬롯** (의사별 월~금 09:00-17:00, 30분 간격)
- **샘플 예약** (5개)

## 빠른 시작

### 방법 1: Docker를 통한 Seed 생성 (권장)
```bash
# 1. Docker 컨테이너 시작
npm run docker:up

# 2. 초기 데이터 생성 대기 (컨테이너가 완전히 준비될 때까지)
sleep 10

# 3. Seed 데이터 생성
npm run docker:seed

# 또는
docker-compose exec api npm run seed
```

### 방법 2: 로컬에서 Seed 생성
```bash
# 1. PostgreSQL과 Redis가 실행 중인지 확인
docker-compose up -d postgres redis

# 2. 환경 변수 확인 (.env 파일)
cat .env

# 3. Seed 데이터 생성
npm run seed:dev

# 또는
npm run seed
```

## 생성되는 데이터 상세

### 1. 병원 정보
```javascript
{
  name: '예시내과의원',
  address: '서울시 강남구 테헤란로 123',
  phone: '02-1234-5678',
  registrationNumber: 'REG20250414001',
  operatingHours: {
    monday: { open: '09:00', close: '18:00' },
    tuesday: { open: '09:00', close: '18:00' },
    wednesday: { open: '09:00', close: '18:00' },
    thursday: { open: '09:00', close: '18:00' },
    friday: { open: '09:00', close: '18:00' },
    saturday: { open: '09:00', close: '13:00' },
    sunday: { open: '', close: '' }
  },
  latitude: 37.4979,
  longitude: 127.0276
}
```

### 2. 진료과
| 이름 | 설명 | 순서 |
|------|------|------|
| 내과 | 일반 내과 진료 | 1 |
| 피부과 | 피부 질환 진료 | 2 |
| 정형외과 | 뼈 및 관절 질환 진료 | 3 |

### 3. 사용자 계정

#### 관리자 계정
| 필드 | 값 |
|------|------|
| Email | admin@hospital.com |
| Password | admin123 |
| Name | 관리자 |
| Role | ADMIN |

#### 의사 계정
| Email | Name | Department | License | Experience |
|-------|------|-----------|---------|-------------|
| doctor1@hospital.com | 김내과 | 내과 | LIC20250001 | 5년 |
| doctor2@hospital.com | 이피부 | 피부과 | LIC20250002 | 7년 |
| doctor3@hospital.com | 박정형 | 정형외과 | LIC20250003 | 6년 |

Password: `doctor123`

#### 환자 계정
| Email | Name |
|-------|------|
| patient1@test.com | 환자1 |
| patient2@test.com | 환자2 |

Password: `patient123`

### 4. 진료 일정 슬롯
- **생성 대상**: 각 의사별로 월~금(1~5)
- **시간대**: 09:00 ~ 17:00
- **간격**: 30분
- **총 개수**: 의사 3명 × 5일 × 16시간 × 2슬롯/시간 = **480개 슬롯**

예시:
```
의사1(내과) - 월요일 09:00, 09:30, 10:00, ..., 16:30
의사1(내과) - 화요일 09:00, 09:30, 10:00, ..., 16:30
...
의사3(정형외과) - 금요일 09:00, 09:30, 10:00, ..., 16:30
```

### 5. 샘플 예약
| 환자 | 의사 | 진료과 | 날짜 | 시간 | 상태 | 증상 |
|------|------|--------|------|------|------|------|
| 환자1 | 김내과 | 내과 | 내일 | 10:00 | confirmed | 감기 증상 |
| 환자1 | 이피부 | 피부과 | +2일 | 14:00 | confirmed | 피부 발진 |
| 환자2 | 박정형 | 정형외과 | +3일 | 11:00 | confirmed | 허리 통증 |
| 환자2 | 김내과 | 내과 | +4일 | 15:30 | pending | 건강검진 |
| 환자1 | 박정형 | 정형외과 | +5일 | 09:00 | pending | 무릎 통증 |

## Seed 스크립트 구조

### 실행 순서
```
1. 데이터베이스 연결
   ↓
2. 기존 데이터 삭제 및 동기화
   ↓
3. 병원 생성 (1개)
   ↓
4. 진료과 생성 (3개)
   ↓
5. 관리자 사용자 생성 (1개)
   ↓
6. 의사 사용자 생성 (3개)
   ↓
7. 의사 상세 정보 생성 (3개)
   ↓
8. 환자 사용자 생성 (2개)
   ↓
9. 진료 일정 슬롯 생성 (480개)
   ↓
10. 샘플 예약 생성 (5개)
    ↓
11. 완료 메시지 출력
```

### 암호 해싱
모든 사용자 계정은 bcrypt로 암호화됨:
```javascript
const saltRounds = 10;
const passwordHash = await bcrypt.hash(password, saltRounds);
```

## 실행 결과 확인

### 1. 콘솔 출력 확인
```bash
npm run seed

# 출력 예시:
# ✓ Database connection established
# [1/7] Creating hospital...
# ✓ Hospital created: 예시내과의원
# [2/7] Creating departments...
# ✓ Departments created: 내과, 피부과, 정형외과
# [3/7] Creating admin user...
# ✓ Admin user created: admin@hospital.com
# [4/7] Creating doctors...
# ✓ Doctors created: 김내과, 이피부, 박정형
# [5/7] Creating patient users...
# ✓ Patient users created: 환자1, 환자2
# [6/7] Creating schedule slots...
# ✓ Schedule slots created: 480 slots
# [7/7] Creating sample appointments...
# ✓ Sample appointments created: 5 appointments
# 
# ✓ SEED DATA COMPLETED SUCCESSFULLY
```

### 2. 데이터베이스 확인

#### PostgreSQL CLI에서
```bash
docker-compose exec postgres psql -U hospital -d hospital_app

# 테이블 확인
\dt

# 데이터 조회
SELECT COUNT(*) FROM users;           -- 6 (admin + 3 doctors + 2 patients)
SELECT COUNT(*) FROM hospitals;       -- 1
SELECT COUNT(*) FROM departments;     -- 3
SELECT COUNT(*) FROM doctors;         -- 3
SELECT COUNT(*) FROM schedule_slots;  -- 480
SELECT COUNT(*) FROM appointments;    -- 5

# 상세 확인
SELECT email, role FROM users ORDER BY role;
SELECT name, yearsOfExperience FROM doctors;
SELECT appointment_date, appointment_time FROM appointments ORDER BY appointment_date;
```

#### API 호출로 확인
```bash
# 의사 목록 조회 (예시)
curl http://localhost:3000/doctors

# 예약 목록 조회 (예시)
curl http://localhost:3000/appointments

# 병원 정보 조회 (예시)
curl http://localhost:3000/hospital
```

## 커스터마이징

### Seed 데이터 수정

#### 병원 정보 변경
```typescript
// database/seeds/seed.ts - 병원 생성 부분
const hospital = hospitalRepository.create({
  name: '변경할 병원 이름',
  address: '변경할 주소',
  phone: '변경할 전화번호',
  // ...
});
```

#### 진료과 추가
```typescript
// 진료과 생성 부분에 추가
const departments = departmentRepository.create([
  // ... 기존 3개
  {
    hospitalId: savedHospital.id,
    name: '안과',
    description: '눈 질환 진료',
    isActive: true,
    displayOrder: 4,
  },
]);
```

#### 의사 추가
```typescript
// 의사 생성 부분에 추가
{
  email: 'doctor4@hospital.com',
  passwordHash: doctorPasswordHash,
  name: '최안과',
  role: UserRole.DOCTOR,
  phone: '010-4444-4444',
  isActive: true,
},

// 그리고 Doctor 레코드도 추가
{
  userId: savedDoctors[3].id,
  name: savedDoctors[3].name,
  departmentId: savedDepartments[3].id, // 새 진료과
  licenseNumber: 'LIC20250004',
  // ...
}
```

#### 진료 일정 시간 변경
```typescript
// 일정 생성 부분
const startHour = 8;      // 시작 시간 변경
const endHour = 18;       // 종료 시간 변경
const slotDuration = 60;  // 간격 변경 (60분)
```

#### 샘플 예약 추가
```typescript
{
  patientId: savedPatients[0].id,
  doctorId: savedDoctorRecords[0].id,
  departmentId: savedDepartments[0].id,
  appointmentDate: new Date(Date.now() + 604800000).toISOString().split('T')[0], // +7일
  appointmentTime: '13:00:00',
  status: 'pending',
  chiefComplaint: '추가 증상',
  notes: '추가 메모',
},
```

## 환경별 Seed 전략

### 개발 환경
```bash
# 자주 seed를 재생성하여 깨끗한 상태 유지
npm run seed:dev

# 또는 docker-compose로
docker-compose down -v
docker-compose up -d
npm run docker:seed
```

### 스테이징 환경
```bash
# 첫 배포 시에만 실행
docker-compose up -d
docker-compose exec api npm run seed

# 이후는 마이그레이션으로만 업데이트
npm run migration:run
```

### 프로덕션 환경
```bash
# Seed 실행 금지!
# 대신 마이그레이션과 데이터 관리 스크립트만 사용
npm run migration:run
```

## 더미 데이터 삭제

### 모든 Seed 데이터 삭제
```bash
# 방법 1: Docker 볼륨 제거
docker-compose down -v

# 방법 2: 데이터베이스 리셋
docker-compose exec postgres psql -U hospital -d hospital_app -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# 방법 3: 타입 ORM 동기화
npm run start:dev
# 애플리케이션이 시작되면서 synchronize: true에 의해 테이블 재생성
```

## 성능 최적화

### 대량 데이터 생성 시 팁
```typescript
// 성능 개선: 배치 삽입 사용
const scheduleSlots = [];
for (const doctor of savedDoctorRecords) {
  for (let day = 1; day <= 5; day++) {
    for (let hour = 9; hour < 17; hour++) {
      // 데이터 생성...
      scheduleSlots.push(slot);
    }
  }
}

// 배치로 삽입 (더 빠름)
for (let i = 0; i < scheduleSlots.length; i += 100) {
  const batch = scheduleSlots.slice(i, i + 100);
  await scheduleSlotRepository.save(batch);
}
```

## 테스트 데이터 생성

### Jest 테스트를 위한 별도 seed
```typescript
// database/seeds/seed.test.ts
export async function createTestData() {
  const user = await userRepository.save({
    email: 'test@test.com',
    passwordHash: await hashPassword('test123'),
    name: 'Test User',
    role: UserRole.PATIENT,
  });
  return user;
}

// test에서 사용
import { createTestData } from '../database/seeds/seed.test';
```

## 문제 해결

### Seed 실행 실패
```bash
# 1. 데이터베이스 연결 확인
docker-compose exec postgres psql -U hospital -d hospital_app -c "SELECT 1"

# 2. 로그 확인
npm run seed 2>&1 | tail -50

# 3. 데이터베이스 초기화 후 재시도
docker-compose down -v
docker-compose up -d postgres
sleep 10
npm run docker:seed
```

### 제약 조건 위반
```bash
# 데이터베이스 상태 확인
SELECT * FROM typeorm_metadata;

# 테이블 구조 확인
\d users

# 초기화
docker-compose exec postgres psql -U hospital -d hospital_app -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

## 참고 문서

- [TypeORM 공식 문서](https://typeorm.io/)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)
- [Bcrypt 라이브러리](https://github.com/kelektiv/node.bcrypt.js)

---

**마지막 업데이트:** 2025년 4월 14일

# 데이터베이스 마이그레이션 가이드

이 문서는 TypeORM을 사용한 데이터베이스 마이그레이션 관리 방법을 설명합니다.

## 개요

이 프로젝트는 다음 두 가지 데이터베이스 관리 전략을 사용합니다:

1. **Synchronize 모드** (개발 환경): 엔티티 변경 시 자동으로 DB 동기화
2. **마이그레이션** (프로덕션): 버전 관리되는 마이그레이션 스크립트 사용

## 빠른 시작

### 마이그레이션 생성
```bash
# 새로운 마이그레이션 생성
npm run migration:generate -- --name=초기마이그레이션

# 예시
npm run migration:generate -- --name=CreateUserTable
npm run migration:generate -- --name=AddPhoneToUser
```

### 마이그레이션 실행
```bash
# 대기 중인 모든 마이그레이션 실행
npm run migration:run
```

### 마이그레이션 되돌리기
```bash
# 마지막 마이그레이션 되돌리기
npm run migration:revert
```

## 마이그레이션 워크플로우

### 1단계: 엔티티 수정
```typescript
// src/modules/auth/entities/user.entity.ts
@Entity('users')
export class User {
  @Column({ length: 100, nullable: true })
  middleName: string | null;  // 새로운 필드 추가
}
```

### 2단계: 마이그레이션 생성
```bash
npm run migration:generate -- --name=AddMiddleNameToUser
```

생성된 파일 예시:
```typescript
// database/migrations/1713084000000-AddMiddleNameToUser.ts
import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddMiddleNameToUser1713084000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'users',
      new TableColumn({
        name: 'middle_name',
        type: 'varchar',
        length: '100',
        isNullable: true,
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('users', 'middle_name');
  }
}
```

### 3단계: 마이그레이션 실행
```bash
npm run migration:run
```

### 4단계: Git 커밋
```bash
git add database/migrations/
git commit -m "migration: Add middle_name column to users table"
```

## 마이그레이션 파일 구조

```
database/migrations/
├── 1713083000000-InitialSchema.ts
├── 1713084000000-AddMiddleNameToUser.ts
└── 1713085000000-CreateDoctorPreferences.ts
```

### 마이그레이션 파일 명명 규칙
- 타임스탬프: `1713083000000` (Unix timestamp in milliseconds)
- 설명: 변경 사항을 명확하게 설명

## 마이그레이션 예시

### 예시 1: 새 테이블 생성
```typescript
import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateAppointmentReminders1713083000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'appointment_reminders',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'gen_random_uuid()',
          },
          {
            name: 'appointment_id',
            type: 'uuid',
          },
          {
            name: 'reminder_type',
            type: 'varchar',
            length: '50',
          },
          {
            name: 'scheduled_at',
            type: 'timestamp',
          },
          {
            name: 'is_sent',
            type: 'boolean',
            default: false,
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'now()',
          },
        ],
        foreignKeys: [
          {
            columnNames: ['appointment_id'],
            referencedTableName: 'appointments',
            referencedColumnNames: ['id'],
            onDelete: 'CASCADE',
          },
        ],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('appointment_reminders');
  }
}
```

### 예시 2: 인덱스 추가
```typescript
import { MigrationInterface, QueryRunner, TableIndex } from 'typeorm';

export class AddIndexToAppointmentDate1713083100000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createIndex(
      'appointments',
      new TableIndex({
        name: 'IDX_appointments_date_doctor',
        columnNames: ['appointment_date', 'doctor_id'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('appointments', 'IDX_appointments_date_doctor');
  }
}
```

### 예시 3: 데이터 마이그레이션
```typescript
import { MigrationInterface, QueryRunner } from 'typeorm';

export class UpdateUserRoles1713083200000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 모든 의사를 DOCTOR 역할로 변경
    await queryRunner.query(
      `UPDATE users SET role = 'doctor' WHERE id IN (SELECT user_id FROM doctors)`,
    );

    // 특정 사용자의 역할 업데이트
    await queryRunner.query(
      `UPDATE users SET role = 'admin' WHERE email = 'admin@hospital.com'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // 이전 상태로 복원
    await queryRunner.query(
      `UPDATE users SET role = 'patient' WHERE role = 'doctor'`,
    );
  }
}
```

### 예시 4: 제약 조건 추가
```typescript
import { MigrationInterface, QueryRunner, TableUnique } from 'typeorm';

export class AddUniqueConstraintToLicense1713083300000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createUniqueConstraint(
      'doctors',
      new TableUnique({
        name: 'UQ_doctors_license_number',
        columnNames: ['license_number'],
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropUniqueConstraint('doctors', 'UQ_doctors_license_number');
  }
}
```

## Docker 환경에서의 마이그레이션

### 자동 마이그레이션 (권장)
docker-compose.yml에서 `migrationsRun: true` 설정 시, 애플리케이션 시작 시 자동 마이그레이션 실행:

```bash
npm run docker:up
# 자동으로 마이그레이션 실행
```

### 수동 마이그레이션
```bash
# Docker 컨테이너에서 마이그레이션 실행
docker-compose exec api npm run migration:run

# 마이그레이션 상태 확인
docker-compose exec postgres psql -U hospital -d hospital_app -c "SELECT * FROM typeorm_metadata;"
```

## 마이그레이션 상태 확인

### 실행된 마이그레이션 확인
```bash
docker-compose exec postgres psql -U hospital -d hospital_app

# PostgreSQL CLI에서
SELECT * FROM typeorm_metadata WHERE type = 'migration';

# 또는
\d typeorm_metadata
SELECT * FROM typeorm_metadata;
```

### 대기 중인 마이그레이션 확인
```bash
# 마이그레이션 파일과 DB 상태 비교
npm run typeorm -- migration:show
```

## 마이그레이션 모범 사례

### 1. 원자적 변경 (Atomic Changes)
한 번의 마이그레이션에는 하나의 논리적 변경만:
```bash
# Good
npm run migration:generate -- --name=AddPhoneToUser
npm run migration:generate -- --name=AddEmailVerificationToUser

# Bad
npm run migration:generate -- --name=AddPhoneAndEmailVerificationToUser
```

### 2. 명확한 이름 지정
변경 사항을 정확히 설명하는 이름 사용:
```bash
# Good
npm run migration:generate -- --name=AddIndexToAppointmentDate

# Bad
npm run migration:generate -- --name=UpdateDatabase
```

### 3. Down 메서드 항상 구현
역방향 마이그레이션도 완전히 구현:
```typescript
export class AddColumn1713083000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 열 추가
    await queryRunner.addColumn(...);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // 열 제거 (필수!)
    await queryRunner.dropColumn(...);
  }
}
```

### 4. 대용량 데이터 마이그레이션 주의
```typescript
export class MigrateUserData1713083000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // 배치 처리로 대용량 데이터 마이그레이션
    const batchSize = 1000;
    const users = await queryRunner.query('SELECT id FROM users');

    for (let i = 0; i < users.length; i += batchSize) {
      const batch = users.slice(i, i + batchSize).map(u => u.id);
      await queryRunner.query(
        `UPDATE users SET processed = true WHERE id = ANY($1)`,
        [batch],
      );
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('UPDATE users SET processed = false');
  }
}
```

### 5. 트랜잭션 활용
중요한 마이그레이션은 트랜잭션으로 보호:
```typescript
export class CriticalMigration1713083000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // queryRunner는 기본적으로 트랜잭션 내에서 실행됨
    await queryRunner.startTransaction();
    try {
      await queryRunner.query('...');
      await queryRunner.query('...');
      await queryRunner.commitTransaction();
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // 역방향도 동일하게 처리
  }
}
```

## 문제 해결

### 마이그레이션 충돌
두 명 이상이 동시에 마이그레이션을 생성한 경우:
```bash
# 1. 마이그레이션 파일 합병
# 2. typeorm_metadata 테이블 확인
SELECT * FROM typeorm_metadata WHERE type = 'migration' ORDER BY timestamp DESC;

# 3. 필요시 충돌하는 마이그레이션 삭제
npm run migration:revert
npm run migration:run
```

### 마이그레이션 실패
```bash
# 1. 로그 확인
docker-compose logs api

# 2. 마이그레이션 상태 확인
docker-compose exec postgres psql -U hospital -d hospital_app

# 3. 실패한 마이그레이션 수동 되돌리기
npm run migration:revert

# 4. 마이그레이션 파일 수정 후 재실행
npm run migration:run
```

### 동기화 모드 vs 마이그레이션
```bash
# 개발: 동기화 모드 (synchronize: true)
NODE_ENV=development npm run start:dev

# 프로덕션: 마이그레이션 모드 (synchronize: false)
NODE_ENV=production npm run docker:up
```

## 환경별 마이그레이션 전략

### 개발 환경
```typescript
// ormconfig.ts
export const AppDataSource = new DataSource({
  ...
  synchronize: true,  // 자동 동기화
  migrationsRun: false,
});
```

### 스테이징 환경
```typescript
// ormconfig.ts
export const AppDataSource = new DataSource({
  ...
  synchronize: false,
  migrationsRun: true,  // 자동 마이그레이션
});
```

### 프로덕션 환경
```bash
# 수동 마이그레이션 실행 후 배포
npm run migration:run
npm run start:prod
```

## 마이그레이션 성능 최적화

### 인덱스 전략
```typescript
// 마이그레이션에서 인덱스 추가
await queryRunner.createIndex('users', new TableIndex({
  name: 'IDX_users_email',
  columnNames: ['email'],  // 검색 성능 향상
}));

// 복합 인덱스
await queryRunner.createIndex('appointments', new TableIndex({
  name: 'IDX_appointments_doctor_date',
  columnNames: ['doctor_id', 'appointment_date'],
}));
```

### 대용량 테이블 변경
```bash
# 스냅샷 생성 후 변경
CREATE TABLE users_new AS SELECT * FROM users;
-- 변경 작업
ALTER TABLE users RENAME TO users_old;
ALTER TABLE users_new RENAME TO users;
DROP TABLE users_old;
```

## 참고 문서

- [TypeORM 마이그레이션 공식 문서](https://typeorm.io/migrations)
- [PostgreSQL 마이그레이션 가이드](https://www.postgresql.org/docs/)
- [Database Versioning Best Practices](https://www.liquibase.org/get-started/best-practices)

---

**마지막 업데이트:** 2025년 4월 14일

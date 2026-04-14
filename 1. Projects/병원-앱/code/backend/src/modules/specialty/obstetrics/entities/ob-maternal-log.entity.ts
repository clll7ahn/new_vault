import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ObPregnancy } from './ob-pregnancy.entity';

export enum EdemaLevel {
  NONE = 'none',
  MILD = 'mild',
  MODERATE = 'moderate',
  SEVERE = 'severe',
}

@Entity('ob_maternal_logs')
export class ObMaternalLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pregnancy_id' })
  pregnancyId: string;

  @ManyToOne(() => ObPregnancy, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pregnancy_id' })
  pregnancy: ObPregnancy;

  @Column({ type: 'decimal', precision: 5, scale: 2 })
  weight: number;

  @Column({ name: 'blood_pressure_sys', type: 'int' })
  bloodPressureSys: number;

  @Column({ name: 'blood_pressure_dia', type: 'int' })
  bloodPressureDia: number;

  @Column({ name: 'edema_level', type: 'enum', enum: EdemaLevel, default: EdemaLevel.NONE })
  edemaLevel: EdemaLevel;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}

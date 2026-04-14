import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum EntSymptomType {
  NASAL_CONGESTION = 'nasal_congestion',
  SORE_THROAT = 'sore_throat',
  EAR_PAIN = 'ear_pain',
  SNORING = 'snoring',
  HEARING_LOSS = 'hearing_loss',
  DIZZINESS = 'dizziness',
  TINNITUS = 'tinnitus',
}

@Entity('ent_symptom_logs')
export class EntSymptomLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'symptom_type', type: 'enum', enum: EntSymptomType })
  symptomType: EntSymptomType;

  @Column({ type: 'int' })
  severity: number;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../../common/auth/entities/user.entity';

export enum KmTreatmentType {
  ACUPUNCTURE = 'acupuncture',
  MOXIBUSTION = 'moxibustion',
  CUPPING = 'cupping',
  HERBAL = 'herbal',
  CHUNA = 'chuna',
}

@Entity('km_treatment_records')
export class KmTreatmentRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'doctor_id' })
  doctorId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'doctor_id' })
  doctor: User;

  @Column({ name: 'treatment_type', type: 'enum', enum: KmTreatmentType })
  treatmentType: KmTreatmentType;

  @Column({ name: 'body_points', type: 'text', array: true, nullable: true })
  bodyPoints: string[] | null;

  @Column({ type: 'text', nullable: true })
  prescription: string | null;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'treated_at', type: 'timestamptz' })
  treatedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

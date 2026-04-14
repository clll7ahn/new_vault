import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../../common/auth/entities/user.entity';

export enum KmConstitutionType {
  TAEYANG = 'taeyang',
  TAEEUM = 'taeeum',
  SOYANG = 'soyang',
  SOEUM = 'soeum',
}

@Entity('km_constitutions')
export class KmConstitution {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'constitution_type', type: 'enum', enum: KmConstitutionType })
  constitutionType: KmConstitutionType;

  @Column({ name: 'diagnosis_note', type: 'text' })
  diagnosisNote: string;

  @Column({ name: 'diagnosed_at', type: 'timestamptz' })
  diagnosedAt: Date;

  @Column({ name: 'doctor_id' })
  doctorId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'doctor_id' })
  doctor: User;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

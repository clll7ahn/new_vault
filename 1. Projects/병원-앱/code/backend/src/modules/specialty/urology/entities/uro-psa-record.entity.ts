import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('uro_psa_records')
export class UroPsaRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'psa_value', type: 'decimal', precision: 8, scale: 3 })
  psaValue: number;

  @Column({ name: 'tested_at', type: 'date' })
  testedAt: string;

  @Column({ type: 'text', nullable: true })
  note: string | null;
}

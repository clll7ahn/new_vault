import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('psy_counseling_notes')
export class PsyCounselingNote {
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

  @Column({ type: 'text' })
  summary: string;

  @Column({ name: 'patient_visible', type: 'boolean', default: false })
  patientVisible: boolean;

  @Column({ name: 'session_at', type: 'timestamptz' })
  sessionAt: Date;
}

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('oph_vision_logs')
export class OphVisionLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'enum', enum: ['left', 'right', 'both'] })
  eye: 'left' | 'right' | 'both';

  @Column({ type: 'decimal', precision: 4, scale: 2 })
  vision: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  iop: number | null;

  @Column({ name: 'measured_at', type: 'timestamptz' })
  measuredAt: Date;
}

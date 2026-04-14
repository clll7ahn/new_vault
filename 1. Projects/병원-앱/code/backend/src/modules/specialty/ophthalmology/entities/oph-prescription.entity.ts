import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('oph_prescriptions')
export class OphPrescription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'enum', enum: ['glasses', 'contact_lens'] })
  type: 'glasses' | 'contact_lens';

  @Column({ name: 'sph_left', type: 'decimal', precision: 5, scale: 2 })
  sphLeft: number;

  @Column({ name: 'sph_right', type: 'decimal', precision: 5, scale: 2 })
  sphRight: number;

  @Column({ name: 'cyl_left', type: 'decimal', precision: 5, scale: 2, nullable: true })
  cylLeft: number | null;

  @Column({ name: 'cyl_right', type: 'decimal', precision: 5, scale: 2, nullable: true })
  cylRight: number | null;

  @Column({ name: 'prescribed_at', type: 'timestamptz' })
  prescribedAt: Date;

  @Column({ name: 'next_replace', type: 'date', nullable: true })
  nextReplace: string | null;
}

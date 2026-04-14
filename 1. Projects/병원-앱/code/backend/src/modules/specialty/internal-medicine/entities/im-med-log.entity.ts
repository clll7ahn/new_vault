import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ImMedication } from './im-medication.entity';

export enum MedLogStatus {
  TAKEN = 'taken',
  SKIPPED = 'skipped',
  LATE = 'late',
}

@Entity('im_med_logs')
export class ImMedLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'medication_id' })
  medicationId: string;

  @ManyToOne(() => ImMedication, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'medication_id' })
  medication: ImMedication;

  @Column({ type: 'enum', enum: MedLogStatus })
  status: MedLogStatus;

  @Column({ name: 'taken_at', type: 'timestamptz' })
  takenAt: Date;
}

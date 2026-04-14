import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum PredictionType {
  NO_SHOW = 'no_show',
  PEAK_TIME = 'peak_time',
  PATIENT_CHURN = 'patient_churn',
}

@Entity('predictions')
export class Prediction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: PredictionType })
  type: PredictionType;

  @Column({ name: 'target_id', type: 'uuid', nullable: true })
  targetId: string | null;

  @Column({ type: 'decimal', precision: 5, scale: 4 })
  probability: number;

  @Column({ type: 'jsonb' })
  factors: Record<string, unknown>;

  @Column({ name: 'predicted_for', type: 'date' })
  predictedFor: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

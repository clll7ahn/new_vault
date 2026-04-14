import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum AllergySeverity {
  MILD = 'mild',
  MODERATE = 'moderate',
  SEVERE = 'severe',
}

@Entity('ent_allergy_records')
export class EntAllergyRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'varchar' })
  allergen: string;

  @Column({ name: 'reaction_type', type: 'varchar' })
  reactionType: string;

  @Column({ type: 'enum', enum: AllergySeverity })
  severity: AllergySeverity;

  @Column({ name: 'diagnosed_at', type: 'date' })
  diagnosedAt: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}

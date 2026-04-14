import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('psy_med_reactions')
export class PsyMedReaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'varchar' })
  medication: string;

  @Column({ name: 'mood_before', type: 'int' })
  moodBefore: number;

  @Column({ name: 'mood_after', type: 'int' })
  moodAfter: number;

  @Column({ name: 'side_effects', type: 'text', nullable: true })
  sideEffects: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}

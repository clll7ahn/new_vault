import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Mission } from './mission.entity';

export enum UserMissionStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  EXPIRED = 'expired',
}

export interface MissionProgress {
  current: number;
  target: number;
}

@Entity('user_missions')
export class UserMission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'mission_id' })
  missionId: string;

  @ManyToOne(() => Mission, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'mission_id' })
  mission: Mission;

  @Column({ type: 'jsonb' })
  progress: MissionProgress;

  @Column({ type: 'enum', enum: UserMissionStatus, default: UserMissionStatus.ACTIVE })
  status: UserMissionStatus;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

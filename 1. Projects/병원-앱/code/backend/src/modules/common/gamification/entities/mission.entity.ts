import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Badge } from './badge.entity';

export enum MissionType {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  ACHIEVEMENT = 'achievement',
}

export interface MissionCondition {
  type: 'steps' | 'medication' | 'checkin' | 'quiz';
  target: number;
}

@Entity('missions')
export class Mission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'enum', enum: MissionType })
  type: MissionType;

  @Column({ type: 'jsonb' })
  condition: MissionCondition;

  @Column({ type: 'int' })
  points: number;

  @Column({ name: 'badge_id', nullable: true })
  badgeId: string | null;

  @ManyToOne(() => Badge, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'badge_id' })
  badge: Badge | null;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';

export enum PointType {
  EARN = 'earn',
  SPEND = 'spend',
}

export type PointSource = 'mission' | 'checkin' | 'quiz' | 'redeem';

@Entity('point_ledger')
export class PointLedger {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'int' })
  amount: number;

  @Column({ type: 'enum', enum: PointType })
  type: PointType;

  @Column({ length: 50 })
  source: PointSource;

  @Column({ length: 200, nullable: true })
  description: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

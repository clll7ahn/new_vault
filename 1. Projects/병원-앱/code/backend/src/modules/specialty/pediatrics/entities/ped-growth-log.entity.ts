import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PedChild } from './ped-child.entity';

@Entity('ped_growth_logs')
export class PedGrowthLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'child_id' })
  childId: string;

  @ManyToOne(() => PedChild, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'child_id' })
  child: PedChild;

  @Column({ type: 'decimal', precision: 5, scale: 2 })
  height: number;

  @Column({ type: 'decimal', precision: 5, scale: 2 })
  weight: number;

  @Column({ name: 'head_circ', type: 'decimal', precision: 5, scale: 2, nullable: true })
  headCirc: number | null;

  @Column({ name: 'measured_at', type: 'timestamptz' })
  measuredAt: Date;
}

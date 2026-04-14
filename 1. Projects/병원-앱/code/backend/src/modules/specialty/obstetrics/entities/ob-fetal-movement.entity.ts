import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ObPregnancy } from './ob-pregnancy.entity';

@Entity('ob_fetal_movements')
export class ObFetalMovement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pregnancy_id' })
  pregnancyId: string;

  @ManyToOne(() => ObPregnancy, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pregnancy_id' })
  pregnancy: ObPregnancy;

  @Column({ type: 'int' })
  count: number;

  @Column({ name: 'duration_min', type: 'int' })
  durationMin: number;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}

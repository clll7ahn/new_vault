import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ObPregnancy } from './ob-pregnancy.entity';

@Entity('ob_checkups')
export class ObCheckup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'pregnancy_id' })
  pregnancyId: string;

  @ManyToOne(() => ObPregnancy, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'pregnancy_id' })
  pregnancy: ObPregnancy;

  @Column({ type: 'int' })
  week: number;

  @Column({ type: 'varchar' })
  type: string;

  @Column({ type: 'jsonb' })
  results: Record<string, unknown>;

  @Column({ name: 'ultrasound_url', type: 'varchar', nullable: true })
  ultrasoundUrl: string | null;

  @Column({ name: 'checked_at', type: 'timestamptz' })
  checkedAt: Date;
}

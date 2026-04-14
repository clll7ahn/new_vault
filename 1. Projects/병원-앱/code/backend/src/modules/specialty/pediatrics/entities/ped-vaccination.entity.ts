import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { PedChild } from './ped-child.entity';

@Entity('ped_vaccinations')
export class PedVaccination {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'child_id' })
  childId: string;

  @ManyToOne(() => PedChild, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'child_id' })
  child: PedChild;

  @Column({ name: 'vaccine_name', type: 'varchar' })
  vaccineName: string;

  @Column({ name: 'dose_number', type: 'int' })
  doseNumber: number;

  @Column({ name: 'scheduled_date', type: 'date' })
  scheduledDate: string;

  @Column({ name: 'actual_date', type: 'date', nullable: true })
  actualDate: string | null;

  @Column({
    type: 'enum',
    enum: ['scheduled', 'completed', 'overdue', 'skipped'],
    default: 'scheduled',
  })
  status: 'scheduled' | 'completed' | 'overdue' | 'skipped';
}

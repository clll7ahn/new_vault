import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('dent_tooth_chart')
export class DentToothChart {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'tooth_number', type: 'int' })
  toothNumber: number;

  @Column({
    type: 'enum',
    enum: ['healthy', 'cavity', 'treated', 'extracted', 'implant'],
    default: 'healthy',
  })
  status: 'healthy' | 'cavity' | 'treated' | 'extracted' | 'implant';

  @Column({ type: 'jsonb', nullable: true })
  conditions: Record<string, unknown> | null;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}

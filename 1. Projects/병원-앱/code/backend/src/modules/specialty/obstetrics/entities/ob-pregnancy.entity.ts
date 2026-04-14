import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum PregnancyStatus {
  ACTIVE = 'active',
  DELIVERED = 'delivered',
  LOSS = 'loss',
}

@Entity('ob_pregnancies')
export class ObPregnancy {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'due_date', type: 'date' })
  dueDate: string;

  @Column({ name: 'lmp_date', type: 'date' })
  lmpDate: string;

  @Column({
    type: 'enum',
    enum: PregnancyStatus,
    default: PregnancyStatus.ACTIVE,
  })
  status: PregnancyStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

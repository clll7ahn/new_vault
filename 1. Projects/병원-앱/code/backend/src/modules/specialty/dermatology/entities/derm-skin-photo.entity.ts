import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('derm_skin_photos')
export class DermSkinPhoto {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'body_area', type: 'varchar' })
  bodyArea: string;

  @Column({ name: 'image_url', type: 'varchar' })
  imageUrl: string;

  @Column({ name: 'ai_result', type: 'jsonb', nullable: true })
  aiResult: Record<string, unknown> | null;

  @Column({ type: 'int', nullable: true })
  score: number | null;

  @Column({ name: 'taken_at', type: 'timestamptz' })
  takenAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

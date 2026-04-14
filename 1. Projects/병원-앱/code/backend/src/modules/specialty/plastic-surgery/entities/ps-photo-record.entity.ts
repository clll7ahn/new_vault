import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { PsProcedure } from './ps-procedure.entity';

export enum PsPhotoType {
  BEFORE = 'before',
  DURING = 'during',
  AFTER = 'after',
  FOLLOW_UP = 'follow_up',
}

@Entity('ps_photo_records')
export class PsPhotoRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'procedure_id' })
  procedureId: string;

  @ManyToOne(() => PsProcedure, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'procedure_id' })
  procedure: PsProcedure;

  @Column({ name: 'photo_type', type: 'enum', enum: PsPhotoType })
  photoType: PsPhotoType;

  @Column({ name: 'image_url', type: 'varchar' })
  imageUrl: string;

  @Column({ name: 'taken_at', type: 'timestamptz' })
  takenAt: Date;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

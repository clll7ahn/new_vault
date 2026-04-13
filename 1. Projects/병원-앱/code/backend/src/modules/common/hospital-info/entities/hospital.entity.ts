import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
} from 'typeorm';

@Entity('hospitals')
export class Hospital {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 255 })
  name: string;

  @Column({ length: 500 })
  address: string;

  @Column({ length: 20 })
  phone: string;

  @Column({ name: 'registration_number', unique: true, length: 50 })
  registrationNumber: string;

  @Column({ name: 'operating_hours', type: 'jsonb', nullable: true })
  operatingHours: Record<string, { open: string; close: string }> | null;

  @Column({ name: 'logo_url', nullable: true, length: 500 })
  logoUrl: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  latitude: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  longitude: number | null;

  @Column({ name: 'terms_of_service', type: 'text', nullable: true })
  termsOfService: string | null;

  @Column({ name: 'privacy_policy', type: 'text', nullable: true })
  privacyPolicy: string | null;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}

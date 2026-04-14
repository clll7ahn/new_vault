import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Department } from './department.entity';
import { User } from '../../auth/entities/user.entity';

@Entity('doctors')
export class Doctor {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', nullable: true })
  userId: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'user_id' })
  user: User | null;

  @Column({ name: 'department_id' })
  departmentId: string;

  @ManyToOne(() => Department, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'department_id' })
  department: Department;

  @Column({ length: 100 })
  name: string;

  @Column({ name: 'license_number', unique: true, length: 50 })
  licenseNumber: string;

  @Column({ name: 'license_issued_date', type: 'date', nullable: true })
  licenseIssuedDate: Date | null;

  @Column({ name: 'years_of_experience', type: 'int', default: 0 })
  yearsOfExperience: number;

  @Column({ length: 100, nullable: true })
  specialty: string | null;

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  @Column({ name: 'profile_image_url', nullable: true, length: 500 })
  profileImageUrl: string | null;

  @Column({ name: 'is_available', default: true })
  isAvailable: boolean;

  @Column({ name: 'display_order', default: 0 })
  displayOrder: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

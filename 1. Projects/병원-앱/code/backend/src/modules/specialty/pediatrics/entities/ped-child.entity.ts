import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('ped_children')
export class PedChild {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'parent_id' })
  parentId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'parent_id' })
  parent: User;

  @Column({ type: 'varchar' })
  name: string;

  @Column({ name: 'birth_date', type: 'date' })
  birthDate: string;

  @Column({ type: 'enum', enum: ['male', 'female'] })
  gender: 'male' | 'female';

  @Column({ name: 'blood_type', type: 'varchar', nullable: true })
  bloodType: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

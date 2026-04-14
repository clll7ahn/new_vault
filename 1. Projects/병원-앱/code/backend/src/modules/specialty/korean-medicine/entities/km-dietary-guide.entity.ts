import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { KmConstitution } from './km-constitution.entity';

@Entity('km_dietary_guides')
export class KmDietaryGuide {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'constitution_id' })
  constitutionId: string;

  @ManyToOne(() => KmConstitution, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'constitution_id' })
  constitution: KmConstitution;

  @Column({ name: 'recommended_foods', type: 'text', array: true })
  recommendedFoods: string[];

  @Column({ name: 'avoided_foods', type: 'text', array: true })
  avoidedFoods: string[];

  @Column({ name: 'lifestyle_tips', type: 'text', array: true })
  lifestyleTips: string[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

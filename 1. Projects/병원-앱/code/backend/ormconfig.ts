import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'hospital',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_DATABASE || 'hospital_app',
  entities: ['src/**/*.entity{.ts,.js}'],
  migrations: ['database/migrations/*.{ts,js}'],
  synchronize: process.env.NODE_ENV !== 'production',
  logging: process.env.NODE_ENV === 'development',
  dropSchema: false,
  migrationsRun: true,
});

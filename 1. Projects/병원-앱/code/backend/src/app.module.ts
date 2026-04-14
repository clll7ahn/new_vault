import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import databaseConfig from './config/database.config';
import jwtConfig from './config/jwt.config';
import { AuthModule } from './modules/common/auth/auth.module';
import { HospitalInfoModule } from './modules/common/hospital-info/hospital-info.module';
import { AppointmentModule } from './modules/common/appointment/appointment.module';
import { QueueModule } from './modules/common/queue/queue.module';
import { NotificationModule } from './modules/common/notification/notification.module';
import { ChatbotModule } from './modules/common/chatbot/chatbot.module';
import { GamificationModule } from './modules/common/gamification/gamification.module';
import { HealthTrackerModule } from './modules/common/health-tracker/health-tracker.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, jwtConfig],
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) =>
        configService.get('database')!,
    }),
    AuthModule,
    HospitalInfoModule,
    AppointmentModule,
    QueueModule,
    NotificationModule,
    ChatbotModule,
    GamificationModule,
    HealthTrackerModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

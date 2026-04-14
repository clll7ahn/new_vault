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
import { InternalMedicineModule } from './modules/specialty/internal-medicine/internal-medicine.module';
import { DermatologyModule } from './modules/specialty/dermatology/dermatology.module';
import { OrthopedicsModule } from './modules/specialty/orthopedics/orthopedics.module';
import { PediatricsModule } from './modules/specialty/pediatrics/pediatrics.module';
import { OphthalmologyModule } from './modules/specialty/ophthalmology/ophthalmology.module';
import { DentalModule } from './modules/specialty/dental/dental.module';
import { ObstetricsModule } from './modules/specialty/obstetrics/obstetrics.module';
import { PsychiatryModule } from './modules/specialty/psychiatry/psychiatry.module';
import { EntModule } from './modules/specialty/ent/ent.module';
import { FamilyMedicineModule } from './modules/specialty/family-medicine/family-medicine.module';
import { UrologyModule } from './modules/specialty/urology/urology.module';
import { NeurologyModule } from './modules/specialty/neurology/neurology.module';
import { PlasticSurgeryModule } from './modules/specialty/plastic-surgery/plastic-surgery.module';
import { KoreanMedicineModule } from './modules/specialty/korean-medicine/korean-medicine.module';
import { RehabilitationModule } from './modules/specialty/rehabilitation/rehabilitation.module';
import { AnalyticsModule } from './modules/common/analytics/analytics.module';
import { TenantModule } from './common/tenant/tenant.module';

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
    TenantModule,
    AuthModule,
    HospitalInfoModule,
    AppointmentModule,
    QueueModule,
    NotificationModule,
    ChatbotModule,
    GamificationModule,
    HealthTrackerModule,
    AnalyticsModule,
    InternalMedicineModule.forRoot(),
    DermatologyModule,
    OrthopedicsModule,
    PediatricsModule,
    OphthalmologyModule,
    DentalModule,
    ObstetricsModule,
    PsychiatryModule,
    EntModule,
    FamilyMedicineModule,
    UrologyModule,
    NeurologyModule,
    PlasticSurgeryModule,
    KoreanMedicineModule,
    RehabilitationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

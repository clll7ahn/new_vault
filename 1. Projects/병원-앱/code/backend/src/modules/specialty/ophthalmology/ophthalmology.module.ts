import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OphVisionLog } from './entities/oph-vision-log.entity';
import { OphPrescription } from './entities/oph-prescription.entity';
import { OphEyeDrop } from './entities/oph-eye-drop.entity';
import { OphthalmologyService } from './ophthalmology.service';
import { OphthalmologyController } from './ophthalmology.controller';

@Module({
  imports: [TypeOrmModule.forFeature([OphVisionLog, OphPrescription, OphEyeDrop])],
  controllers: [OphthalmologyController],
  providers: [OphthalmologyService],
  exports: [OphthalmologyService],
})
export class OphthalmologyModule {}

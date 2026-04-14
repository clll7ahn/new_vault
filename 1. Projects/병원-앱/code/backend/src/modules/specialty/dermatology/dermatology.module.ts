import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DermSkinPhoto } from './entities/derm-skin-photo.entity';
import { DermTreatment } from './entities/derm-treatment.entity';
import { DermatologyService } from './dermatology.service';
import { DermatologyController } from './dermatology.controller';

@Module({
  imports: [TypeOrmModule.forFeature([DermSkinPhoto, DermTreatment])],
  controllers: [DermatologyController],
  providers: [DermatologyService],
  exports: [DermatologyService],
})
export class DermatologyModule {}

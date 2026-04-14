import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ObPregnancy } from './entities/ob-pregnancy.entity';
import { ObCheckup } from './entities/ob-checkup.entity';
import { ObFetalMovement } from './entities/ob-fetal-movement.entity';
import { ObMaternalLog } from './entities/ob-maternal-log.entity';
import { ObstetricsService } from './obstetrics.service';
import { ObstetricsController } from './obstetrics.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([ObPregnancy, ObCheckup, ObFetalMovement, ObMaternalLog]),
  ],
  controllers: [ObstetricsController],
  providers: [ObstetricsService],
  exports: [ObstetricsService],
})
export class ObstetricsModule {}

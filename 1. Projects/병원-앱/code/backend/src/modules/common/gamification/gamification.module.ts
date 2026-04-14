import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Mission } from './entities/mission.entity';
import { UserMission } from './entities/user-mission.entity';
import { PointLedger } from './entities/point-ledger.entity';
import { Badge } from './entities/badge.entity';
import { UserBadge } from './entities/user-badge.entity';
import { GamificationService } from './gamification.service';
import { GamificationController } from './gamification.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Mission, UserMission, PointLedger, Badge, UserBadge]),
  ],
  controllers: [GamificationController],
  providers: [GamificationService],
  exports: [GamificationService],
})
export class GamificationModule {}

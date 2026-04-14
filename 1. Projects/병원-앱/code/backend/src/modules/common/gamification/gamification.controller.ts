import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { GamificationService } from './gamification.service';
import { CreateMissionDto } from './dto/create-mission.dto';
import { UpdateMissionProgressDto } from './dto/update-mission-progress.dto';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { SpendPointsDto } from './dto/spend-points.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { MissionType } from './entities/mission.entity';

@Controller('api/v1/gamification')
@UseGuards(JwtAuthGuard)
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Get('missions')
  getMissions(@Query('type') type?: MissionType) {
    return this.gamificationService.getMissions(type);
  }

  @Get('my-missions')
  getMyMissions(@CurrentUser('id') userId: string) {
    return this.gamificationService.getMyMissions(userId);
  }

  @Patch('missions/:id/progress')
  updateProgress(
    @CurrentUser('id') userId: string,
    @Param('id', ParseUUIDPipe) missionId: string,
    @Body() dto: UpdateMissionProgressDto,
  ) {
    return this.gamificationService.updateProgress(userId, missionId, dto);
  }

  @Post('check-in')
  dailyCheckIn(@CurrentUser('id') userId: string) {
    return this.gamificationService.dailyCheckIn(userId);
  }

  @Get('points')
  getPointBalance(@CurrentUser('id') userId: string) {
    return this.gamificationService.getPointBalance(userId);
  }

  @Get('points/history')
  getPointHistory(
    @CurrentUser('id') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.gamificationService.getPointHistory(userId, page, limit);
  }

  @Post('points/spend')
  spendPoints(@CurrentUser('id') userId: string, @Body() dto: SpendPointsDto) {
    return this.gamificationService.spendPoints(userId, dto);
  }

  @Get('badges')
  getBadges() {
    return this.gamificationService.getBadges();
  }

  @Get('my-badges')
  getMyBadges(@CurrentUser('id') userId: string) {
    return this.gamificationService.getMyBadges(userId);
  }

  @Post('missions')
  @UseGuards(RolesGuard)
  @Roles('admin')
  createMission(@Body() dto: CreateMissionDto) {
    return this.gamificationService.createMission(dto);
  }

  @Post('badges')
  @UseGuards(RolesGuard)
  @Roles('admin')
  createBadge(@Body() dto: CreateBadgeDto) {
    return this.gamificationService.createBadge(dto);
  }
}

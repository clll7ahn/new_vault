import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual } from 'typeorm';
import { Mission, MissionType } from './entities/mission.entity';
import { UserMission, UserMissionStatus } from './entities/user-mission.entity';
import { PointLedger, PointType } from './entities/point-ledger.entity';
import { Badge } from './entities/badge.entity';
import { UserBadge } from './entities/user-badge.entity';
import { CreateMissionDto } from './dto/create-mission.dto';
import { UpdateMissionProgressDto } from './dto/update-mission-progress.dto';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { SpendPointsDto } from './dto/spend-points.dto';

@Injectable()
export class GamificationService {
  constructor(
    @InjectRepository(Mission)
    private readonly missionRepo: Repository<Mission>,
    @InjectRepository(UserMission)
    private readonly userMissionRepo: Repository<UserMission>,
    @InjectRepository(PointLedger)
    private readonly pointLedgerRepo: Repository<PointLedger>,
    @InjectRepository(Badge)
    private readonly badgeRepo: Repository<Badge>,
    @InjectRepository(UserBadge)
    private readonly userBadgeRepo: Repository<UserBadge>,
  ) {}

  async getMissions(type?: MissionType): Promise<Mission[]> {
    const where: Partial<Mission> = { isActive: true };
    if (type) where.type = type;
    return this.missionRepo.find({ where, relations: ['badge'], order: { createdAt: 'ASC' } });
  }

  async getMyMissions(userId: string): Promise<UserMission[]> {
    return this.userMissionRepo.find({
      where: { userId },
      relations: ['mission', 'mission.badge'],
      order: { createdAt: 'DESC' },
    });
  }

  async updateProgress(
    userId: string,
    missionId: string,
    dto: UpdateMissionProgressDto,
  ): Promise<UserMission> {
    const userMission = await this.userMissionRepo.findOne({
      where: { userId, missionId, status: UserMissionStatus.ACTIVE },
      relations: ['mission'],
    });
    if (!userMission) throw new NotFoundException('Active user mission not found');

    userMission.progress = {
      current: dto.current,
      target: userMission.mission.condition.target,
    };

    if (dto.current >= userMission.mission.condition.target) {
      userMission.status = UserMissionStatus.COMPLETED;
      userMission.completedAt = new Date();
      await this.earnPoints(
        userId,
        userMission.mission.points,
        'mission',
        `Mission completed: ${userMission.mission.title}`,
      );
      if (userMission.mission.badgeId) {
        await this.awardBadge(userId, userMission.mission.badgeId);
      }
    }

    return this.userMissionRepo.save(userMission);
  }

  async dailyCheckIn(userId: string): Promise<PointLedger> {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const existing = await this.pointLedgerRepo.findOne({
      where: {
        userId,
        source: 'checkin',
        createdAt: MoreThanOrEqual(todayStart),
      },
    });
    if (existing) throw new ConflictException('Already checked in today');

    return this.earnPoints(userId, 10, 'checkin', 'Daily check-in');
  }

  async getPointBalance(userId: string): Promise<{ balance: number }> {
    const records = await this.pointLedgerRepo.find({ where: { userId } });
    const balance = records.reduce((sum, r) => {
      return r.type === PointType.EARN ? sum + r.amount : sum - r.amount;
    }, 0);
    return { balance };
  }

  async getPointHistory(
    userId: string,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ data: PointLedger[]; total: number; page: number; limit: number }> {
    const [data, total] = await this.pointLedgerRepo.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, total, page, limit };
  }

  async spendPoints(userId: string, dto: SpendPointsDto): Promise<PointLedger> {
    const { balance } = await this.getPointBalance(userId);
    if (balance < dto.amount) throw new BadRequestException('Insufficient points');

    const entry = this.pointLedgerRepo.create({
      userId,
      amount: dto.amount,
      type: PointType.SPEND,
      source: 'redeem',
      description: dto.description ?? null,
    });
    return this.pointLedgerRepo.save(entry);
  }

  async getMyBadges(userId: string): Promise<UserBadge[]> {
    return this.userBadgeRepo.find({
      where: { userId },
      relations: ['badge'],
      order: { earnedAt: 'DESC' },
    });
  }

  async getBadges(): Promise<{ badge: Badge; earned: boolean }[]> {
    const [allBadges, userBadges] = await Promise.all([
      this.badgeRepo.find({ order: { createdAt: 'ASC' } }),
      this.userBadgeRepo.find({ select: ['badgeId'] }),
    ]);
    const earnedIds = new Set(userBadges.map((ub) => ub.badgeId));
    return allBadges.map((badge) => ({ badge, earned: earnedIds.has(badge.id) }));
  }

  async awardBadge(userId: string, badgeId: string): Promise<UserBadge> {
    const badge = await this.badgeRepo.findOne({ where: { id: badgeId } });
    if (!badge) throw new NotFoundException('Badge not found');

    const existing = await this.userBadgeRepo.findOne({ where: { userId, badgeId } });
    if (existing) return existing;

    const userBadge = this.userBadgeRepo.create({ userId, badgeId, earnedAt: new Date() });
    return this.userBadgeRepo.save(userBadge);
  }

  async createMission(dto: CreateMissionDto): Promise<Mission> {
    const mission = this.missionRepo.create({
      title: dto.title,
      description: dto.description,
      type: dto.type,
      condition: dto.condition,
      points: dto.points,
      badgeId: dto.badgeId ?? null,
      isActive: dto.isActive ?? true,
    });
    return this.missionRepo.save(mission);
  }

  async createBadge(dto: CreateBadgeDto): Promise<Badge> {
    const badge = this.badgeRepo.create({
      name: dto.name,
      iconUrl: dto.iconUrl,
      description: dto.description,
      condition: dto.condition,
    });
    return this.badgeRepo.save(badge);
  }

  private async earnPoints(
    userId: string,
    amount: number,
    source: PointLedger['source'],
    description: string,
  ): Promise<PointLedger> {
    const entry = this.pointLedgerRepo.create({
      userId,
      amount,
      type: PointType.EARN,
      source,
      description,
    });
    return this.pointLedgerRepo.save(entry);
  }
}

import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';
import { CreateNotificationDto } from './dto/create-notification.dto';
import { SendBulkDto } from './dto/send-bulk.dto';

@Injectable()
export class NotificationService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
  ) {}

  async create(dto: CreateNotificationDto): Promise<Notification> {
    const notification = this.notificationRepo.create({
      userId: dto.userId,
      title: dto.title,
      body: dto.body,
      type: dto.type,
      data: dto.data ?? null,
    });
    return this.notificationRepo.save(notification);
  }

  async sendBulk(dto: SendBulkDto): Promise<Notification[]> {
    const notifications = dto.userIds.map((userId) =>
      this.notificationRepo.create({
        userId,
        title: dto.title,
        body: dto.body,
        type: dto.type,
        data: null,
      }),
    );
    return this.notificationRepo.save(notifications);
  }

  async getMyNotifications(
    userId: string,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ data: Notification[]; total: number; page: number; limit: number }> {
    const [data, total] = await this.notificationRepo.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    return { data, total, page, limit };
  }

  async markAsRead(id: string, userId: string): Promise<Notification> {
    const notification = await this.notificationRepo.findOne({ where: { id } });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    if (notification.userId !== userId) {
      throw new ForbiddenException('Access denied');
    }
    notification.isRead = true;
    return this.notificationRepo.save(notification);
  }

  async markAllAsRead(userId: string): Promise<{ affected: number }> {
    const result = await this.notificationRepo.update(
      { userId, isRead: false },
      { isRead: true },
    );
    return { affected: result.affected ?? 0 };
  }

  async getUnreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.notificationRepo.count({
      where: { userId, isRead: false },
    });
    return { count };
  }
}

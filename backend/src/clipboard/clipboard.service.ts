import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateClipboardDto } from './dto/create-clipboard.dto';

const TTL_HOURS = 24;

@Injectable()
export class ClipboardService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateClipboardDto) {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + TTL_HOURS);

    const item = await this.prisma.clipboardItem.create({
      data: {
        userId,
        content: dto.content,
        contentType: dto.contentType,
        sourceDevice: dto.sourceDevice,
        expiresAt,
      },
    });

    return item;
  }

  async getLatest(userId: string) {
    return this.prisma.clipboardItem.findFirst({
      where: {
        userId,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getHistory(userId: string) {
    return this.prisma.clipboardItem.findMany({
      where: {
        userId,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  async delete(userId: string, id: string) {
    return this.prisma.clipboardItem.deleteMany({
      where: { id, userId },
    });
  }

  async cleanExpired() {
    return this.prisma.clipboardItem.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });
  }
}

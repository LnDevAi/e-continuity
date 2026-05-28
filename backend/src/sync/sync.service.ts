import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSyncConfigDto } from './dto/sync-config.dto';

@Injectable()
export class SyncService {
  constructor(private prisma: PrismaService) {}

  async getConfig(userId: string) {
    return this.prisma.syncConfig.findUnique({ where: { userId } });
  }

  async updateConfig(userId: string, dto: UpdateSyncConfigDto) {
    return this.prisma.syncConfig.upsert({
      where: { userId },
      update: {
        syncedPaths: dto.syncedPaths,
        backupEnabled: dto.backupEnabled ?? true,
      },
      create: {
        userId,
        syncedPaths: dto.syncedPaths,
        backupEnabled: dto.backupEnabled ?? true,
      },
    });
  }

  async updateLastSync(userId: string) {
    return this.prisma.syncConfig.update({
      where: { userId },
      data: { lastSync: new Date() },
    });
  }

  async triggerSync(userId: string) {
    // Dans la production, envoie un signal via WebSocket à tous les appareils actifs
    // pour lancer la synchronisation des fichiers configurés
    await this.updateLastSync(userId);
    return {
      message: 'Synchronisation déclenchée',
      timestamp: new Date(),
    };
  }
}

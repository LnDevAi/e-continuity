import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(private prisma: PrismaService) {}

  async registerDevice(userId: string, dto: RegisterDeviceDto) {
    // Upsert : si le deviceToken existe déjà, on met à jour
    const device = await this.prisma.device.upsert({
      where: { deviceToken: dto.deviceToken },
      update: {
        name: dto.name,
        lastSeen: new Date(),
        isOnline: true,
        publicKey: dto.publicKey,
      },
      create: {
        userId,
        name: dto.name,
        type: dto.type,
        platform: dto.platform,
        deviceToken: dto.deviceToken,
        publicKey: dto.publicKey,
        isOnline: true,
      },
    });
    return device;
  }

  async getUserDevices(userId: string) {
    return this.prisma.device.findMany({
      where: { userId },
      orderBy: { lastSeen: 'desc' },
    });
  }

  async deleteDevice(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) throw new NotFoundException('Appareil non trouvé');
    if (device.userId !== userId) throw new ForbiddenException('Accès refusé');
    return this.prisma.device.delete({ where: { id: deviceId } });
  }

  async heartbeat(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) throw new NotFoundException('Appareil non trouvé');
    if (device.userId !== userId) throw new ForbiddenException('Accès refusé');
    return this.prisma.device.update({
      where: { id: deviceId },
      data: { lastSeen: new Date(), isOnline: true },
    });
  }

  async setOffline(deviceId: string) {
    return this.prisma.device.update({
      where: { id: deviceId },
      data: { isOnline: false },
    });
  }
}

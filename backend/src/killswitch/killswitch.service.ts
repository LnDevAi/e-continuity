import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { KillSwitchActionDto } from './dto/killswitch.dto';

@Injectable()
export class KillSwitchService {
  constructor(private prisma: PrismaService) {}

  async lock(userId: string, dto: KillSwitchActionDto) {
    await this.validateDeviceOwnership(userId, dto.targetDeviceId);

    const command = await this.prisma.killSwitchCommand.create({
      data: {
        userId,
        targetDeviceId: dto.targetDeviceId,
        action: 'lock',
        status: 'pending',
      },
    });

    // Mise à jour du statut de l'appareil
    await this.prisma.device.update({
      where: { id: dto.targetDeviceId },
      data: { killSwitchStatus: 'locked' },
    });

    return command;
  }

  async wipe(userId: string, dto: KillSwitchActionDto) {
    const device = await this.validateDeviceOwnership(userId, dto.targetDeviceId);

    if (device.killSwitchStatus === 'wiped') {
      throw new BadRequestException('Cet appareil a déjà été effacé');
    }

    const command = await this.prisma.killSwitchCommand.create({
      data: {
        userId,
        targetDeviceId: dto.targetDeviceId,
        action: 'wipe',
        status: 'pending',
      },
    });

    await this.prisma.device.update({
      where: { id: dto.targetDeviceId },
      data: { killSwitchStatus: 'wiped' },
    });

    return command;
  }

  async getStatus(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) throw new NotFoundException('Appareil non trouvé');
    if (device.userId !== userId) throw new ForbiddenException('Accès refusé');

    const latestCommand = await this.prisma.killSwitchCommand.findFirst({
      where: { targetDeviceId: deviceId, userId },
      orderBy: { issuedAt: 'desc' },
    });

    return {
      deviceId,
      killSwitchStatus: device.killSwitchStatus,
      latestCommand,
    };
  }

  async markExecuted(userId: string, commandId: string) {
    const command = await this.prisma.killSwitchCommand.findUnique({ where: { id: commandId } });
    if (!command) throw new NotFoundException('Commande non trouvée');
    if (command.userId !== userId) throw new ForbiddenException('Accès refusé');

    return this.prisma.killSwitchCommand.update({
      where: { id: commandId },
      data: { status: 'executed', executedAt: new Date() },
    });
  }

  private async validateDeviceOwnership(userId: string, deviceId: string) {
    const device = await this.prisma.device.findUnique({ where: { id: deviceId } });
    if (!device) throw new NotFoundException('Appareil non trouvé');
    if (device.userId !== userId) throw new ForbiddenException('Accès refusé');
    return device;
  }
}

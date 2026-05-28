import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { KillSwitchService } from './killswitch.service';
import { PrismaService } from '../prisma/prisma.service';

const mockPrisma = {
  device: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  killSwitchCommand: {
    create: jest.fn(),
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
  },
};

const baseDevice = {
  id: 'd1',
  userId: 'u1',
  name: 'Mon PC',
  killSwitchStatus: 'active',
};

describe('KillSwitchService', () => {
  let service: KillSwitchService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        KillSwitchService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<KillSwitchService>(KillSwitchService);
  });

  describe('lock', () => {
    it('throw NotFoundException si appareil introuvable', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(null);
      await expect(service.lock('u1', { targetDeviceId: 'd1' })).rejects.toThrow(NotFoundException);
    });

    it('throw ForbiddenException si appareil appartient à un autre utilisateur', async () => {
      mockPrisma.device.findUnique.mockResolvedValue({ ...baseDevice, userId: 'u2' });
      await expect(service.lock('u1', { targetDeviceId: 'd1' })).rejects.toThrow(ForbiddenException);
    });

    it('crée commande lock et met à jour statut device', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(baseDevice);
      const mockCommand = { id: 'cmd1', action: 'lock', status: 'pending' };
      mockPrisma.killSwitchCommand.create.mockResolvedValue(mockCommand);
      mockPrisma.device.update.mockResolvedValue({ ...baseDevice, killSwitchStatus: 'locked' });

      const result = await service.lock('u1', { targetDeviceId: 'd1' });

      expect(mockPrisma.killSwitchCommand.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ action: 'lock', status: 'pending' }) }),
      );
      expect(mockPrisma.device.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { killSwitchStatus: 'locked' } }),
      );
      expect(result).toEqual(mockCommand);
    });
  });

  describe('wipe', () => {
    it('throw BadRequestException si appareil déjà effacé', async () => {
      mockPrisma.device.findUnique.mockResolvedValue({ ...baseDevice, killSwitchStatus: 'wiped' });
      await expect(service.wipe('u1', { targetDeviceId: 'd1' })).rejects.toThrow(BadRequestException);
    });

    it('crée commande wipe et met à jour statut', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(baseDevice);
      const mockCommand = { id: 'cmd2', action: 'wipe', status: 'pending' };
      mockPrisma.killSwitchCommand.create.mockResolvedValue(mockCommand);
      mockPrisma.device.update.mockResolvedValue({ ...baseDevice, killSwitchStatus: 'wiped' });

      const result = await service.wipe('u1', { targetDeviceId: 'd1' });

      expect(mockPrisma.device.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { killSwitchStatus: 'wiped' } }),
      );
      expect(result.action).toBe('wipe');
    });
  });

  describe('getStatus', () => {
    it('throw NotFoundException si device introuvable', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(null);
      await expect(service.getStatus('u1', 'd1')).rejects.toThrow(NotFoundException);
    });

    it('throw ForbiddenException si mauvais propriétaire', async () => {
      mockPrisma.device.findUnique.mockResolvedValue({ ...baseDevice, userId: 'u99' });
      await expect(service.getStatus('u1', 'd1')).rejects.toThrow(ForbiddenException);
    });

    it('retourne statut et dernière commande', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(baseDevice);
      const cmd = { id: 'cmd1', action: 'lock', status: 'executed' };
      mockPrisma.killSwitchCommand.findFirst.mockResolvedValue(cmd);

      const result = await service.getStatus('u1', 'd1');
      expect(result.killSwitchStatus).toBe('active');
      expect(result.latestCommand).toEqual(cmd);
    });
  });

  describe('markExecuted', () => {
    it('throw NotFoundException si commande introuvable', async () => {
      mockPrisma.killSwitchCommand.findUnique.mockResolvedValue(null);
      await expect(service.markExecuted('u1', 'cmd99')).rejects.toThrow(NotFoundException);
    });

    it('throw ForbiddenException si mauvais propriétaire', async () => {
      mockPrisma.killSwitchCommand.findUnique.mockResolvedValue({ id: 'cmd1', userId: 'u99' });
      await expect(service.markExecuted('u1', 'cmd1')).rejects.toThrow(ForbiddenException);
    });

    it('marque la commande comme exécutée', async () => {
      mockPrisma.killSwitchCommand.findUnique.mockResolvedValue({ id: 'cmd1', userId: 'u1' });
      const updated = { id: 'cmd1', status: 'executed', executedAt: new Date() };
      mockPrisma.killSwitchCommand.update.mockResolvedValue(updated);

      const result = await service.markExecuted('u1', 'cmd1');
      expect(result.status).toBe('executed');
    });
  });
});

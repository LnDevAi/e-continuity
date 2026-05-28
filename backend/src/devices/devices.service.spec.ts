import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { PrismaService } from '../prisma/prisma.service';

const mockPrisma = {
  device: {
    upsert: jest.fn(),
    findMany: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
};

const baseDevice = {
  id: 'd1', userId: 'u1', name: 'PC Bureau',
  type: 'desktop', platform: 'windows',
  deviceToken: 'tok123', publicKey: 'pub', isOnline: true,
  killSwitchStatus: 'active', lastSeen: new Date(),
};

describe('DevicesService', () => {
  let service: DevicesService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DevicesService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<DevicesService>(DevicesService);
  });

  describe('registerDevice', () => {
    it('upsert par deviceToken (créer ou mettre à jour)', async () => {
      mockPrisma.device.upsert.mockResolvedValue(baseDevice);

      const result = await service.registerDevice('u1', {
        name: 'PC Bureau', type: 'desktop', platform: 'windows',
        deviceToken: 'tok123', publicKey: 'pub',
      });

      expect(mockPrisma.device.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { deviceToken: 'tok123' } }),
      );
      expect(result.id).toBe('d1');
    });
  });

  describe('getUserDevices', () => {
    it('retourne les appareils triés par lastSeen', async () => {
      mockPrisma.device.findMany.mockResolvedValue([baseDevice]);

      const result = await service.getUserDevices('u1');
      expect(mockPrisma.device.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'u1' }, orderBy: { lastSeen: 'desc' } }),
      );
      expect(result).toHaveLength(1);
    });
  });

  describe('deleteDevice', () => {
    it('throw NotFoundException si appareil introuvable', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(null);
      await expect(service.deleteDevice('u1', 'd1')).rejects.toThrow(NotFoundException);
    });

    it('throw ForbiddenException si mauvais propriétaire', async () => {
      mockPrisma.device.findUnique.mockResolvedValue({ ...baseDevice, userId: 'u99' });
      await expect(service.deleteDevice('u1', 'd1')).rejects.toThrow(ForbiddenException);
    });

    it('supprime l\'appareil si propriétaire valide', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(baseDevice);
      mockPrisma.device.delete.mockResolvedValue(baseDevice);

      const result = await service.deleteDevice('u1', 'd1');
      expect(mockPrisma.device.delete).toHaveBeenCalledWith({ where: { id: 'd1' } });
      expect(result.id).toBe('d1');
    });
  });

  describe('heartbeat', () => {
    it('throw NotFoundException si appareil introuvable', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(null);
      await expect(service.heartbeat('u1', 'd1')).rejects.toThrow(NotFoundException);
    });

    it('throw ForbiddenException si mauvais propriétaire', async () => {
      mockPrisma.device.findUnique.mockResolvedValue({ ...baseDevice, userId: 'u99' });
      await expect(service.heartbeat('u1', 'd1')).rejects.toThrow(ForbiddenException);
    });

    it('met à jour lastSeen et isOnline=true', async () => {
      mockPrisma.device.findUnique.mockResolvedValue(baseDevice);
      const updated = { ...baseDevice, lastSeen: new Date(), isOnline: true };
      mockPrisma.device.update.mockResolvedValue(updated);

      const result = await service.heartbeat('u1', 'd1');
      expect(mockPrisma.device.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ isOnline: true }) }),
      );
      expect(result.isOnline).toBe(true);
    });
  });
});

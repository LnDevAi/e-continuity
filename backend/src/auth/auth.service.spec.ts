import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

jest.mock('bcrypt');

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
};

const mockJwt = {
  sign: jest.fn().mockReturnValue('mock_token'),
};

describe('AuthService (e-continuity)', () => {
  let service: AuthService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwt },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('register', () => {
    it('throw ConflictException si email existe', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'u1' });
      await expect(
        service.register({ email: 'x@x.com', password: 'p', firstName: 'A', lastName: 'B' }),
      ).rejects.toThrow(ConflictException);
    });

    it('crée user, retourne publicKey et privateKey (une seule fois)', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed');
      const createdUser = { id: 'u1', email: 'a@b.com', firstName: 'A', lastName: 'B', publicKey: 'pubkey_b64' };
      mockPrisma.user.create.mockResolvedValue(createdUser);

      const result = await service.register({ email: 'a@b.com', password: 'secret', firstName: 'A', lastName: 'B' });

      expect(result).toHaveProperty('privateKey');
      expect(result).toHaveProperty('accessToken');
      expect(result.user.email).toBe('a@b.com');
      // publicKey stockée, privateKey retournée une fois seulement
      expect(mockPrisma.user.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ publicKey: expect.any(String) }) }),
      );
    });
  });

  describe('login', () => {
    it('throw UnauthorizedException si user introuvable', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      await expect(service.login({ email: 'x@x.com', password: 'p' })).rejects.toThrow(UnauthorizedException);
    });

    it('throw UnauthorizedException si mot de passe invalide', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'u1', password: 'hashed' });
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);
      await expect(service.login({ email: 'a@b.com', password: 'wrong' })).rejects.toThrow(UnauthorizedException);
    });

    it('retourne user et tokens si identifiants valides', async () => {
      const user = { id: 'u1', email: 'a@b.com', firstName: 'A', lastName: 'B', publicKey: 'pub', password: 'hashed' };
      mockPrisma.user.findUnique.mockResolvedValue(user);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.login({ email: 'a@b.com', password: 'secret' });
      expect(result).toHaveProperty('accessToken');
      expect(result.user.publicKey).toBe('pub');
    });
  });
});

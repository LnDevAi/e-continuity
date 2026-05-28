import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email déjà utilisé');

    const hashedPassword = await bcrypt.hash(dto.password, 12);

    // Génération d'une paire de clés simulée (dans un vrai projet, générée côté client Libsodium)
    const { publicKey, privateKey } = this.generateKeyPair();

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password: hashedPassword,
        firstName: dto.firstName,
        lastName: dto.lastName,
        publicKey,
      },
    });

    const tokens = this.generateTokens(user.id, user.email);

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        publicKey: user.publicKey,
      },
      // La clé privée n'est retournée qu'une seule fois — l'utilisateur doit la sauvegarder
      privateKey,
      ...tokens,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new UnauthorizedException('Identifiants invalides');

    const valid = await bcrypt.compare(dto.password, user.password);
    if (!valid) throw new UnauthorizedException('Identifiants invalides');

    const tokens = this.generateTokens(user.id, user.email);

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        publicKey: user.publicKey,
      },
      ...tokens,
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        publicKey: true,
        createdAt: true,
        _count: { select: { devices: true } },
      },
    });
    return user;
  }

  private generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };
    return {
      accessToken: this.jwtService.sign(payload, { expiresIn: '1h' }),
      refreshToken: this.jwtService.sign(payload, { expiresIn: '7d' }),
    };
  }

  private generateKeyPair() {
    // Simulation d'une paire de clés Libsodium (Base64)
    // Dans la production, la génération est faite côté client
    const randomBytes = (n: number) =>
      Buffer.from(Array.from({ length: n }, () => Math.floor(Math.random() * 256))).toString('base64');
    return {
      publicKey: randomBytes(32),
      privateKey: randomBytes(64),
    };
  }
}

import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async validateUser(username: string, pass: string): Promise<any> {
    const user = await this.prisma.user.findFirst({
      where: { username, deletedAt: null },
    });
    if (user && (await bcrypt.compare(pass, user.passwordHash))) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { username: user.username, sub: user.id, role: user.role };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(
      { sub: user.id },
      { expiresIn: '7d' },
    );

    // Save refresh token hash in db
    const salt = await bcrypt.genSalt();
    const tokenHash = await bcrypt.hash(refreshToken, salt);
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    return {
      userId: user.id,
      username: user.username,
      role: user.role,
      accessToken,
      refreshToken,
    };
  }

  async changePassword(userId: string, newPassword: string) {
    const salt = await bcrypt.genSalt();
    const passwordHash = await bcrypt.hash(newPassword, salt);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    return { status: 'success', message: 'Password changed successfully' };
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const userId = payload.sub;

      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new UnauthorizedException('User not found');

      // Find token in db
      const dbTokens = await this.prisma.refreshToken.findMany({
        where: { userId },
      });

      let isValid = false;
      let matchedTokenId = '';
      for (const dbToken of dbTokens) {
        if (await bcrypt.compare(refreshToken, dbToken.tokenHash)) {
          if (dbToken.expiresAt > new Date()) {
            isValid = true;
            matchedTokenId = dbToken.id;
            break;
          }
        }
      }

      if (!isValid) {
        throw new UnauthorizedException('Invalid or expired refresh token');
      }

      // Delete the used refresh token
      await this.prisma.refreshToken.delete({ where: { id: matchedTokenId } });

      // Generate new pair
      return this.login(user);
    } catch (e) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}

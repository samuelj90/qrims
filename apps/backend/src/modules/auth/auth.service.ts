import { Injectable, UnauthorizedException } from '@nestjs/common';
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
      const result = { ...user };
      delete (result as any).passwordHash;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { username: user.username, sub: user.id, role: user.role };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });

    // Generate database token reference first
    const dbToken = await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: 'pending',
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    // Sign JWT enclosing the database token identifier as jti claim
    const refreshToken = this.jwtService.sign(
      { sub: user.id, jti: dbToken.id },
      { expiresIn: '7d' },
    );

    // Save refresh token bcrypt hash in db
    const salt = await bcrypt.genSalt();
    const tokenHash = await bcrypt.hash(refreshToken, salt);
    await this.prisma.refreshToken.update({
      where: { id: dbToken.id },
      data: { tokenHash },
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
      const jti = payload.jti;
      const userId = payload.sub;

      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new UnauthorizedException('User not found');

      // Direct lookup by JTI primary key (no loops, O(1) performance)
      const dbToken = await this.prisma.refreshToken.findUnique({
        where: { id: jti },
      });

      if (!dbToken || dbToken.expiresAt < new Date()) {
        throw new UnauthorizedException('Invalid or expired refresh token');
      }

      // Check the token hash
      const isValid = await bcrypt.compare(refreshToken, dbToken.tokenHash);
      if (!isValid) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Delete the used refresh token (One-time use rotation)
      await this.prisma.refreshToken.delete({ where: { id: jti } });

      // Generate new pair
      return this.login(user);
    } catch (e) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}

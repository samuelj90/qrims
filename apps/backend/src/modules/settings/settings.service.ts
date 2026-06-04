import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSettingsDto } from './dto/settings.dto';

@Injectable()
export class SettingsService implements OnModuleInit {
  constructor(private prisma: PrismaService) {}

  // Ensure initial row exists on start
  async onModuleInit() {
    const count = await this.prisma.systemSettings.count();
    if (count === 0) {
      await this.prisma.systemSettings.create({
        data: {
          id: 1,
          name: 'QRBS Supermarket',
          address: '123052/Street, City',
          phoneNumber: '944858585858',
        },
      });
    }
  }

  async getSettings() {
    return this.prisma.systemSettings.findUnique({
      where: { id: 1 },
    });
  }

  async updateSettings(dto: UpdateSettingsDto) {
    return this.prisma.systemSettings.update({
      where: { id: 1 },
      data: dto,
    });
  }
}

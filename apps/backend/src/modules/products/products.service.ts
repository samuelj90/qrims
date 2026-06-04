import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.product.findMany({
      where: { isActive: true, deletedAt: null },
    });
  }

  async findBySku(sku: string) {
    return this.prisma.product.findFirst({
      where: { sku, isActive: true, deletedAt: null },
    });
  }
}

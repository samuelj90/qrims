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

  async create(dto: any) {
    return this.prisma.product.create({
      data: {
        sku: dto.sku,
        name: dto.name,
        price: Number(dto.price),
        discount: dto.discount ? Number(dto.discount) : 0.0,
        tax: dto.tax ? Number(dto.tax) : 0.0,
        compliment: dto.compliment || null,
        isActive: true,
      },
    });
  }
}

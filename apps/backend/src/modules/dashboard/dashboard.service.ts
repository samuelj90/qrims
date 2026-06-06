import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async getStats() {
    // 1. Products (SKUs)
    const totalProducts = await this.prisma.product.count({
      where: { isActive: true, deletedAt: null },
    });

    // 2. Users (Role distribution)
    const totalUsers = await this.prisma.user.count({
      where: { deletedAt: null },
    });
    const adminsCount = await this.prisma.user.count({
      where: { role: 'ADMIN', deletedAt: null },
    });
    const staffCount = await this.prisma.user.count({
      where: { role: 'STAFF', deletedAt: null },
    });
    const customersCount = await this.prisma.user.count({
      where: { role: 'CUSTOMER', deletedAt: null },
    });

    // 3. Sales Volume (Ecosystem Checkout Flow)
    const salesAggregate = await this.prisma.sale.aggregate({
      _sum: {
        totalAmount: true,
      },
    });
    const totalSalesAmount = salesAggregate._sum.totalAmount || 0.0;

    // 4. Pending / active carts
    const pendingCartsCount = await this.prisma.cart.count({
      where: { status: 'PENDING' },
    });

    // 5. Audit logs (latest 5)
    const auditLogs = await this.prisma.auditLog.findMany({
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        action: true,
        targetTable: true,
        createdAt: true,
        user: {
          select: {
            username: true,
          },
        },
      },
    });

    // 6. Database status (simple SELECT 1 check)
    let dbStatus = 'healthy';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch (e) {
      dbStatus = 'unhealthy';
    }

    return {
      products: {
        totalActiveSkus: totalProducts,
      },
      users: {
        totalRegistered: totalUsers,
        admins: adminsCount,
        staff: staffCount,
        customers: customersCount,
      },
      sales: {
        totalAmount: totalSalesAmount,
      },
      devices: {
        activeTerminals: 14, // Mocked value representing connected hardware
        pendingSyncs: pendingCartsCount,
      },
      auditLogs: auditLogs.map(log => ({
        id: log.id,
        action: log.action,
        targetTable: log.targetTable,
        username: log.user?.username || 'SYSTEM',
        createdAt: log.createdAt,
      })),
      dbStatus,
    };
  }
}

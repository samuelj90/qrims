import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckoutDto } from './dto/checkout.dto';

@Injectable()
export class CartsService {
  constructor(private prisma: PrismaService) {}

  async checkout(userId: string, checkoutDto: CheckoutDto) {
    const { items, totalAmount } = checkoutDto;

    if (!items || items.length === 0) {
      throw new BadRequestException('Checkout cart is empty');
    }

    // Execute in a transaction to ensure atomic consistency
    return this.prisma.$transaction(async (tx) => {
      // Map item productIds (which may be SKUs or UUIDs) to actual Product UUIDs
      const mappedItems = await Promise.all(
        items.map(async (item) => {
          let product = await tx.product.findUnique({
            where: { id: item.productId },
          });

          if (!product) {
            // Try lookup by SKU in case the client sent the SKU
            product = await tx.product.findUnique({
              where: { sku: item.productId },
            });
          }

          if (!product) {
            throw new BadRequestException(`Product not found: ${item.productId}`);
          }

          return {
            ...item,
            productId: product.id, // Ensure we use the actual Product UUID
          };
        }),
      );

      // 1. Create the Cart
      const cart = await tx.cart.create({
        data: {
          userId,
          status: 'CHECKED_OUT',
          totalAmount,
          items: {
            create: mappedItems.map((item) => ({
              productId: item.productId,
              price: item.price,
              discount: item.discount,
              tax: item.tax,
              quantity: item.quantity,
            })),
          },
        },
        include: {
          items: true,
        },
      });

      // 2. Create the Sale record
      const sale = await tx.sale.create({
        data: {
          staffId: userId,
          totalAmount,
          items: {
            create: mappedItems.map((item) => ({
              productId: item.productId,
              price: item.price,
              discount: item.discount,
              tax: item.tax,
              quantity: item.quantity,
            })),
          },
        },
      });

      // 3. Log the system audit
      await tx.auditLog.create({
        data: {
          userId,
          action: `Checked out cart ${cart.id} - Sale registered ${sale.id}`,
          targetTable: 'Cart',
          targetId: cart.id,
          changes: { totalAmount, itemCount: items.length },
        },
      });

      return {
        status: 'success',
        cartId: cart.id,
        saleId: sale.id,
        message: 'Checkout processed successfully',
      };
    });
  }
}

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log('--> Seeding database...');

  // 1. Seed Users
  const salt = await bcrypt.genSalt(10);
  
  const adminPasswordHash = await bcrypt.hash('adminpassword', salt);
  const staffPasswordHash = await bcrypt.hash('staffpassword', salt);
  const customerPasswordHash = await bcrypt.hash('customerpassword', salt);

  const admin = await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      passwordHash: adminPasswordHash,
      role: 'ADMIN',
    },
  });

  const staff = await prisma.user.upsert({
    where: { username: 'staff' },
    update: {},
    create: {
      username: 'staff',
      passwordHash: staffPasswordHash,
      role: 'STAFF',
    },
  });

  const customer = await prisma.user.upsert({
    where: { username: 'customer' },
    update: {},
    create: {
      username: 'customer',
      passwordHash: customerPasswordHash,
      role: 'CUSTOMER',
    },
  });

  console.log('✓ Users seeded:', { admin: admin.username, staff: staff.username, customer: customer.username });

  // 2. Seed Products
  const productsData = [
    { sku: 'PROD-001', name: 'Wireless Laser Mouse', price: 29.99, discount: 0.0, tax: 5.0, compliment: 'Ergonomic 2.4Ghz wireless' },
    { sku: 'PROD-002', name: 'Mechanical Gaming Keyboard', price: 89.99, discount: 10.0, tax: 5.0, compliment: 'RGB backlit blue switches' },
    { sku: 'PROD-003', name: '27-inch 4K IPS Monitor', price: 349.99, discount: 0.0, tax: 15.0, compliment: 'UHD 144Hz high refresh rate' },
    { sku: 'PROD-004', name: 'USB-C Multiport Hub', price: 45.00, discount: 5.0, tax: 2.5, compliment: '8-in-1 card reader & HDMI' },
    { sku: 'PROD-005', name: 'Noise Cancelling Headphones', price: 199.99, discount: 20.0, tax: 10.0, compliment: 'Over-ear Bluetooth headphones' },
    { sku: 'PROD-006', name: 'Ergonomic Office Chair', price: 249.00, discount: 0.0, tax: 12.0, compliment: 'Mesh back lumbar support' },
    { sku: 'PROD-007', name: 'Smart Fitness Watch', price: 129.50, discount: 15.0, tax: 6.0, compliment: 'Heart rate & sleep tracker' },
    { sku: 'PROD-008', name: '1080p Web Camera', price: 59.99, discount: 0.0, tax: 3.0, compliment: 'HD stream autofocus mic' },
    { sku: 'PROD-009', name: 'External 2TB SSD', price: 159.00, discount: 10.0, tax: 8.0, compliment: 'USB 3.2 gen 2 ultra speed' },
    { sku: 'PROD-010', name: 'Portable Laptop Stand', price: 35.00, discount: 0.0, tax: 1.5, compliment: 'Aluminum fold angle adjuster' }
  ];

  for (const item of productsData) {
    await prisma.product.upsert({
      where: { sku: item.sku },
      update: {
        name: item.name,
        price: item.price,
        discount: item.discount,
        tax: item.tax,
        compliment: item.compliment,
      },
      create: item,
    });
  }

  console.log(`✓ ${productsData.length} products seeded.`);
  console.log('--> Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

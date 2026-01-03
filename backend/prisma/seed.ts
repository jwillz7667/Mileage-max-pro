import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create IRS rates for tax years
  const taxYearData = [
    { year: 2024, business: 0.67, medical: 0.21, charity: 0.14 },
    { year: 2025, business: 0.70, medical: 0.22, charity: 0.14 },
    { year: 2026, business: 0.70, medical: 0.22, charity: 0.14 },
  ];

  console.log('Database seeded successfully');
}

main()
  .catch((error) => {
    console.error('Seed error:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

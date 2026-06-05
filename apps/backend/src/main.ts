import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import * as http from 'http';

let cachedExpressApp: any;

async function bootstrapServer(): Promise<any> {
  if (!cachedExpressApp) {
    const app = await NestFactory.create(AppModule);

    // Apply security headers
    app.use(helmet());

    // CORS config (Secure by default: block wildcard credentials leakage)
    const allowedOrigins = process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(',')
      : false;
    app.enableCors({
      origin: allowedOrigins,
      methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
      credentials: allowedOrigins !== false,
    });

    // API path prefixing and versioning
    app.setGlobalPrefix('api');
    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1', // results in /api/v1/...
    });

    // Global DTO input validation & transformation
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );

    // Swagger OpenAPI generation setup
    const config = new DocumentBuilder()
      .setTitle('QRIMS API')
      .setDescription('QR Inventory Management System Backend Ecosystem API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document);

    await app.init();
    cachedExpressApp = app.getHttpAdapter().getInstance();
  }
  return cachedExpressApp;
}

// Serverless Handler for Vercel deployment
export default async (req: any, res: any) => {
  const expressApp = await bootstrapServer();
  return expressApp(req, res);
};

// Local standalone initialization for local development and Docker Compose
if (!process.env.VERCEL) {
  bootstrapServer().then((expressApp) => {
    const port = process.env.PORT || 3000;
    const server = http.createServer(expressApp);
    server.listen(port, () => {
      console.log(`QRIMS API is running locally on: http://localhost:${port}/api/v1`);
      console.log(`Swagger OpenAPI Documentation: http://localhost:${port}/docs`);
    });
  }).catch((err) => {
    console.error('Failed to start local NestJS server:', err);
  });
}

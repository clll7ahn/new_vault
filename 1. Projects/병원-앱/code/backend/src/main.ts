import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('병원 앱 API')
    .setDescription('중소규모 병원용 모듈러 앱 API')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', '인증')
    .addTag('hospitals', '병원 정보')
    .addTag('appointments', '예약')
    .addTag('queue', '대기열')
    .addTag('notifications', '알림')
    .addTag('chatbot', '챗봇')
    .addTag('gamification', '게이미피케이션')
    .addTag('health', '건강 트래커')
    .addTag('analytics', 'AI 분석')
    .addTag('specialty', '전문 모듈')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();

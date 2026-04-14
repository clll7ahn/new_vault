import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Faq } from './entities/faq.entity';
import { ChatSession } from './entities/chat-session.entity';
import { ChatMessage } from './entities/chat-message.entity';
import { ChatbotService } from './chatbot.service';
import { ChatbotController } from './chatbot.controller';
import { LlmChatService } from './llm/llm-chat.service';
import { LlmChatController } from './llm/llm-chat.controller';
import { GuardrailService } from './llm/guardrail.service';

@Module({
  imports: [TypeOrmModule.forFeature([Faq, ChatSession, ChatMessage])],
  controllers: [ChatbotController, LlmChatController],
  providers: [ChatbotService, LlmChatService, GuardrailService],
  exports: [ChatbotService, LlmChatService, GuardrailService],
})
export class ChatbotModule {}

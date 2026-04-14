import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { LlmChatService } from './llm-chat.service';
import { JwtAuthGuard } from '../../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../../common/decorators/current-user.decorator';
import { IsString, IsUUID, IsOptional, MaxLength } from 'class-validator';

export class LlmMessageDto {
  @IsString()
  @MaxLength(2000)
  message: string;

  @IsOptional()
  @IsUUID()
  sessionId?: string;
}

@Controller('api/v1/chatbot/llm')
@UseGuards(JwtAuthGuard)
export class LlmChatController {
  constructor(private readonly llmChatService: LlmChatService) {}

  @Post('message')
  sendMessage(
    @CurrentUser('id') userId: string,
    @Body() dto: LlmMessageDto,
  ) {
    return this.llmChatService.chat(userId, dto.sessionId, dto.message);
  }

  @Get('sessions/:id/messages')
  getSessionMessages(@Param('id', ParseUUIDPipe) id: string) {
    return this.llmChatService.getSessionMessages(id);
  }
}

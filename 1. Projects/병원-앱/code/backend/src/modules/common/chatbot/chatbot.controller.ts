import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ChatbotService } from './chatbot.service';
import { SendMessageDto } from './dto/send-message.dto';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/chatbot')
export class ChatbotController {
  constructor(private readonly chatbotService: ChatbotService) {}

  @Post('message')
  @UseGuards(JwtAuthGuard)
  sendMessage(
    @CurrentUser('id') userId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatbotService.sendMessage(userId, dto);
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  getMySessions(@CurrentUser('id') userId: string) {
    return this.chatbotService.getMySessions(userId);
  }

  @Get('sessions/:id/messages')
  @UseGuards(JwtAuthGuard)
  getSessionHistory(@Param('id', ParseUUIDPipe) id: string) {
    return this.chatbotService.getSessionHistory(id);
  }

  @Get('faqs')
  getFaqs() {
    return this.chatbotService.getFaqs();
  }

  @Post('faqs')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  createFaq(@Body() dto: CreateFaqDto) {
    return this.chatbotService.createFaq(dto);
  }

  @Patch('faqs/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  updateFaq(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateFaqDto,
  ) {
    return this.chatbotService.updateFaq(id, dto);
  }
}

import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatSession, ChatSessionType } from '../entities/chat-session.entity';
import { ChatMessage, MessageRole } from '../entities/chat-message.entity';
import { GuardrailService } from './guardrail.service';

export interface LlmMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

const SYSTEM_PROMPT = `당신은 병원 앱의 의료 안내 AI 어시스턴트입니다.

역할 및 제한사항:
- 일반적인 의료 정보와 병원 이용 안내를 제공합니다.
- 진단(diagnosis)을 내리거나 특정 질병이라고 단정 짓지 마십시오.
- 처방(prescription) 또는 특정 약물 복용을 권유하지 마십시오.
- 응급 상황(흉통, 의식불명, 호흡곤란 등)이 감지되면 반드시 즉시 119 연락을 안내하십시오.
- 항상 "정확한 진단은 의료진 상담이 필요합니다"를 포함하십시오.
- 친절하고 공감적인 어조를 유지하되, 의학적 판단은 하지 마십시오.
- 한국어로 응답하십시오.`;

@Injectable()
export class LlmChatService {
  private readonly provider: 'anthropic' | 'openai' | 'mock';

  constructor(
    private readonly configService: ConfigService,
    private readonly guardrailService: GuardrailService,
    @InjectRepository(ChatSession)
    private readonly sessionRepo: Repository<ChatSession>,
    @InjectRepository(ChatMessage)
    private readonly messageRepo: Repository<ChatMessage>,
  ) {
    const apiKey =
      this.configService.get<string>('ANTHROPIC_API_KEY') ||
      this.configService.get<string>('OPENAI_API_KEY');

    if (this.configService.get<string>('ANTHROPIC_API_KEY')) {
      this.provider = 'anthropic';
    } else if (this.configService.get<string>('OPENAI_API_KEY')) {
      this.provider = 'openai';
    } else {
      this.provider = 'mock';
    }

    void apiKey;
  }

  async sendToLLM(
    messages: LlmMessage[],
    systemPrompt: string = SYSTEM_PROMPT,
  ): Promise<string> {
    if (this.provider === 'anthropic') {
      return this.callAnthropic(messages, systemPrompt);
    } else if (this.provider === 'openai') {
      return this.callOpenAI(messages, systemPrompt);
    }
    return this.mockResponse(messages);
  }

  private async callAnthropic(
    messages: LlmMessage[],
    systemPrompt: string,
  ): Promise<string> {
    const apiKey = this.configService.get<string>('ANTHROPIC_API_KEY')!;
    const anthropicMessages = messages.filter((m) => m.role !== 'system');

    const body = {
      model: 'claude-3-haiku-20240307',
      max_tokens: 1024,
      system: systemPrompt,
      messages: anthropicMessages,
    };

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new InternalServerErrorException('LLM API 호출에 실패했습니다.');
    }

    const data = (await response.json()) as {
      content: Array<{ type: string; text: string }>;
    };
    return data.content[0]?.text ?? '';
  }

  private async callOpenAI(
    messages: LlmMessage[],
    systemPrompt: string,
  ): Promise<string> {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY')!;
    const allMessages: LlmMessage[] = [
      { role: 'system', content: systemPrompt },
      ...messages,
    ];

    const body = {
      model: 'gpt-4o-mini',
      max_tokens: 1024,
      messages: allMessages,
    };

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new InternalServerErrorException('LLM API 호출에 실패했습니다.');
    }

    const data = (await response.json()) as {
      choices: Array<{ message: { content: string } }>;
    };
    return data.choices[0]?.message?.content ?? '';
  }

  private mockResponse(messages: LlmMessage[]): string {
    const lastUserMsg = [...messages].reverse().find((m) => m.role === 'user');
    const content = lastUserMsg?.content ?? '';
    return `안녕하세요! "${content}"에 대해 답변 드립니다. 저는 의료 안내 AI입니다. 정확한 진단은 의료진 상담이 필요합니다.`;
  }

  async chat(
    userId: string,
    sessionId: string | undefined,
    userMessage: string,
  ): Promise<{ sessionId: string; reply: string }> {
    let session: ChatSession;

    if (sessionId) {
      const found = await this.sessionRepo.findOne({
        where: { id: sessionId, userId },
      });
      session = found ?? (await this.createSession(userId));
    } else {
      session = await this.createSession(userId);
    }

    await this.messageRepo.save(
      this.messageRepo.create({
        sessionId: session.id,
        role: MessageRole.USER,
        content: userMessage,
        metadata: null,
      }),
    );

    const history = await this.messageRepo.find({
      where: { sessionId: session.id },
      order: { createdAt: 'ASC' },
      take: 20,
    });

    const llmMessages: LlmMessage[] = history
      .filter((m) => m.role !== MessageRole.SYSTEM)
      .map((m) => ({
        role: m.role === MessageRole.USER ? 'user' : 'assistant',
        content: m.content,
      }));

    const rawReply = await this.sendToLLM(llmMessages);
    const processed = this.guardrailService.process(rawReply);

    await this.messageRepo.save(
      this.messageRepo.create({
        sessionId: session.id,
        role: MessageRole.BOT,
        content: processed,
        metadata: { provider: this.provider },
      }),
    );

    return { sessionId: session.id, reply: processed };
  }

  async getSessionMessages(sessionId: string) {
    return this.messageRepo.find({
      where: { sessionId },
      order: { createdAt: 'ASC' },
    });
  }

  private async createSession(userId: string): Promise<ChatSession> {
    return this.sessionRepo.save(
      this.sessionRepo.create({ userId, type: ChatSessionType.GENERAL }),
    );
  }
}

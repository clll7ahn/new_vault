import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Faq } from './entities/faq.entity';
import { ChatSession, ChatSessionType } from './entities/chat-session.entity';
import { ChatMessage, MessageRole } from './entities/chat-message.entity';
import { SendMessageDto } from './dto/send-message.dto';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';

const SYMPTOM_MAP: Record<string, { department: string; urgency: 'low' | 'medium' | 'high' | 'emergency' }> = {
  '두통': { department: '내과', urgency: 'low' },
  '복통': { department: '내과', urgency: 'medium' },
  '흉통': { department: '내과', urgency: 'emergency' },
  '호흡곤란': { department: '내과', urgency: 'emergency' },
  '피부발진': { department: '피부과', urgency: 'low' },
  '여드름': { department: '피부과', urgency: 'low' },
  '허리통증': { department: '정형외과', urgency: 'medium' },
  '골절': { department: '정형외과', urgency: 'high' },
  '시력저하': { department: '안과', urgency: 'medium' },
  '치통': { department: '치과', urgency: 'medium' },
  '우울': { department: '정신건강의학과', urgency: 'medium' },
  '불면': { department: '정신건강의학과', urgency: 'low' },
  '의식저하': { department: '응급', urgency: 'emergency' },
};

@Injectable()
export class ChatbotService {
  constructor(
    @InjectRepository(Faq)
    private readonly faqRepo: Repository<Faq>,
    @InjectRepository(ChatSession)
    private readonly sessionRepo: Repository<ChatSession>,
    @InjectRepository(ChatMessage)
    private readonly messageRepo: Repository<ChatMessage>,
  ) {}

  async sendMessage(userId: string, dto: SendMessageDto) {
    let session: ChatSession;

    if (dto.sessionId) {
      const found = await this.sessionRepo.findOne({ where: { id: dto.sessionId, userId } });
      if (!found) throw new NotFoundException('Session not found');
      session = found;
    } else {
      const sessionType =
        dto.type === 'faq'
          ? ChatSessionType.FAQ
          : dto.type === 'symptom_check'
          ? ChatSessionType.SYMPTOM_CHECK
          : ChatSessionType.GENERAL;

      session = await this.sessionRepo.save(
        this.sessionRepo.create({ userId, type: sessionType }),
      );
    }

    await this.messageRepo.save(
      this.messageRepo.create({
        sessionId: session.id,
        role: MessageRole.USER,
        content: dto.message,
        metadata: null,
      }),
    );

    let botContent: string;
    let metadata: Record<string, unknown> | null = null;

    if (session.type === ChatSessionType.FAQ) {
      const faq = await this.matchFaq(dto.message);
      botContent = faq ? faq.answer : '죄송합니다. 관련 FAQ를 찾을 수 없습니다. 직접 문의 부탁드립니다.';
    } else if (session.type === ChatSessionType.SYMPTOM_CHECK) {
      const result = this.checkSymptoms(dto.message);
      if (result.length === 0) {
        botContent = '증상 키워드를 인식하지 못했습니다. 두통, 복통, 흉통 등 증상을 직접 입력해 주세요.';
      } else {
        const hasEmergency = result.some((r) => r.urgency === 'emergency');
        const lines = result.map(
          (r) => `- ${r.keyword}: ${r.department} (긴급도: ${r.urgency})`,
        );
        botContent = `증상 분석 결과입니다:\n${lines.join('\n')}`;
        if (hasEmergency) {
          botContent += '\n\n⚠️ 응급 증상이 감지되었습니다. 즉시 119에 연락하거나 응급실을 방문하세요.';
        }
        metadata = { recommendations: result };
      }
    } else {
      botContent = '안녕하세요! 무엇을 도와드릴까요? FAQ 조회나 증상 체크를 원하시면 type을 지정해 주세요.';
    }

    const botMessage = await this.messageRepo.save(
      this.messageRepo.create({
        sessionId: session.id,
        role: MessageRole.BOT,
        content: botContent,
        metadata,
      }),
    );

    return {
      sessionId: session.id,
      message: botMessage,
    };
  }

  async matchFaq(message: string): Promise<Faq | null> {
    const faqs = await this.faqRepo.find({ where: { isActive: true } });
    const lower = message.toLowerCase();

    let best: Faq | null = null;
    let bestScore = 0;

    for (const faq of faqs) {
      const score = faq.keywords.filter((kw) =>
        lower.includes(kw.toLowerCase()),
      ).length;
      if (score > bestScore) {
        bestScore = score;
        best = faq;
      }
    }

    return bestScore > 0 ? best : null;
  }

  checkSymptoms(
    message: string,
  ): Array<{ keyword: string; department: string; urgency: string }> {
    const results: Array<{ keyword: string; department: string; urgency: string }> = [];

    for (const [keyword, info] of Object.entries(SYMPTOM_MAP)) {
      if (message.includes(keyword)) {
        results.push({ keyword, ...info });
      }
    }

    return results;
  }

  async getSessionHistory(sessionId: string) {
    const session = await this.sessionRepo.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Session not found');

    const messages = await this.messageRepo.find({
      where: { sessionId },
      order: { createdAt: 'ASC' },
    });

    return { session, messages };
  }

  async getMySessions(userId: string) {
    return this.sessionRepo.find({
      where: { userId },
      order: { startedAt: 'DESC' },
    });
  }

  async getFaqs() {
    return this.faqRepo.find({
      where: { isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
  }

  async createFaq(dto: CreateFaqDto) {
    return this.faqRepo.save(this.faqRepo.create(dto));
  }

  async updateFaq(id: string, dto: UpdateFaqDto) {
    const faq = await this.faqRepo.findOne({ where: { id } });
    if (!faq) throw new NotFoundException('FAQ not found');
    Object.assign(faq, dto);
    return this.faqRepo.save(faq);
  }
}

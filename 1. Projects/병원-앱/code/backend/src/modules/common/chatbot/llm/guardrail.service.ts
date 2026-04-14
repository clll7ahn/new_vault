import { Injectable } from '@nestjs/common';

const FORBIDDEN_PATTERNS = [
  /당신(은|의)?\s*(병명|진단|질환|질병)(은|이|을|가)?\s*(.*?)(입니다|이에요|이야|같아요|같습니다)/,
  /이\s*(증상|상태)(은|는|이|가)?\s*(.*?)(입니다|이에요|확실합니다)/,
  /(확실히|분명히|틀림없이)\s*(.*?)(병|질환|질병|증후군)/,
  /처방(해|하겠|드리겠|을\s*드릴)/,
  /(이\s*약|약품|약물)(을|를)?\s*(드세요|복용하세요|사용하세요)/,
];

const EMERGENCY_KEYWORDS = [
  '119', '응급', '의식불명', '의식 없', '호흡 정지', '호흡정지',
  '심정지', '심장마비', '쓰러', '갑작스러운 흉통', '뇌졸중',
  '출혈이 심', '뼈가 부러', '대량 출혈',
];

const DISCLAIMER = '\n\n※ 위 내용은 참고용 의료 정보이며, 정확한 진단은 의료진 상담이 필요합니다.';

@Injectable()
export class GuardrailService {
  validateResponse(text: string): { isValid: boolean; sanitized: string } {
    let sanitized = text;
    let hasForbidden = false;

    for (const pattern of FORBIDDEN_PATTERNS) {
      if (pattern.test(text)) {
        hasForbidden = true;
        sanitized = sanitized.replace(
          pattern,
          '해당 내용은 의료진이 직접 판단해야 합니다.',
        );
      }
    }

    return { isValid: !hasForbidden, sanitized };
  }

  detectEmergency(text: string): boolean {
    const lower = text.toLowerCase();
    return EMERGENCY_KEYWORDS.some((kw) => lower.includes(kw));
  }

  addDisclaimer(text: string): string {
    return text + DISCLAIMER;
  }

  process(text: string): string {
    const { sanitized } = this.validateResponse(text);
    const withDisclaimer = this.addDisclaimer(sanitized);

    if (this.detectEmergency(text)) {
      return withDisclaimer + '\n\n🚨 응급 상황으로 판단될 경우 즉시 119에 연락하거나 가까운 응급실을 방문하세요.';
    }

    return withDisclaimer;
  }
}

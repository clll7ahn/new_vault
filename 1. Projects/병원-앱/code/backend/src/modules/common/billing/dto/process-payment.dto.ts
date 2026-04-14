import { IsEnum } from 'class-validator';
import { PaymentMethod } from '../entities/billing.entity';

export class ProcessPaymentDto {
  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;
}

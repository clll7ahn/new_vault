/// 수납/결제 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// BillingStatus
// ──────────────────────────────────────────────────────────────────────────────

enum BillingStatus {
  pending,   // 미납
  paid,      // 결제완료
  refunded,  // 환불
  overdue,   // 연체
}

extension BillingStatusX on BillingStatus {
  String get label {
    switch (this) {
      case BillingStatus.pending:
        return '미납';
      case BillingStatus.paid:
        return '결제완료';
      case BillingStatus.refunded:
        return '환불';
      case BillingStatus.overdue:
        return '연체';
    }
  }

  bool get isUnpaid =>
      this == BillingStatus.pending || this == BillingStatus.overdue;

  static BillingStatus fromString(String? value) {
    switch (value) {
      case 'paid':
        return BillingStatus.paid;
      case 'refunded':
        return BillingStatus.refunded;
      case 'overdue':
        return BillingStatus.overdue;
      default:
        return BillingStatus.pending;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PaymentMethod
// ──────────────────────────────────────────────────────────────────────────────

enum PaymentMethod {
  card,
  cash,
  transfer,
  appPay,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return '카드';
      case PaymentMethod.cash:
        return '현금';
      case PaymentMethod.transfer:
        return '계좌이체';
      case PaymentMethod.appPay:
        return '앱결제';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.appPay:
        return 'app_pay';
    }
  }

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'app_pay':
        return PaymentMethod.appPay;
      default:
        return PaymentMethod.card;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BillingModel
// ──────────────────────────────────────────────────────────────────────────────

class BillingModel {
  const BillingModel({
    required this.id,
    required this.patientId,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.appointmentId,
    this.paymentMethod,
    this.paidAt,
    this.receiptNumber,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String? appointmentId;
  final double amount;
  final String description;
  final BillingStatus status;
  final PaymentMethod? paymentMethod;
  final DateTime? paidAt;
  final String? receiptNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      amount: double.parse(json['amount'].toString()),
      description: json['description'] as String,
      status: BillingStatusX.fromString(json['status'] as String?),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethodX.fromString(json['payment_method'] as String?)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      receiptNumber: json['receipt_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        if (appointmentId != null) 'appointment_id': appointmentId,
        'amount': amount,
        'description': description,
        'status': status.name,
        if (paymentMethod != null) 'payment_method': paymentMethod!.apiValue,
        if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
        if (receiptNumber != null) 'receipt_number': receiptNumber,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  BillingModel copyWith({BillingStatus? status, PaymentMethod? paymentMethod}) {
    return BillingModel(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      amount: amount,
      description: description,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt,
      receiptNumber: receiptNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

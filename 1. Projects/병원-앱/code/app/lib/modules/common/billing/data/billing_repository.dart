import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/billing_model.dart';

/// 수납/결제 API 레포지토리
class BillingRepository {
  BillingRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  // ──────────────────────────────────────────
  // 내 청구 목록 조회
  // ──────────────────────────────────────────

  Future<List<BillingModel>> getMyBillings({BillingStatus? status}) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.billings,
      queryParameters: {
        if (status != null) 'status': status.name,
      },
    );
    return (response.data ?? [])
        .map((e) => BillingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 미납 청구 목록 조회
  // ──────────────────────────────────────────

  Future<List<BillingModel>> getUnpaidBillings() async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiConstants.billings}/unpaid',
    );
    return (response.data ?? [])
        .map((e) => BillingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 단일 청구서 조회
  // ──────────────────────────────────────────

  Future<BillingModel> getBilling(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.billings}/$id',
    );
    return BillingModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 결제 처리
  // ──────────────────────────────────────────

  Future<BillingModel> processPayment({
    required String id,
    required PaymentMethod paymentMethod,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '${ApiConstants.billings}/$id/pay',
      data: {'paymentMethod': paymentMethod.apiValue},
    );
    return BillingModel.fromJson(response.data!);
  }
}

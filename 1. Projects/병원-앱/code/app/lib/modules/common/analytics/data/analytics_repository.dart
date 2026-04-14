import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/analytics_model.dart';

class AnalyticsRepository {
  AnalyticsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;
  static const _base = '${ApiConstants.apiV1}/analytics';

  Future<List<NoShowRiskAppointmentModel>> getNoShowRiskAppointments(
      {int limit = 10}) async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/no-show-risk',
      queryParameters: {'limit': limit, 'date': _todayStr()},
    );
    return (res.data ?? [])
        .map((e) => NoShowRiskAppointmentModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PeakTimeSlotModel>> getPeakTimeSlots() async {
    final res = await _dio.get<List<dynamic>>(
      '$_base/peak-times',
      queryParameters: {'date': _todayStr()},
    );
    return (res.data ?? [])
        .map((e) => PeakTimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChurnRiskSummaryModel> getChurnRiskSummary() async {
    final res =
        await _dio.get<Map<String, dynamic>>('$_base/churn-risk-summary');
    return ChurnRiskSummaryModel.fromJson(res.data!);
  }

  Future<RevenueSummaryModel> getRevenueSummary() async {
    final res =
        await _dio.get<Map<String, dynamic>>('$_base/revenue-summary');
    return RevenueSummaryModel.fromJson(res.data!);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }
}

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/appointment_model.dart';

/// 예약 API 레포지토리
///
/// - getSlots      : 특정 의사 + 날짜의 예약 가능 슬롯 조회
/// - create        : 예약 생성
/// - getMyList     : 내 예약 목록 조회
/// - cancel        : 예약 취소
class AppointmentRepository {
  AppointmentRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  // ──────────────────────────────────────────
  // 예약 가능 슬롯 조회
  // ──────────────────────────────────────────

  Future<List<SlotModel>> getSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.availableSlots,
      queryParameters: {
        'doctor_id': doctorId,
        'date': _dateFmt.format(date),
      },
    );
    return (response.data ?? [])
        .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 예약 생성
  // ──────────────────────────────────────────

  Future<AppointmentModel> create(CreateAppointmentDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.appointments,
      data: dto.toJson(),
    );
    return AppointmentModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 내 예약 목록
  // ──────────────────────────────────────────

  Future<List<AppointmentModel>> getMyList({AppointmentStatus? status}) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.appointments,
      queryParameters: {
        if (status != null) 'status': status.name,
      },
    );
    return (response.data ?? [])
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 예약 취소
  // ──────────────────────────────────────────

  Future<void> cancel(String id) async {
    await _dio.patch<void>(
      '${ApiConstants.appointments}/$id/cancel',
    );
  }
}

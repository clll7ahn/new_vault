import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/hospital_model.dart';

/// 병원 정보 API 레포지토리
///
/// - getHospitalInfo : 병원 기본 정보
/// - getDepartments  : 진료과 목록
/// - getDoctors      : 의료진 목록 (진료과 필터 선택)
/// - getDoctor       : 의료진 단건 조회
class HospitalRepository {
  HospitalRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  // ──────────────────────────────────────────
  // 병원 기본 정보
  // ──────────────────────────────────────────

  Future<HospitalModel> getHospitalInfo() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.apiV1}/hospital',
    );
    return HospitalModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 진료과 목록
  // ──────────────────────────────────────────

  Future<List<DepartmentModel>> getDepartments() async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.departments,
    );
    return (response.data ?? [])
        .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 의료진 목록
  // ──────────────────────────────────────────

  Future<List<DoctorModel>> getDoctors({String? departmentId}) async {
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.doctors,
      queryParameters: {
        if (departmentId != null) 'department_id': departmentId,
      },
    );
    return (response.data ?? [])
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 의료진 단건
  // ──────────────────────────────────────────

  Future<DoctorModel> getDoctor(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.doctors}/$id',
    );
    return DoctorModel.fromJson(response.data!);
  }
}

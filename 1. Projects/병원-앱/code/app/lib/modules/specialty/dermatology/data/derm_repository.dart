import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/derm_model.dart';

/// 피부과 API 레포지토리
///
/// - addPhoto       : 피부 사진 업로드
/// - getPhotos      : 사진 목록 조회 (타임라인)
/// - getTimeline    : 날짜순 타임라인 (부위 필터)
/// - addTreatment   : 시술 이력 추가
/// - getTreatments  : 시술 이력 목록
/// - getBeforeAfter : Before/After 쌍 조회
class DermRepository {
  DermRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const String _base =
      '${ApiConstants.apiV1}/specialty/dermatology';

  // ──────────────────────────────────────────
  // 피부 사진 업로드
  // ──────────────────────────────────────────

  Future<SkinPhotoModel> addPhoto({
    required String localFilePath,
    required SkinRegion region,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        localFilePath,
        filename: 'skin_photo.jpg',
      ),
      'region': region.name,
      'taken_at': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/photos',
      data: formData,
    );
    return SkinPhotoModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 사진 목록 조회
  // ──────────────────────────────────────────

  Future<List<SkinPhotoModel>> getPhotos({
    SkinRegion? region,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/photos',
      queryParameters: {
        if (region != null) 'region': region.name,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data ?? [])
        .map((e) => SkinPhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 날짜순 타임라인
  // ──────────────────────────────────────────

  Future<List<SkinPhotoModel>> getTimeline({
    SkinRegion? region,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/photos/timeline',
      queryParameters: {
        if (region != null) 'region': region.name,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    return (response.data ?? [])
        .map((e) => SkinPhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // 시술 이력 추가
  // ──────────────────────────────────────────

  Future<TreatmentModel> addTreatment({
    required String name,
    required DateTime treatedAt,
    SkinRegion? region,
    String? notes,
    DateTime? nextScheduled,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/treatments',
      data: {
        'name': name,
        'treated_at': treatedAt.toIso8601String(),
        'status': 'completed',
        if (region != null) 'region': region.name,
        if (notes != null) 'notes': notes,
        if (nextScheduled != null)
          'next_scheduled': nextScheduled.toIso8601String(),
      },
    );
    return TreatmentModel.fromJson(response.data!);
  }

  // ──────────────────────────────────────────
  // 시술 이력 목록
  // ──────────────────────────────────────────

  Future<List<TreatmentModel>> getTreatments({
    TreatmentStatus? status,
    int limit = 20,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/treatments',
      queryParameters: {
        if (status != null) 'status': status.name,
        'limit': limit,
      },
    );
    return (response.data ?? [])
        .map((e) => TreatmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────
  // Before/After 쌍 조회
  // ──────────────────────────────────────────

  Future<List<BeforeAfterPair>> getBeforeAfter({
    String? treatmentId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_base/before-after',
      queryParameters: {
        if (treatmentId != null) 'treatment_id': treatmentId,
      },
    );
    return (response.data ?? [])
        .map((e) => BeforeAfterPair.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

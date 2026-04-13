import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hospital_repository.dart';
import '../domain/hospital_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository Provider
// ──────────────────────────────────────────────────────────────────────────────

final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// 병원 정보
// ──────────────────────────────────────────────────────────────────────────────

/// 병원 기본 정보 provider
final hospitalInfoProvider = FutureProvider<HospitalModel>((ref) {
  return ref.read(hospitalRepositoryProvider).getHospitalInfo();
});

// ──────────────────────────────────────────────────────────────────────────────
// 진료과 목록
// ──────────────────────────────────────────────────────────────────────────────

/// 전체 진료과 목록 provider
final departmentsProvider = FutureProvider<List<DepartmentModel>>((ref) {
  return ref.read(hospitalRepositoryProvider).getDepartments();
});

// ──────────────────────────────────────────────────────────────────────────────
// 의료진 목록
// ──────────────────────────────────────────────────────────────────────────────

/// 의료진 목록 provider
/// [departmentId] null이면 전체 조회, 값이 있으면 해당 진료과 필터
final doctorsProvider =
    FutureProvider.family<List<DoctorModel>, String?>((ref, departmentId) {
  return ref.read(hospitalRepositoryProvider).getDoctors(
        departmentId: departmentId,
      );
});

/// 의료진 단건 provider
final doctorDetailProvider =
    FutureProvider.family<DoctorModel, String>((ref, doctorId) {
  return ref.read(hospitalRepositoryProvider).getDoctor(doctorId);
});

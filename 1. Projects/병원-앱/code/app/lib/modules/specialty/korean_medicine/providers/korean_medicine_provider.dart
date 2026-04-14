import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/korean_medicine_repository.dart';
import '../domain/korean_medicine_model.dart';

final koreanMedicineRepositoryProvider =
    Provider<KoreanMedicineRepository>((_) => KoreanMedicineRepository());

final sasangProfileProvider =
    FutureProvider<PatientSasangProfile?>((ref) {
  return ref.read(koreanMedicineRepositoryProvider).getSasangProfile();
});

final treatmentRecordsProvider =
    FutureProvider<List<TreatmentRecordModel>>((ref) {
  return ref.read(koreanMedicineRepositoryProvider).getTreatmentRecords();
});

final sasangGuideProvider =
    FutureProvider.family<SasangGuideModel, SasangType>((ref, type) {
  return ref.read(koreanMedicineRepositoryProvider).getSasangGuide(type);
});

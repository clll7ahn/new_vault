/// 건강 기록 도메인 모델

// ──────────────────────────────────────────────────────────────────────────────
// HealthRecordType
// ──────────────────────────────────────────────────────────────────────────────

enum HealthRecordType {
  steps,         // 걸음수
  heartRate,     // 심박수
  sleep,         // 수면 (시간)
  bloodPressure, // 혈압 (수축기/이완기)
  bloodGlucose,  // 혈당
  weight,        // 체중
}

extension HealthRecordTypeX on HealthRecordType {
  String get label {
    switch (this) {
      case HealthRecordType.steps:
        return '걸음수';
      case HealthRecordType.heartRate:
        return '심박수';
      case HealthRecordType.sleep:
        return '수면';
      case HealthRecordType.bloodPressure:
        return '혈압';
      case HealthRecordType.bloodGlucose:
        return '혈당';
      case HealthRecordType.weight:
        return '체중';
    }
  }

  String get unit {
    switch (this) {
      case HealthRecordType.steps:
        return '보';
      case HealthRecordType.heartRate:
        return 'bpm';
      case HealthRecordType.sleep:
        return '시간';
      case HealthRecordType.bloodPressure:
        return 'mmHg';
      case HealthRecordType.bloodGlucose:
        return 'mg/dL';
      case HealthRecordType.weight:
        return 'kg';
    }
  }

  /// API 전송용 snake_case 키
  String get apiKey {
    switch (this) {
      case HealthRecordType.steps:
        return 'steps';
      case HealthRecordType.heartRate:
        return 'heart_rate';
      case HealthRecordType.sleep:
        return 'sleep';
      case HealthRecordType.bloodPressure:
        return 'blood_pressure';
      case HealthRecordType.bloodGlucose:
        return 'blood_glucose';
      case HealthRecordType.weight:
        return 'weight';
    }
  }

  static HealthRecordType fromString(String? value) {
    switch (value) {
      case 'steps':
        return HealthRecordType.steps;
      case 'heart_rate':
        return HealthRecordType.heartRate;
      case 'sleep':
        return HealthRecordType.sleep;
      case 'blood_pressure':
        return HealthRecordType.bloodPressure;
      case 'blood_glucose':
        return HealthRecordType.bloodGlucose;
      case 'weight':
        return HealthRecordType.weight;
      default:
        return HealthRecordType.steps;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HealthRecordModel
// ──────────────────────────────────────────────────────────────────────────────

class HealthRecordModel {
  const HealthRecordModel({
    required this.id,
    required this.type,
    required this.value,
    this.valueSecondary, // 혈압 이완기 등 부가 수치
    required this.unit,
    this.source,
    required this.recordedAt,
  });

  final String id;
  final HealthRecordType type;
  final double value;
  final double? valueSecondary;
  final String unit;
  final String? source; // 'manual' | 'device' | 앱명
  final DateTime recordedAt;

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String,
      type: HealthRecordTypeX.fromString(json['type'] as String?),
      value: (json['value'] as num).toDouble(),
      valueSecondary: (json['value_secondary'] as num?)?.toDouble(),
      unit: json['unit'] as String,
      source: json['source'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.apiKey,
        'value': value,
        if (valueSecondary != null) 'value_secondary': valueSecondary,
        'unit': unit,
        if (source != null) 'source': source,
        'recorded_at': recordedAt.toIso8601String(),
      };

  /// 혈압처럼 두 값이 있는 경우 표시 문자열 반환
  String get displayValue {
    if (type == HealthRecordType.bloodPressure && valueSecondary != null) {
      return '${value.toStringAsFixed(0)}/${valueSecondary!.toStringAsFixed(0)}';
    }
    if (type == HealthRecordType.weight || type == HealthRecordType.sleep) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(0);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AddHealthRecordDto — 건강 기록 추가 요청 DTO
// ──────────────────────────────────────────────────────────────────────────────

class AddHealthRecordDto {
  const AddHealthRecordDto({
    required this.type,
    required this.value,
    this.valueSecondary,
    this.source = 'manual',
  });

  final HealthRecordType type;
  final double value;
  final double? valueSecondary;
  final String source;

  Map<String, dynamic> toJson() => {
        'type': type.apiKey,
        'value': value,
        if (valueSecondary != null) 'value_secondary': valueSecondary,
        'unit': type.unit,
        'source': source,
        'recorded_at': DateTime.now().toIso8601String(),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// HealthSummary — 단일 타입 집계 요약
// ──────────────────────────────────────────────────────────────────────────────

class HealthSummary {
  const HealthSummary({
    required this.type,
    required this.average,
    required this.sum,
    required this.count,
    this.latest,
  });

  final HealthRecordType type;
  final double average;
  final double sum;
  final int count;
  final HealthRecordModel? latest; // 가장 최근 기록

  factory HealthSummary.fromRecords(
    HealthRecordType type,
    List<HealthRecordModel> records,
  ) {
    if (records.isEmpty) {
      return HealthSummary(type: type, average: 0, sum: 0, count: 0);
    }
    final sorted = [...records]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final sum = records.fold<double>(0, (acc, r) => acc + r.value);
    return HealthSummary(
      type: type,
      average: sum / records.length,
      sum: sum,
      count: records.length,
      latest: sorted.first,
    );
  }

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      type: HealthRecordTypeX.fromString(json['type'] as String?),
      average: (json['average'] as num?)?.toDouble() ?? 0,
      sum: (json['sum'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
      latest: json['latest'] != null
          ? HealthRecordModel.fromJson(
              json['latest'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HealthSnapshot — 모든 타입의 최신 스냅샷
// ──────────────────────────────────────────────────────────────────────────────

class HealthSnapshot {
  const HealthSnapshot({
    required this.records,
    required this.from,
    required this.to,
  });

  /// 타입별 최신 기록 목록 (key: HealthRecordType.apiKey)
  final Map<HealthRecordType, List<HealthRecordModel>> records;
  final DateTime from;
  final DateTime to;

  List<HealthRecordModel> forType(HealthRecordType type) =>
      records[type] ?? [];

  HealthRecordModel? latestFor(HealthRecordType type) {
    final list = forType(type);
    if (list.isEmpty) return null;
    final sorted = [...list]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return sorted.first;
  }

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as Map<String, dynamic>? ?? {};
    final Map<HealthRecordType, List<HealthRecordModel>> parsed = {};
    for (final entry in rawRecords.entries) {
      final type = HealthRecordTypeX.fromString(entry.key);
      final list = (entry.value as List<dynamic>)
          .map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
      parsed[type] = list;
    }
    return HealthSnapshot(
      records: parsed,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
    );
  }

  /// 빈 스냅샷 (로딩 전 초기값용)
  factory HealthSnapshot.empty() => HealthSnapshot(
        records: {},
        from: DateTime.now().subtract(const Duration(days: 7)),
        to: DateTime.now(),
      );
}

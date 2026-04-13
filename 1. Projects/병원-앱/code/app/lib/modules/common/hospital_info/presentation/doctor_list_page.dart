import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/hospital_model.dart';
import '../providers/hospital_provider.dart';

/// 의료진 목록 화면
///
/// - 상단 진료과 필터 칩
/// - 의사 카드 (사진 아바타 · 이름 · 전공 · 진료과)
/// - 예약하기 버튼
class DoctorListPage extends ConsumerStatefulWidget {
  const DoctorListPage({super.key});

  @override
  ConsumerState<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends ConsumerState<DoctorListPage> {
  String? _selectedDepartmentId;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final doctorsAsync = ref.watch(doctorsProvider(_selectedDepartmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('의료진')),
      body: Column(
        children: [
          // ── 진료과 필터 칩 ─────────────────────────────
          departmentsAsync.when(
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (departments) => _DepartmentFilterBar(
              departments: departments,
              selectedId: _selectedDepartmentId,
              onSelected: (id) => setState(() => _selectedDepartmentId = id),
            ),
          ),

          // ── 의사 목록 ──────────────────────────────────
          Expanded(
            child: doctorsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '의료진 정보를 불러오지 못했습니다.',
                onRetry: () =>
                    ref.invalidate(doctorsProvider(_selectedDepartmentId)),
              ),
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const _EmptyDoctors();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(doctorsProvider(_selectedDepartmentId));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _DoctorCard(doctor: doctors[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 진료과 필터 바
// ──────────────────────────────────────────────────────────────────────────────

class _DepartmentFilterBar extends StatelessWidget {
  const _DepartmentFilterBar({
    required this.departments,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DepartmentModel> departments;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // '전체' 칩
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('전체'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
              selectedColor: cs.primaryContainer,
              checkmarkColor: cs.onPrimaryContainer,
              labelStyle: TextStyle(
                color: selectedId == null
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
                fontWeight: selectedId == null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          // 진료과별 칩
          ...departments.where((d) => d.isActive).map((dept) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(dept.name),
                  selected: selectedId == dept.id,
                  onSelected: (_) => onSelected(dept.id),
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.onPrimaryContainer,
                  labelStyle: TextStyle(
                    color: selectedId == dept.id
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontWeight: selectedId == dept.id
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 의사 카드
// ──────────────────────────────────────────────────────────────────────────────

class _DoctorCard extends ConsumerWidget {
  const _DoctorCard({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 진료과 이름 조회
    final departmentsAsync = ref.watch(departmentsProvider);
    final deptName = departmentsAsync.valueOrNull
            ?.where((d) => d.id == doctor.departmentId)
            .firstOrNull
            ?.name ??
        doctor.departmentId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 프로필 사진 아바타 ─────────────────────
            _DoctorAvatar(
              imageUrl: doctor.profileImageUrl,
              name: doctor.name,
              size: 64,
            ),
            const SizedBox(width: 16),

            // ── 정보 ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${doctor.name} 원장',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (!doctor.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '휴진',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 전공
                  Text(
                    doctor.specialty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 진료과 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deptName,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  if (doctor.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      doctor.bio,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 예약하기 버튼
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: doctor.isAvailable
                          ? () => context.push(
                                '/booking',
                                extra: {'doctorId': doctor.id},
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text('예약하기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 의사 아바타
// ──────────────────────────────────────────────────────────────────────────────

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
    required this.name,
    required this.size,
    this.imageUrl,
  });

  final String? imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = name.isNotEmpty ? name[0] : '?';

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _fallback(cs, size, initials),
        ),
      );
    }

    return _fallback(cs, size, initials);
  }

  Widget _fallback(ColorScheme cs, double size, String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 빈 상태 / 오류
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyDoctors extends StatelessWidget {
  const _EmptyDoctors();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            '해당 진료과 의료진이 없습니다.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 52)),
          ),
        ],
      ),
    );
  }
}

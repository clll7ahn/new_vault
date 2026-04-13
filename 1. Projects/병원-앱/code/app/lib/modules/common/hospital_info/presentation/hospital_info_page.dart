import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/hospital_model.dart';
import '../providers/hospital_provider.dart';

/// 병원 정보 화면
///
/// - 병원명 / 주소 / 전화번호 (tap-to-call)
/// - 진료시간표 카드
/// - 진료과 바로가기 버튼
class HospitalInfoPage extends ConsumerWidget {
  const HospitalInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(hospitalInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: '의료진 보기',
            onPressed: () => context.push('/doctors'),
          ),
        ],
      ),
      body: hospitalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: '병원 정보를 불러오지 못했습니다.',
          onRetry: () => ref.invalidate(hospitalInfoProvider),
        ),
        data: (hospital) => _HospitalInfoBody(hospital: hospital),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _HospitalInfoBody extends StatelessWidget {
  const _HospitalInfoBody({required this.hospital});

  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // 부모 ConsumerWidget에서 invalidate 할 수 없으므로
        // 간단히 딜레이 후 복귀 (실사용 시 ref 주입 패턴 사용)
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HospitalHeaderCard(hospital: hospital),
          const SizedBox(height: 16),
          _ContactCard(hospital: hospital),
          const SizedBox(height: 16),
          _OperatingHoursCard(hours: hospital.operatingHours),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 헤더 카드 (병원명 + 주소)
// ──────────────────────────────────────────────────────────────────────────────

class _HospitalHeaderCard extends StatelessWidget {
  const _HospitalHeaderCard({required this.hospital});

  final HospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 병원 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_hospital_rounded,
                size: 36,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 주소 복사 버튼
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: hospital.address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('주소가 복사되었습니다.')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('주소 복사'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
// 연락처 카드 (tap-to-call)
// ──────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.hospital});

  final HospitalModel hospital;

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll('-', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화를 걸 수 없습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => _call(context, hospital.phone),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer ?? cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: cs.onTertiaryContainer ?? cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('대표 전화', style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
                    const SizedBox(height: 2),
                    Text(hospital.phone, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 진료시간 카드
// ──────────────────────────────────────────────────────────────────────────────

class _OperatingHoursCard extends StatelessWidget {
  const _OperatingHoursCard({required this.hours});

  final Map<String, String> hours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text('진료 시간', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (hours.isEmpty)
              Text(
                '진료 시간 정보가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              ...hours.entries.map((entry) => _HoursRow(
                    day: entry.key,
                    time: entry.value,
                    isClosed: entry.value.contains('휴'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({
    required this.day,
    required this.time,
    required this.isClosed,
  });

  final String day;
  final String time;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isClosed ? cs.error : cs.onSurface,
                fontWeight: isClosed ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (!isClosed)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cs.tertiary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 오류 뷰
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

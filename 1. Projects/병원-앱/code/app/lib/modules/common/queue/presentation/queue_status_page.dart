import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/queue_model.dart';
import '../providers/queue_provider.dart';

/// 대기 현황 페이지
///
/// 킬러 UX:
/// - 상단: 큰 숫자(48sp+)로 내 순번 표시
/// - 중단: "앞에 N명 대기 중 · 약 N분" 정보
/// - 진행바: 전체 대기 중 내 위치 시각화
/// - 상태별 색상: 대기=회색, 호출=파란, 진료중=초록
/// - 하단: 대기 취소 버튼
/// - RefreshIndicator로 수동 새로고침
class QueueStatusPage extends ConsumerWidget {
  const QueueStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(myQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('대기 현황'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: queueAsync.when(
        loading: () => const _QueueLoadingSkeleton(),
        error: (e, _) => _QueueErrorView(
          message: _parseError(e),
          onRetry: () =>
              ref.read(myQueueProvider.notifier).refresh(),
        ),
        data: (entry) => entry == null
            ? _QueueEmptyView(
                onCheckIn: () => _showCheckInDialog(context, ref),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(myQueueProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: _QueueContent(entry: entry),
                ),
              ),
      ),
    );
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('network')) {
      return '네트워크 연결을 확인해 주세요.';
    }
    if (msg.contains('401')) return '로그인이 필요합니다.';
    return '대기 현황을 불러올 수 없습니다.';
  }

  void _showCheckInDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CheckInSheet(
        onCheckIn: (doctorId, departmentId, appointmentId) async {
          Navigator.pop(context);
          await ref.read(myQueueProvider.notifier).checkIn(
                CheckInDto(
                  doctorId: doctorId,
                  departmentId: departmentId,
                  appointmentId: appointmentId,
                ),
              );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 대기 정보 메인 콘텐츠
// ──────────────────────────────────────────────────────────────────────────────

class _QueueContent extends ConsumerWidget {
  const _QueueContent({required this.entry});

  final QueueEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _statusColor(cs, entry.status);

    return Column(
      children: [
        // ── 상태 카드 ───────────────────────────────────────────────────────
        _StatusHeader(entry: entry, statusColor: statusColor),
        const SizedBox(height: 24),

        // ── 순번 & 대기 정보 ─────────────────────────────────────────────────
        _QueueNumberCard(entry: entry, statusColor: statusColor),
        const SizedBox(height: 20),

        // ── 진행바 ───────────────────────────────────────────────────────────
        if (entry.waitingAhead != null)
          _WaitingProgressBar(entry: entry, statusColor: statusColor),
        if (entry.waitingAhead != null) const SizedBox(height: 24),

        // ── 진료 정보 ────────────────────────────────────────────────────────
        _InfoCard(entry: entry),
        const SizedBox(height: 32),

        // ── 대기 취소 버튼 ───────────────────────────────────────────────────
        if (entry.status == QueueStatus.waiting ||
            entry.status == QueueStatus.called)
          _CancelButton(entryId: entry.id),

        const SizedBox(height: 16),
      ],
    );
  }

  Color _statusColor(ColorScheme cs, QueueStatus status) {
    switch (status) {
      case QueueStatus.waiting:
        return cs.outline; // 회색
      case QueueStatus.called:
        return cs.primary; // 파란색
      case QueueStatus.inProgress:
        return const Color(0xFF2E7D32); // 초록색
      case QueueStatus.completed:
        return cs.secondary;
      case QueueStatus.cancelled:
        return cs.error;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 상태 헤더 배지
// ──────────────────────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.entry, required this.statusColor});

  final QueueEntryModel entry;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.status.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 큰 순번 카드
// ──────────────────────────────────────────────────────────────────────────────

class _QueueNumberCard extends StatelessWidget {
  const _QueueNumberCard({required this.entry, required this.statusColor});

  final QueueEntryModel entry;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Text(
              '내 번호',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // 48sp+ 큰 순번 표시
            Text(
              '${entry.queueNumber}번',
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: statusColor,
                height: 1.1,
              ),
            ),
            if (entry.waitingAhead != null || entry.estimatedWaitMin != null) ...[
              const SizedBox(height: 16),
              _WaitingInfoText(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// "앞에 N명 대기 중 · 약 N분" 텍스트
// ──────────────────────────────────────────────────────────────────────────────

class _WaitingInfoText extends StatelessWidget {
  const _WaitingInfoText({required this.entry});

  final QueueEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final parts = <String>[];
    if (entry.waitingAhead != null) {
      parts.add('앞에 ${entry.waitingAhead}명 대기 중');
    }
    if (entry.estimatedWaitMin != null) {
      final min = entry.estimatedWaitMin!;
      if (min < 1) {
        parts.add('곧 호출 예정');
      } else {
        parts.add('약 $min분');
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        parts.join(' · '),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 대기 진행바
// ──────────────────────────────────────────────────────────────────────────────

class _WaitingProgressBar extends StatelessWidget {
  const _WaitingProgressBar({required this.entry, required this.statusColor});

  final QueueEntryModel entry;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ahead = entry.waitingAhead ?? 0;
    // 내 위치 = 전체 대기(앞사람 + 나) 중에서 진행된 비율
    // totalBefore = ahead + 1 (나 포함 기준)
    // 진행 비율 = 0 / (ahead + 1) → 앞에 ahead명이 남아 있으므로
    // 진행된 인원 = 전체 - (ahead + 1), 최소 0
    final total = entry.queueNumber; // 내 번호를 전체 기준으로 사용
    final progress = total > 1
        ? (total - ahead - 1).clamp(0, total - 1) / (total - 1).toDouble()
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '대기 위치',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '${entry.queueNumber}번 / 전체 대기',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            minHeight: 12,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '시작',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '내 차례',
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 진료 정보 카드
// ──────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.entry});

  final QueueEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rows = <({IconData icon, String label, String value})>[];

    if (entry.doctorName != null) {
      rows.add((
        icon: Icons.person_outlined,
        label: '담당의',
        value: '${entry.doctorName} 원장',
      ));
    }
    if (entry.departmentName != null) {
      rows.add((
        icon: Icons.local_hospital_outlined,
        label: '진료과',
        value: entry.departmentName!,
      ));
    }
    if (entry.checkInAt != null) {
      rows.add((
        icon: Icons.login_outlined,
        label: '체크인',
        value: _formatTime(entry.checkInAt!),
      ));
    }
    if (entry.calledAt != null) {
      rows.add((
        icon: Icons.campaign_outlined,
        label: '호출 시각',
        value: _formatTime(entry.calledAt!),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: rows
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(r.icon, size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        r.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        r.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 대기 취소 버튼
// ──────────────────────────────────────────────────────────────────────────────

class _CancelButton extends ConsumerWidget {
  const _CancelButton({required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancel(context, ref),
        icon: Icon(Icons.cancel_outlined, color: cs.error),
        label: Text(
          '대기 취소',
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.error),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('대기 취소'),
        content: const Text('정말 대기를 취소하시겠습니까?\n취소 후 다시 줄을 서야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(myQueueProvider.notifier).cancel(entryId);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 대기 없음 뷰
// ──────────────────────────────────────────────────────────────────────────────

class _QueueEmptyView extends StatelessWidget {
  const _QueueEmptyView({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_outlined,
              size: 72,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              '현재 대기 중이 아닙니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '병원에 도착하셨다면\n대기 등록을 해주세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onCheckIn,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('대기 등록'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 에러 뷰
// ──────────────────────────────────────────────────────────────────────────────

class _QueueErrorView extends StatelessWidget {
  const _QueueErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 로딩 스켈레톤
// ──────────────────────────────────────────────────────────────────────────────

class _QueueLoadingSkeleton extends StatelessWidget {
  const _QueueLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _Skeleton(height: 48, width: double.infinity, cs: cs,
              borderRadius: 16),
          const SizedBox(height: 24),
          _Skeleton(height: 200, width: double.infinity, cs: cs,
              borderRadius: 24),
          const SizedBox(height: 20),
          _Skeleton(height: 12, width: double.infinity, cs: cs,
              borderRadius: 8),
          const SizedBox(height: 20),
          _Skeleton(height: 140, width: double.infinity, cs: cs,
              borderRadius: 16),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({
    required this.height,
    required this.width,
    required this.cs,
    required this.borderRadius,
  });

  final double height;
  final double width;
  final ColorScheme cs;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 체크인 BottomSheet (간단 폼)
// ──────────────────────────────────────────────────────────────────────────────

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({required this.onCheckIn});

  final Future<void> Function(
    String doctorId,
    String departmentId,
    String? appointmentId,
  ) onCheckIn;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final _doctorIdCtrl = TextEditingController();
  final _deptIdCtrl = TextEditingController();
  final _apptIdCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _doctorIdCtrl.dispose();
    _deptIdCtrl.dispose();
    _apptIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final doctorId = _doctorIdCtrl.text.trim();
    final deptId = _deptIdCtrl.text.trim();
    if (doctorId.isEmpty || deptId.isEmpty) return;

    setState(() => _loading = true);
    await widget.onCheckIn(
      doctorId,
      deptId,
      _apptIdCtrl.text.trim().isEmpty ? null : _apptIdCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('대기 등록', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _doctorIdCtrl,
            decoration: const InputDecoration(
              labelText: '의사 ID',
              hintText: 'doctor-uuid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deptIdCtrl,
            decoration: const InputDecoration(
              labelText: '진료과 ID',
              hintText: 'dept-uuid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apptIdCtrl,
            decoration: const InputDecoration(
              labelText: '예약 ID (선택)',
              hintText: 'appointment-uuid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('등록하기',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

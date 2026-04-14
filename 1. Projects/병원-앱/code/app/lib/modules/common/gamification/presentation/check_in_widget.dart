import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gamification_provider.dart';

/// 출석 체크 버튼 위젯
///
/// 홈 페이지 또는 게이미피케이션 페이지에서 공용으로 사용 가능.
/// 상태에 따라 버튼 텍스트/색상이 변경되며,
/// 성공/이미완료 시 스낵바를 표시합니다.
class CheckInWidget extends ConsumerWidget {
  const CheckInWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 상태 변화 리스닝 → 스낵바
    ref.listen(checkInProvider, (prev, next) {
      if (!context.mounted) return;
      if (next is CheckInSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '출석 체크 완료! +${next.pointsEarned}P 적립',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onInverseSurface),
                ),
              ],
            ),
          ),
        );
        ref.read(checkInProvider.notifier).reset();
      } else if (next is CheckInAlreadyDone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '오늘은 이미 출석 체크를 완료했습니다.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onInverseSurface),
            ),
          ),
        );
        ref.read(checkInProvider.notifier).reset();
      } else if (next is CheckInError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
          ),
        );
        ref.read(checkInProvider.notifier).reset();
      }
    });

    final isLoading = checkInState is CheckInLoading;
    final isDone = checkInState is CheckInAlreadyDone ||
        checkInState is CheckInSuccess;

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading || isDone
            ? null
            : () => ref.read(checkInProvider.notifier).checkIn(),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isDone
                    ? Icons.check_circle_outline
                    : Icons.calendar_today_outlined,
                size: 20,
              ),
        label: Text(
          isLoading
              ? '처리 중…'
              : isDone
                  ? '출석 완료'
                  : '오늘 출석 체크',
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: isDone ? cs.surfaceContainerHighest : cs.primary,
          foregroundColor:
              isDone ? cs.onSurfaceVariant : cs.onPrimary,
          disabledBackgroundColor:
              isDone ? cs.surfaceContainerHighest : null,
          disabledForegroundColor:
              isDone ? cs.onSurfaceVariant : null,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/gamification_provider.dart';

/// 출석 체크 버튼 위젯
///
/// - 일일 1회 출석 체크
/// - 완료 시 비활성화 + 체크 아이콘 표시
/// - 성공/이미완료/오류 시 SnackBar 표시
/// - 최소 터치 타겟 48dp 보장
class CheckInButton extends ConsumerWidget {
  const CheckInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkInProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    final isLoading = state is CheckInLoading;
    final isDone =
        state is CheckInAlreadyDone || state is CheckInSuccess;

    return SizedBox(
      width: double.infinity,
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
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDone ? cs.onSurfaceVariant : cs.onPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor:
              isDone ? cs.surfaceContainerHighest : cs.primary,
          foregroundColor:
              isDone ? cs.onSurfaceVariant : cs.onPrimary,
          disabledBackgroundColor:
              isDone ? cs.surfaceContainerHighest : null,
          disabledForegroundColor:
              isDone ? cs.onSurfaceVariant : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

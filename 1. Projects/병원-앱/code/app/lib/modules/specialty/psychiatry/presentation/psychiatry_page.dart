import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/psychiatry_model.dart';
import '../providers/psychiatry_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PsychiatryPage
// ──────────────────────────────────────────────────────────────────────────────

class PsychiatryPage extends ConsumerWidget {
  const PsychiatryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정신건강'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(moodLogsProvider);
              ref.invalidate(sleepLogsProvider);
              ref.invalidate(crisisResourcesProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(moodLogsProvider);
          ref.invalidate(sleepLogsProvider);
          ref.invalidate(crisisResourcesProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            // 위기 핫라인 — 최상단 고정
            _CrisisHotlineCard(),
            SizedBox(height: 0),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MoodTrackerSection(),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SleepLogSection(),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 위기 핫라인 카드 (상단 고정, 빨간 카드)
// ──────────────────────────────────────────────────────────────────────────────

class _CrisisHotlineCard extends ConsumerWidget {
  const _CrisisHotlineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(crisisResourcesProvider);
    final theme = Theme.of(context);

    // 로딩/오류 시에도 기본 리소스 보여줌
    final resources = async.whenOrNull(data: (r) => r) ??
        kDefaultCrisisResources;

    return Container(
      color: const Color(0xFFDC2626),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency_outlined,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                '위기 상담 핫라인 (24시간)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resources.take(4).map((r) => _HotlineTile(r)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HotlineTile extends StatelessWidget {
  const _HotlineTile(this.resource);
  final CrisisResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _call(resource.phoneNumber),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resource.phoneNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  resource.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _call(String number) {
    // 실제 전화 연결은 url_launcher 플러그인 필요
    // url_launcher 없이 HapticFeedback 제공
    HapticFeedback.mediumImpact();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 기분 트래커 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _MoodTrackerSection extends ConsumerStatefulWidget {
  const _MoodTrackerSection();

  @override
  ConsumerState<_MoodTrackerSection> createState() =>
      _MoodTrackerSectionState();
}

class _MoodTrackerSectionState extends ConsumerState<_MoodTrackerSection> {
  MoodLevel? _selectedMood;
  final _memoCtrl = TextEditingController();

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(moodLogsProvider);
    final addState = ref.watch(moodAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is MoodAddLoading;

    // 성공 시 선택 초기화
    ref.listen(moodAddProvider, (prev, next) {
      if (next is MoodAddSuccess) {
        setState(() {
          _selectedMood = null;
          _memoCtrl.clear();
        });
        ref.read(moodAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기분이 기록되었습니다.')),
        );
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('기분 트래커', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),

            // 이모지 선택 그리드
            Text(
              '지금 기분은 어때요?',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: MoodLevel.values.map((level) {
                final selected = _selectedMood == level;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: cs.primary, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          level.emoji,
                          style: TextStyle(
                            fontSize: selected ? 28 : 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // 선택된 기분 레이블
            if (_selectedMood != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _selectedMood!.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            // 한줄 메모
            TextField(
              controller: _memoCtrl,
              maxLength: 100,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: '한줄 메모 (선택)',
                hintText: '지금 어떤 감정인지 적어보세요...',
                counterStyle: theme.textTheme.labelSmall,
              ),
            ),
            const SizedBox(height: 12),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_selectedMood == null || isLoading) ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('기분 기록'),
              ),
            ),

            // 최근 기분 기록
            const SizedBox(height: 20),
            Text(
              '최근 기분 기록',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '기분 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(moodLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text(
                    '기록이 없습니다.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  );
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                return Column(
                  children: sorted.take(5).map(_MoodLogTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedMood == null) return;
    ref.read(moodAddProvider.notifier).add(
          AddMoodLogDto(
            mood: _selectedMood!,
            memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
          ),
        );
  }
}

class _MoodLogTile extends StatelessWidget {
  const _MoodLogTile(this.log);
  final MoodLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(log.mood.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.mood.label, style: theme.textTheme.bodyMedium),
                    Text(
                      DateFormat('M/d HH:mm').format(log.recordedAt.toLocal()),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (log.memo != null)
                  Text(
                    log.memo!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 수면 일지 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _SleepLogSection extends ConsumerStatefulWidget {
  const _SleepLogSection();

  @override
  ConsumerState<_SleepLogSection> createState() => _SleepLogSectionState();
}

class _SleepLogSectionState extends ConsumerState<_SleepLogSection> {
  DateTime? _bedtime;
  DateTime? _wakeTime;
  int _quality = 3; // 1~5

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sleepLogsProvider);
    final addState = ref.watch(sleepAddProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = addState is SleepAddLoading;

    ref.listen(sleepAddProvider, (prev, next) {
      if (next is SleepAddSuccess) {
        setState(() {
          _bedtime = null;
          _wakeTime = null;
          _quality = 3;
        });
        ref.read(sleepAddProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수면 기록이 저장되었습니다.')),
        );
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 8),
                Text('수면 일지', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),

            // 취침/기상 시간 피커
            Row(
              children: [
                Expanded(
                  child: _TimePickerButton(
                    label: '취침 시간',
                    time: _bedtime,
                    icon: Icons.bedtime_outlined,
                    onTap: () => _pickTime(isBedtime: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerButton(
                    label: '기상 시간',
                    time: _wakeTime,
                    icon: Icons.wb_sunny_outlined,
                    onTap: () => _pickTime(isBedtime: false),
                  ),
                ),
              ],
            ),

            // 수면 시간 계산
            if (_bedtime != null && _wakeTime != null) ...[
              const SizedBox(height: 12),
              Center(
                child: _SleepDurationBadge(
                    bedtime: _bedtime!, wakeTime: _wakeTime!),
              ),
            ],

            const SizedBox(height: 16),
            // 수면 품질 슬라이더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '수면 품질',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _qualityLabel(_quality),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: _quality.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _qualityLabel(_quality),
              onChanged: (v) => setState(() => _quality = v.round()),
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_bedtime == null || _wakeTime == null || isLoading)
                    ? null
                    : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('수면 기록'),
              ),
            ),

            // 최근 수면 기록
            const SizedBox(height: 20),
            Text(
              '최근 수면 기록',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorRetry(
                message: '수면 기록을 불러오지 못했습니다.',
                onRetry: () => ref.invalidate(sleepLogsProvider),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Text(
                    '기록이 없습니다.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  );
                }
                final sorted = [...logs]
                  ..sort((a, b) => b.bedtime.compareTo(a.bedtime));
                return Column(
                  children: sorted.take(5).map(_SleepLogTile.new).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _qualityLabel(int q) {
    switch (q) {
      case 1:
        return '매우 나쁨';
      case 2:
        return '나쁨';
      case 3:
        return '보통';
      case 4:
        return '좋음';
      case 5:
        return '매우 좋음';
      default:
        return '보통';
    }
  }

  Future<void> _pickTime({required bool isBedtime}) async {
    final now = DateTime.now();
    final initial = isBedtime
        ? _bedtime ?? DateTime(now.year, now.month, now.day, 23, 0)
        : _wakeTime ?? DateTime(now.year, now.month, now.day + 1, 7, 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isBedtime ? '취침 시간 선택' : '기상 시간 선택',
    );

    if (picked == null) return;

    final result = DateTime(
      now.year,
      now.month,
      isBedtime ? now.day : now.day + 1,
      picked.hour,
      picked.minute,
    );
    setState(() {
      if (isBedtime) {
        _bedtime = result;
      } else {
        _wakeTime = result;
      }
    });
  }

  void _submit() {
    if (_bedtime == null || _wakeTime == null) return;
    ref.read(sleepAddProvider.notifier).add(
          AddSleepLogDto(
            bedtime: _bedtime!,
            wakeTime: _wakeTime!,
            sleepQuality: _quality,
          ),
        );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime? time;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasTime = time != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasTime
              ? cs.primary.withOpacity(0.08)
              : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? cs.primary.withOpacity(0.4) : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasTime ? cs.primary : cs.outline, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  hasTime
                      ? DateFormat('HH:mm').format(time!)
                      : '미설정',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: hasTime ? cs.primary : cs.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepDurationBadge extends StatelessWidget {
  const _SleepDurationBadge({
    required this.bedtime,
    required this.wakeTime,
  });

  final DateTime bedtime;
  final DateTime wakeTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minutes = wakeTime.difference(bedtime).inMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final durationLabel = mins == 0 ? '$hours시간' : '$hours시간 $mins분';
    final isAdequate = hours >= 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isAdequate
            ? const Color(0xFF16A34A).withOpacity(0.1)
            : cs.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdequate ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 18,
            color: isAdequate ? const Color(0xFF16A34A) : cs.error,
          ),
          const SizedBox(width: 6),
          Text(
            '수면 시간: $durationLabel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isAdequate ? const Color(0xFF16A34A) : cs.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SleepLogTile extends StatelessWidget {
  const _SleepLogTile(this.log);
  final SleepLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final timeFmt = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.nightlight, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${timeFmt.format(log.bedtime.toLocal())} → '
                      '${timeFmt.format(log.wakeTime.toLocal())}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      log.durationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('M월 d일').format(log.bedtime.toLocal()),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (log.sleepQuality != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < log.sleepQuality! ? Icons.star : Icons.star_border,
                  size: 14,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 오류 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

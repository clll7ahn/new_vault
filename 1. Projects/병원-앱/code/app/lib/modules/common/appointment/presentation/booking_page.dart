import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../hospital_info/domain/hospital_model.dart';
import '../../hospital_info/providers/hospital_provider.dart';
import '../domain/appointment_model.dart';
import '../providers/appointment_provider.dart';

/// 예약 화면 — 3단계 Stepper
///
/// Step 1: 진료과 선택
/// Step 2: 의사 선택
/// Step 3: 날짜/시간 + 증상 입력 → 예약 확정
///
/// 진입 시 extra로 {'doctorId': String} 전달 가능 (의사 카드에서 바로 예약)
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key, this.initialDoctorId});

  /// 의사 카드에서 진입할 때 미리 지정
  final String? initialDoctorId;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  int _currentStep = 0;

  // ── 선택 상태 ─────────────────────────────────────────────────────────────
  DepartmentModel? _selectedDept;
  DoctorModel? _selectedDoctor;
  SlotModel? _selectedSlot;
  DateTime _selectedDate = DateTime.now();
  final _symptomsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 의사 ID가 미리 지정된 경우 Step 3으로 스킵
    if (widget.initialDoctorId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillDoctor(widget.initialDoctorId!);
      });
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _prefillDoctor(String doctorId) {
    // 의사 정보 로드 후 dept / doctor 자동 선택
    ref.read(doctorDetailProvider(doctorId)).whenData((doctor) {
      ref.read(departmentsProvider).whenData((depts) {
        final dept = depts.where((d) => d.id == doctor.departmentId).firstOrNull;
        setState(() {
          _selectedDept = dept;
          _selectedDoctor = doctor;
          _currentStep = 2; // 날짜/시간 선택으로 이동
        });
      });
    });
  }

  // ── 스텝 유효성 ───────────────────────────────────────────────────────────

  bool get _canContinueStep0 => _selectedDept != null;
  bool get _canContinueStep1 => _selectedDoctor != null;
  bool get _canContinueStep2 => _selectedSlot != null;

  // ── 예약 확정 ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedDoctor == null ||
        _selectedDept == null ||
        _selectedSlot == null) {
      return;
    }

    final dto = CreateAppointmentDto(
      doctorId: _selectedDoctor!.id,
      departmentId: _selectedDept!.id,
      slotId: _selectedSlot!.id,
      symptoms: _symptomsController.text.trim(),
    );

    await ref.read(appointmentCreateProvider.notifier).create(dto);
  }

  @override
  Widget build(BuildContext context) {
    // 예약 결과 처리
    ref.listen<AppointmentCreateState>(appointmentCreateProvider, (_, next) {
      if (next is AppointmentCreateSuccess) {
        ref.read(appointmentCreateProvider.notifier).reset();
        _showSuccessDialog(context);
      } else if (next is AppointmentCreateError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        ref.read(appointmentCreateProvider.notifier).reset();
      }
    });

    final createState = ref.watch(appointmentCreateProvider);
    final isSubmitting = createState is AppointmentCreateLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('예약하기')),
      body: Theme(
        data: Theme.of(context).copyWith(
          // Stepper 내부 색상 재정의
          colorScheme: Theme.of(context).colorScheme.copyWith(
                secondary: Theme.of(context).colorScheme.primary,
              ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            // 이전 스텝으로만 자유 이동 허용
            if (step < _currentStep) {
              setState(() => _currentStep = step);
            }
          },
          controlsBuilder: (context, details) => _StepperControls(
            currentStep: _currentStep,
            totalSteps: 3,
            canContinue: [
              _canContinueStep0,
              _canContinueStep1,
              _canContinueStep2,
            ][_currentStep],
            isSubmitting: isSubmitting,
            onContinue: details.onStepContinue,
            onCancel: details.onStepCancel,
          ),
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
          steps: [
            Step(
              title: const Text('진료과 선택'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
              content: _StepDepartment(
                selected: _selectedDept,
                onSelected: (dept) {
                  setState(() {
                    _selectedDept = dept;
                    // 진료과 바뀌면 의사 / 슬롯 초기화
                    if (_selectedDoctor?.departmentId != dept.id) {
                      _selectedDoctor = null;
                      _selectedSlot = null;
                    }
                  });
                },
              ),
            ),
            Step(
              title: const Text('의사 선택'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
              content: _StepDoctor(
                departmentId: _selectedDept?.id,
                selected: _selectedDoctor,
                onSelected: (doctor) {
                  setState(() {
                    _selectedDoctor = doctor;
                    _selectedSlot = null; // 의사 바뀌면 슬롯 초기화
                  });
                },
              ),
            ),
            Step(
              title: const Text('날짜 · 시간 · 증상'),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: _StepDateTime(
                doctorId: _selectedDoctor?.id,
                selectedDate: _selectedDate,
                selectedSlot: _selectedSlot,
                symptomsController: _symptomsController,
                onDateChanged: (date) =>
                    setState(() {
                      _selectedDate = date;
                      _selectedSlot = null;
                    }),
                onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.tertiary, size: 56),
        title: const Text('예약 완료'),
        content: Text(
          '${_selectedDoctor?.name} 원장님 예약이 완료되었습니다.\n'
          '예약 목록에서 확인하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/appointments');
            },
            style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
            child: const Text('예약 목록 보기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
            child: const Text('홈으로'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Step 1 — 진료과 선택
// ──────────────────────────────────────────────────────────────────────────────

class _StepDepartment extends ConsumerWidget {
  const _StepDepartment({
    required this.selected,
    required this.onSelected,
  });

  final DepartmentModel? selected;
  final ValueChanged<DepartmentModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(departmentsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('진료과 로드 실패: $e'),
      data: (depts) => Column(
        children: depts
            .where((d) => d.isActive)
            .map((dept) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => onSelected(dept),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected?.id == dept.id
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected?.id == dept.id
                              ? cs.primary
                              : cs.outlineVariant,
                          width: selected?.id == dept.id ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            color: selected?.id == dept.id
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dept.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: selected?.id == dept.id
                                          ? cs.onPrimaryContainer
                                          : cs.onSurface,
                                    )),
                                if (dept.description.isNotEmpty)
                                  Text(dept.description,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (selected?.id == dept.id)
                            Icon(Icons.check_circle,
                                color: cs.primary, size: 22),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Step 2 — 의사 선택
// ──────────────────────────────────────────────────────────────────────────────

class _StepDoctor extends ConsumerWidget {
  const _StepDoctor({
    required this.departmentId,
    required this.selected,
    required this.onSelected,
  });

  final String? departmentId;
  final DoctorModel? selected;
  final ValueChanged<DoctorModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (departmentId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('진료과를 먼저 선택해 주세요.'),
      );
    }

    final async = ref.watch(doctorsProvider(departmentId));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('의사 목록 로드 실패: $e'),
      data: (doctors) {
        if (doctors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('선택한 진료과에 의사가 없습니다.'),
          );
        }
        return Column(
          children: doctors
              .map((doctor) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: doctor.isAvailable ? () => onSelected(doctor) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Opacity(
                        opacity: doctor.isAvailable ? 1.0 : 0.5,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected?.id == doctor.id
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected?.id == doctor.id
                                  ? cs.primary
                                  : cs.outlineVariant,
                              width: selected?.id == doctor.id ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _DoctorMiniAvatar(
                                  name: doctor.name,
                                  imageUrl: doctor.profileImageUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${doctor.name} 원장',
                                        style: theme.textTheme.titleSmall),
                                    Text(doctor.specialty,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: cs.primary)),
                                    if (!doctor.isAvailable)
                                      Text('현재 진료 불가',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(color: cs.error)),
                                  ],
                                ),
                              ),
                              if (selected?.id == doctor.id)
                                Icon(Icons.check_circle,
                                    color: cs.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _DoctorMiniAvatar extends StatelessWidget {
  const _DoctorMiniAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = 44.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(imageUrl!, width: size, height: size,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(cs)),
      );
    }
    return _fallback(cs);
  }

  Widget _fallback(ColorScheme cs) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// Step 3 — 날짜 / 시간 / 증상
// ──────────────────────────────────────────────────────────────────────────────

class _StepDateTime extends ConsumerWidget {
  const _StepDateTime({
    required this.doctorId,
    required this.selectedDate,
    required this.selectedSlot,
    required this.symptomsController,
    required this.onDateChanged,
    required this.onSlotSelected,
  });

  final String? doctorId;
  final DateTime selectedDate;
  final SlotModel? selectedSlot;
  final TextEditingController symptomsController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<SlotModel> onSlotSelected;

  static final _displayDateFmt = DateFormat('yyyy년 M월 d일 (E)', 'ko');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 날짜 선택 ──────────────────────────────────────────────────────
        Text('날짜 선택', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
              locale: const Locale('ko'),
            );
            if (picked != null) onDateChanged(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Text(
                  _displayDateFmt.format(selectedDate),
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 시간 슬롯 ────────────────────────────────────────────────────
        Text('시간 선택', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),

        if (doctorId == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('의사를 먼저 선택해 주세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant)),
          )
        else
          _SlotGrid(
            doctorId: doctorId!,
            date: selectedDate,
            selected: selectedSlot,
            onSelected: onSlotSelected,
            timeFmt: _timeFmt,
          ),

        const SizedBox(height: 20),

        // ── 증상 입력 ─────────────────────────────────────────────────────
        Text('증상 입력 (선택)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: symptomsController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '증상이나 방문 이유를 간략히 적어주세요.',
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SlotGrid extends ConsumerWidget {
  const _SlotGrid({
    required this.doctorId,
    required this.date,
    required this.selected,
    required this.onSelected,
    required this.timeFmt,
  });

  final String doctorId;
  final DateTime date;
  final SlotModel? selected;
  final ValueChanged<SlotModel> onSelected;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (doctorId: doctorId, date: date);
    final async = ref.watch(slotsProvider(query));
    final cs = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('슬롯 로드 실패: $e'),
      data: (slots) {
        if (slots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '선택한 날짜에 예약 가능한 시간이 없습니다.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = selected?.id == slot.id;
            final label = timeFmt.format(slot.startTime.toLocal());
            return SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: slot.isAvailable ? () => onSelected(slot) : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor:
                      isSelected ? cs.primaryContainer : null,
                  foregroundColor:
                      isSelected ? cs.onPrimaryContainer : null,
                  side: BorderSide(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(label),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stepper 커스텀 컨트롤
// ──────────────────────────────────────────────────────────────────────────────

class _StepperControls extends StatelessWidget {
  const _StepperControls({
    required this.currentStep,
    required this.totalSteps,
    required this.canContinue,
    required this.isSubmitting,
    required this.onContinue,
    required this.onCancel,
  });

  final int currentStep;
  final int totalSteps;
  final bool canContinue;
  final bool isSubmitting;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canContinue && !isSubmitting ? onContinue : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(isLastStep ? '예약 확정' : '다음'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(currentStep == 0 ? '취소' : '이전'),
            ),
          ),
        ],
      ),
    );
  }
}

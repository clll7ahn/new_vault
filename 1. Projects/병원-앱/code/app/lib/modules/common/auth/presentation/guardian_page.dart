import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/guardian_model.dart';
import '../providers/auth_provider.dart';
import '../providers/guardian_provider.dart';

/// 보호자 관리 화면
///
/// - 내가 보호하는 피보호자 목록 (대리 관리 전환)
/// - 나를 보호하는 보호자 목록
/// - 새 가족 연결 버튼 → 연결 코드 입력 다이얼로그
/// - 대리 관리 모드 전환 드롭다운
class GuardianPage extends ConsumerWidget {
  const GuardianPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProxy = ref.watch(isProxyModeProvider);
    final proxyUser = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('보호자 관리'),
        actions: [
          if (isProxy)
            // 대리 관리 중이면 내 계정 복귀 버튼 표시
            TextButton.icon(
              onPressed: () {
                ref.read(activeAccountProvider.notifier).switchBackToMyAccount();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내 계정으로 돌아왔습니다.')),
                );
              },
              icon: const Icon(Icons.person_outline, color: Colors.white),
              label: const Text('내 계정으로',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── 대리 관리 중 배너 ──────────────────────────────────────────
          if (isProxy && proxyUser != null)
            _ProxyModeBanner(proxyUser: proxyUser),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(dependentsProvider.notifier).refresh(),
                  ref.read(guardiansProvider.notifier).refresh(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _DependentSection(),
                  SizedBox(height: 24),
                  _GuardianSection(),
                  SizedBox(height: 80), // FAB 공간
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLinkDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('가족 연결'),
      ),
    );
  }

  /// 연결 코드 입력 다이얼로그
  void _showLinkDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LinkCodeDialog(ref: ref),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 대리 관리 중 배너
// ──────────────────────────────────────────────────────────────────────────────

class _ProxyModeBanner extends StatelessWidget {
  const _ProxyModeBanner({required this.proxyUser});

  final dynamic proxyUser; // UserModel

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cs.tertiary,
      child: Row(
        children: [
          Icon(Icons.supervisor_account, color: cs.onTertiary, size: 20),
          const SizedBox(width: 8),
          Text(
            '${proxyUser.name} 님 대신 관리 중',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 내가 보호하는 피보호자 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _DependentSection extends ConsumerWidget {
  const _DependentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependentsAsync = ref.watch(dependentsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text('내가 보호하는 가족', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '아래 가족 계정을 대신해서 앱을 사용할 수 있어요.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        dependentsAsync.when(
          loading: () => const _SectionSkeleton(),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return _EmptyTile(
                icon: Icons.person_add_outlined,
                message: '연결된 가족이 없어요.\n아래 버튼으로 가족을 연결해 보세요.',
              );
            }
            return Column(
              children: list
                  .map((link) => _DependentTile(link: link))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DependentTile extends ConsumerWidget {
  const _DependentTile({required this.link});

  final GuardianLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = ref.watch(activeAccountProvider)?.id == link.dependentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor:
              isActive ? cs.primary : cs.secondaryContainer,
          child: Icon(
            Icons.person,
            color: isActive ? cs.onPrimary : cs.onSecondaryContainer,
          ),
        ),
        title: Text(
          link.dependentName ?? link.dependentUserId,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          link.relationship.label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Chip(
                label: const Text('관리 중'),
                backgroundColor: cs.primaryContainer,
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            else
              TextButton(
                onPressed: () async {
                  await ref
                      .read(activeAccountProvider.notifier)
                      .switchToDependentAccount(link.dependentUserId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${link.dependentName ?? '가족'} 계정으로 전환했어요.'),
                      ),
                    );
                  }
                },
                child: const Text('대리 관리'),
              ),
            IconButton(
              icon: Icon(Icons.link_off, color: cs.error, size: 20),
              tooltip: '연결 해제',
              onPressed: () =>
                  _showUnlinkDialog(context, ref, link),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlinkDialog(
      BuildContext context, WidgetRef ref, GuardianLink link) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결 해제'),
        content: Text(
            '${link.dependentName ?? link.dependentUserId} 님과의 보호자 연결을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(dependentsProvider.notifier)
                  .unlink(link.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 나를 보호하는 보호자 섹션
// ──────────────────────────────────────────────────────────────────────────────

class _GuardianSection extends ConsumerWidget {
  const _GuardianSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardiansAsync = ref.watch(guardiansProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text('나를 보호하는 가족', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '이 분들이 여러분의 예약이나 진료를 대신 관리할 수 있어요.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        guardiansAsync.when(
          loading: () => const _SectionSkeleton(),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (list) {
            if (list.isEmpty) {
              return _EmptyTile(
                icon: Icons.shield_outlined,
                message: '연결된 보호자가 없어요.',
              );
            }
            return Column(
              children: list
                  .map((link) => _GuardianTile(link: link))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _GuardianTile extends ConsumerWidget {
  const _GuardianTile({required this.link});

  final GuardianLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.person, color: cs.onSecondaryContainer),
        ),
        title: Text(
          link.guardianName ?? link.guardianUserId,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          link.relationship.label,
          style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: Icon(Icons.link_off, color: cs.error, size: 20),
          tooltip: '연결 해제',
          onPressed: () => _showUnlinkDialog(context, ref, link),
        ),
      ),
    );
  }

  void _showUnlinkDialog(
      BuildContext context, WidgetRef ref, GuardianLink link) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결 해제'),
        content: Text(
            '${link.guardianName ?? link.guardianUserId} 님과의 보호자 연결을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // guardians 측에서 해제 (링크 ID로 삭제)
              await ref
                  .read(guardianRepositoryProvider)
                  .unlinkGuardian(link.id);
              await ref.read(guardiansProvider.notifier).refresh();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 가족 연결 코드 입력 다이얼로그
// ──────────────────────────────────────────────────────────────────────────────

class _LinkCodeDialog extends ConsumerStatefulWidget {
  const _LinkCodeDialog({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_LinkCodeDialog> createState() => _LinkCodeDialogState();
}

class _LinkCodeDialogState extends ConsumerState<_LinkCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  GuardianRelationship _relationship = GuardianRelationship.parent;
  bool _loading = false;
  String? _error;

  // 탭 0 = 코드 입력(내가 보호자가 됨), 탭 1 = 코드 발급(상대가 보호자가 됨)
  int _tab = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('가족 연결', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '연결 코드를 사용해 가족 계정과 보호자 관계를 설정합니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // ── 탭 선택 ────────────────────────────────────────────────
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('코드 입력'), icon: Icon(Icons.input)),
                ButtonSegment(value: 1, label: Text('코드 발급'), icon: Icon(Icons.qr_code)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() {
                _tab = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),

            if (_tab == 0) ...[
              // ── 코드 입력 탭: 내가 보호자가 됨 ──────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: '연결 코드',
                        hintText: '가족에게 받은 6자리 코드',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 12,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '연결 코드를 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GuardianRelationship>(
                      value: _relationship,
                      decoration: const InputDecoration(
                        labelText: '관계',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      items: GuardianRelationship.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _relationship = v);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _loading ? null : _submitLink,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('연결하기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── 코드 발급 탭: 상대가 보호자가 됨 ─────────────────────
              _LinkCodeGeneratePanel(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(guardiansProvider.notifier).link(
            code: _codeCtrl.text.trim(),
            relationship: _relationship,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가족 계정이 연결되었습니다.')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '연결에 실패했습니다. 코드를 확인해 주세요.';
      });
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 코드 발급 패널
// ──────────────────────────────────────────────────────────────────────────────

class _LinkCodeGeneratePanel extends ConsumerWidget {
  const _LinkCodeGeneratePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(linkCodeGeneratorProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return codeAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(
        '코드 발급에 실패했습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
      ),
      data: (linkCode) {
        final remaining = linkCode.expiresAt.difference(DateTime.now());
        final expireMinutes = remaining.inMinutes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '아래 코드를 보호자에게 전달하세요.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      linkCode.code,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_outlined, color: cs.primary),
                    tooltip: '복사',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: linkCode.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('코드가 복사되었습니다.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              expireMinutes > 0
                  ? '${expireMinutes}분 후 만료됩니다.'
                  : '코드가 만료되었습니다. 새로고침 해주세요.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 공통 헬퍼 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        2,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '불러오는 중 오류가 발생했습니다.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

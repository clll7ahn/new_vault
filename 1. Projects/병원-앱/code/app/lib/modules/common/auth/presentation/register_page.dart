import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// 회원가입 화면
///
/// 입력 필드:
/// - 이름 (필수)
/// - 이메일 (필수)
/// - 비밀번호 (필수, 6자 이상)
/// - 비밀번호 확인 (필수)
/// - 전화번호 (선택)
///
/// 어르신 모드 고려:
/// - 최소 56dp 버튼 높이
/// - 명확한 레이블 + 힌트 텍스트
/// - 큰 입력 폰트 (16sp)
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // 오류 메시지 SnackBar
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'),
          tooltip: '로그인으로 돌아가기',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 안내 텍스트 ────────────────────────────
                    Text(
                      '계정을 만들어 주세요',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '아래 정보를 입력하시면 바로 서비스를 이용하실 수 있습니다.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── 이름 ──────────────────────────────────
                    _SectionLabel(label: '이름', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '홍길동',
                        prefixIcon: Icon(Icons.person_outline, size: 24),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해 주세요.';
                        }
                        if (value.trim().length < 2) {
                          return '이름은 2자 이상이어야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 이메일 ────────────────────────────────
                    _SectionLabel(label: '이메일', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        hintText: 'example@hospital.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 24),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이메일을 입력해 주세요.';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return '올바른 이메일 형식을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 비밀번호 ──────────────────────────────
                    _SectionLabel(label: '비밀번호', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: '6자 이상 입력해 주세요',
                        prefixIcon: const Icon(Icons.lock_outline, size: 24),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해 주세요.';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 비밀번호 확인 ──────────────────────────
                    _SectionLabel(label: '비밀번호 확인', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 다시 입력해 주세요',
                        prefixIcon:
                            const Icon(Icons.lock_outline, size: 24),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          tooltip: _obscureConfirmPassword
                              ? '비밀번호 보기'
                              : '비밀번호 숨기기',
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 다시 입력해 주세요.';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── 전화번호 (선택) ───────────────────────
                    _SectionLabel(label: '전화번호', isRequired: false),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onRegister(),
                      decoration: const InputDecoration(
                        hintText: '010-0000-0000 (선택)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 24),
                      ),
                      style: theme.textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // 선택 필드
                        }
                        final phoneRegex = RegExp(r'^01[0-9]-?\d{3,4}-?\d{4}$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return '올바른 전화번호 형식을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // ── 가입 버튼 ──────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : _onRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('가입하기'),
                    ),
                    const SizedBox(height: 20),

                    // ── 로그인으로 돌아가기 ────────────────────
                    Center(
                      child: TextButton(
                        onPressed:
                            isLoading ? null : () => context.go('/login'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('이미 계정이 있으신가요? 로그인'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 섹션 레이블 위젯 (필수 여부 표시 포함)
// ──────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.isRequired,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

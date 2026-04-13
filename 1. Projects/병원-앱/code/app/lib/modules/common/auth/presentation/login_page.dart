import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// 로그인 화면
///
/// - 이메일 + 비밀번호 입력
/// - 로그인 버튼 (최소 56dp 높이, 어르신 터치 타겟)
/// - 회원가입 링크
/// - 로딩/오류 상태 처리
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 로고 / 타이틀 ──────────────────────────
                    _HospitalLogo(colorScheme: colorScheme),
                    const SizedBox(height: 48),

                    // ── 이메일 필드 ────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: '이메일',
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
                    const SizedBox(height: 16),

                    // ── 비밀번호 필드 ──────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLogin(),
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '비밀번호를 입력해 주세요',
                        prefixIcon:
                            const Icon(Icons.lock_outline, size: 24),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
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
                    const SizedBox(height: 32),

                    // ── 로그인 버튼 ────────────────────────────
                    ElevatedButton(
                      onPressed: isLoading ? null : _onLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('로그인'),
                    ),
                    const SizedBox(height: 24),

                    // ── 구분선 ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '또는',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Expanded(child: Divider(color: colorScheme.outlineVariant)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 회원가입 링크 ──────────────────────────
                    OutlinedButton(
                      onPressed:
                          isLoading ? null : () => context.go('/register'),
                      child: const Text('계정이 없으신가요? 회원가입'),
                    ),
                    const SizedBox(height: 16),

                    // ── 비밀번호 찾기 ──────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: 비밀번호 찾기 화면으로 이동
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('준비 중인 기능입니다.'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('비밀번호를 잊으셨나요?'),
                      ),
                    ),
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
// 병원 로고 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _HospitalLogo extends StatelessWidget {
  const _HospitalLogo({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.local_hospital_rounded,
            size: 48,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '병원 앱',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '진료 예약부터 건강 관리까지',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../core/supabase/supabase_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/');
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_privacyAccepted) {
      setState(() => _errorMessage = 'Примите политику конфиденциальности');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/');
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithOAuth(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.signInWithOAuth(
        provider == 'google' ? OAuthProvider.google : OAuthProvider.apple,
        redirectTo: 'com.instiq.app://callback',
      );
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Введите email');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Письмо для сброса пароля отправлено')),
        );
      }
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    }
    setState(() => _isLoading = false);
  }

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.gradientPrimaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradientPrimaryGradient.createShader(bounds),
                child: Text(
                  'InstIQ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Добро пожаловать! AI-контент для Instagram.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 32),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _signInWithOAuth('google'),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: const Text('Войти с Google'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _signInWithOAuth('apple'),
                        icon: const Icon(Icons.apple_rounded, size: 24),
                        label: const Text('Войти с Apple'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'или',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryDark,
                        unselectedLabelColor: isDark ? AppColors.mutedForegroundDark : AppColors.mutedForegroundLight,
                        indicator: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tabs: const [
                          Tab(text: 'Вход'),
                          Tab(text: 'Регистрация'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'example@mail.com',
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Введите email';
                                if (!_emailRegex.hasMatch(v.trim())) return 'Некорректный email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Пароль',
                                hintText: 'Минимум 6 символов',
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Введите пароль';
                                if (v.length < 6) return 'Пароль не менее 6 символов';
                                return null;
                              },
                            ),
                            if (_tabController.index == 1) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _privacyAccepted,
                                    onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                                    activeColor: AppColors.primaryDark,
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Я принимаю '),
                                          TextSpan(
                                            text: 'политику конфиденциальности',
                                            style: TextStyle(color: AppColors.primaryDark, decoration: TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()..onTap = () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.destructiveDark, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 16),
                            GradientButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_tabController.index == 0) {
                                        _signInWithEmail();
                                      } else {
                                        _signUpWithEmail();
                                      }
                                    },
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                                    )
                                  : Text(_tabController.index == 0 ? 'Войти' : 'Зарегистрироваться'),
                            ),
                            if (_tabController.index == 0) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                child: const Text('Забыли пароль?'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/cge_button.dart';
import '../../../widgets/cge_input.dart';

enum AuthMode { signIn, signUp, resetPassword }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _gamertagController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _gamertagController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider.notifier);

      if (_mode == AuthMode.resetPassword) {
        await auth.resetPassword(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent!')),
          );
          setState(() => _mode = AuthMode.signIn);
        }
      } else if (_mode == AuthMode.signIn) {
        await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) context.go('/');
      } else {
        await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          gamertag: _gamertagController.text.trim().isEmpty
              ? null
              : _gamertagController.text.trim(),
        );
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    try {
      await ref.read(authProvider.notifier).signInWithProvider(provider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/cge_logo.png',
                  height: 80,
                ),
              ),

              const SizedBox(height: 40),

              // Mode title
              Text(
                _mode == AuthMode.signIn
                    ? 'Welcome Back'
                    : _mode == AuthMode.signUp
                        ? 'Create Account'
                        : 'Reset Password',
                style: AppTypography.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _mode == AuthMode.signIn
                    ? 'Sign in to continue gaming'
                    : _mode == AuthMode.signUp
                        ? 'Join the CGE community'
                        : 'Enter your email to reset',
                style: AppTypography.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name (sign up only)
                    if (_mode == AuthMode.signUp) ...[
                      CgeInput(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        prefixIcon: LucideIcons.user,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    CgeInput(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: LucideIcons.mail,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    // Password (not for reset)
                    if (_mode != AuthMode.resetPassword) ...[
                      const SizedBox(height: 16),
                      CgeInput(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: LucideIcons.lock,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (_mode == AuthMode.signUp && v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],

                    // Gamertag (sign up only)
                    if (_mode == AuthMode.signUp) ...[
                      const SizedBox(height: 16),
                      CgeInput(
                        label: 'Gamertag (optional)',
                        hint: 'Your gaming alias',
                        controller: _gamertagController,
                        prefixIcon: LucideIcons.gamepad2,
                      ),
                    ],

                    // Forgot password link
                    if (_mode == AuthMode.signIn) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _mode = AuthMode.resetPassword),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    CgeButton(
                      label: _mode == AuthMode.signIn
                          ? 'Sign In'
                          : _mode == AuthMode.signUp
                              ? 'Create Account'
                              : 'Send Reset Email',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                      fullWidth: true,
                      size: CgeButtonSize.lg,
                    ),
                  ],
                ),
              ),

              // Social login (not for reset)
              if (_mode != AuthMode.resetPassword) ...[
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google',
                      onTap: () => _handleSocialLogin(OAuthProvider.google),
                    ),
                    const SizedBox(width: 16),
                    _SocialButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      onTap: () => _handleSocialLogin(OAuthProvider.apple),
                    ),
                    const SizedBox(width: 16),
                    _SocialButton(
                      icon: LucideIcons.messageCircle,
                      label: 'Discord',
                      onTap: () => _handleSocialLogin(OAuthProvider.discord),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Switch mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _mode == AuthMode.signIn
                        ? "Don't have an account?"
                        : _mode == AuthMode.signUp
                            ? 'Already have an account?'
                            : 'Remember your password?',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _mode = _mode == AuthMode.signIn
                            ? AuthMode.signUp
                            : AuthMode.signIn;
                      });
                    },
                    child: Text(
                      _mode == AuthMode.signUp ? 'Sign In' : 'Sign Up',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.text),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

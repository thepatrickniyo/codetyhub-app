import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _acceptedTerms = false;

  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(0);
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openLegal(1);

  void _openLegal(int tab) {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.privacy, arguments: {'tab': tab});
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _authController.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your journey to mastering AI skills',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormField<bool>(
                  initialValue: _acceptedTerms,
                  validator: (_) => _acceptedTerms
                      ? null
                      : 'You must accept the Privacy Policy and Terms to continue',
                  builder: (field) {
                    final linkStyle = TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                key: const Key('signup_terms_checkbox'),
                                value: _acceptedTerms,
                                activeColor: AppColors.primary,
                                side: BorderSide(
                                  color: field.hasError
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                                onChanged: (v) {
                                  setState(() => _acceptedTerms = v ?? false);
                                  field.didChange(_acceptedTerms);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'I have read and agree to the ',
                                    ),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: linkStyle,
                                      recognizer: _privacyTap,
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: linkStyle,
                                      recognizer: _termsTap,
                                    ),
                                    const TextSpan(
                                      text: ', and consent to CodetyHub '
                                          'processing my data as described.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 36),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (_authController.errorMessage.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _authController.errorMessage.value,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Obx(
                  () => PrimaryButton(
                    label: 'Create Account',
                    isLoading: _authController.isLoading.value,
                    onPressed: _handleSignup,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

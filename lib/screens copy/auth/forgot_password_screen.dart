// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/auth_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/primary_button.dart';
import 'otp_verification_screen.dart';

/// Step 1 of the forgot-password flow: collect email/phone, request OTP.
class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/auth/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(_identifierController.text.trim());

    if (!mounted) return;
    if (sent) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AuthColors.lightBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AuthColors.primaryBlue, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AuthColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter your email or phone number and we'll send you "
                      'a one-time code to reset your password.',
                      style: TextStyle(
                          fontSize: 14, color: AuthColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      controller: _identifierController,
                      label: 'Email or Phone Number',
                      icon: Icons.alternate_email,
                      textInputAction: TextInputAction.done,
                      validator: Validators.emailOrPhone,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Send OTP',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
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

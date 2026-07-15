// lib/screens/auth/otp_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/auth_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/auth/primary_button.dart';
import 'reset_password_screen.dart';

/// Step 2: 6-digit OTP entry with resend cooldown.
class OtpVerificationScreen extends StatefulWidget {
  static const routeName = '/auth/verify-otp';

  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int _length = AppConstants.otpLength;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsLeft = AppConstants.otpResendCooldown.inSeconds;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
    _startCooldown();
  }

  void _startCooldown() {
    _secondsLeft = AppConstants.otpResendCooldown.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != _length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter the full $_length-digit code')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_otp);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final identifier = auth.pendingIdentifier;
    if (identifier == null) return;
    final sent = await auth.sendOtp(identifier);
    if (!mounted) return;
    if (sent) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final identifier = auth.pendingIdentifier ?? '';

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AuthColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    identifier.isEmpty
                        ? 'Enter the code we sent you'
                        : 'Enter the code sent to $identifier',
                    style: const TextStyle(
                        fontSize: 14, color: AuthColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_length, _buildOtpBox),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Verify',
                    isLoading: auth.isLoading,
                    onPressed: _verify,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AuthColors.textSecondary),
                          )
                        : GestureDetector(
                            onTap: _resend,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                color: AuthColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AuthColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AuthColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AuthColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AuthColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AuthColors.primaryBlue, width: 1.6),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_otp.length == _length) _verify();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../dashboard/home_shell.dart';
import 'role_select_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole _role = UserRole.student;
  int _step = 0;

  void _createAccount() {
    AppState.instance.currentRole.value = _role;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create your account', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Join thousands building smarter careers with AI guidance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 24),
              Row(
                children: List.generate(2, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),
              if (_step == 0) _buildRoleStep() else _buildDetailsStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your role', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        ...UserRole.values.map((role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _role = role),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: role == _role ? AppColors.primarySoft : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: role == _role ? Border.all(color: AppColors.primary, width: 1.4) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: AppColors.roleGradient(role.key), borderRadius: BorderRadius.circular(12)),
                        child: Icon(roleIcon(role), color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(role.tagline, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (role == _role) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            )),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => setState(() => _step = 1), child: const Text('Continue')),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 16),
        const Text('Full name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'Enter your full name')),
        const SizedBox(height: 16),
        const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'you@example.com')),
        const SizedBox(height: 16),
        Text(_role == UserRole.company ? 'Company name' : 'Institution / Organization',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(decoration: InputDecoration(hintText: _role == UserRole.company ? 'e.g. Acme Corp' : 'e.g. NIT Trichy')),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(obscureText: true, decoration: InputDecoration(hintText: '••••••••')),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => setState(() => _step = 0), child: const Text('Back')),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(onPressed: _createAccount, child: const Text('Create Account')),
            ),
          ],
        ),
      ],
    );
  }
}

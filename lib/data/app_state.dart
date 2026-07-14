import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Minimal global app state — deliberately dependency-free (no provider /
/// riverpod) since this is a frontend-only scaffold. Swap for your preferred
/// state management solution when wiring up the backend.
class AppState {
  AppState._();
  static final AppState instance = AppState._();

  final ValueNotifier<UserRole> currentRole = ValueNotifier(UserRole.student);
  final ValueNotifier<bool> onboardingSeen = ValueNotifier(false);
}

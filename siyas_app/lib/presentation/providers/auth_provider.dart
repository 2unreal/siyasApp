import 'package:flutter_riverpod/legacy.dart';
import '../../domain/models/user_model.dart';

class AuthState {
  final bool isAuthenticated;
  final String? uid;
  final String? phone;
  final UserRole role;
  final bool isAppLocked;

  const AuthState({
    this.isAuthenticated = false,
    this.uid,
    this.phone,
    this.role = UserRole.owner, // Default to owner for first setup
    this.isAppLocked = false,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;

  AuthState copyWith({
    bool? isAuthenticated,
    String? uid,
    String? phone,
    UserRole? role,
    bool? isAppLocked,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isAppLocked: isAppLocked ?? this.isAppLocked,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setRole(UserRole newRole) {
    state = state.copyWith(role: newRole);
  }

  void lockApp() {
    state = state.copyWith(isAppLocked: true);
  }

  void unlockApp() {
    state = state.copyWith(isAppLocked: false);
  }

  void setAuthenticated({required String uid, required String phone, required UserRole role}) {
    state = state.copyWith(
      isAuthenticated: true,
      uid: uid,
      phone: phone,
      role: role,
      isAppLocked: false,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

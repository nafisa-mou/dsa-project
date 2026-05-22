import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/firebase/firebase_models.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.user, this.isLoading = false, this.errorMessage});

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DriverAuthNotifier extends StateNotifier<AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DriverAuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser == null) {
        state = AuthState(user: null);
      } else {
        state = state.copyWith(isLoading: true);
        try {
          final doc = await _firestore.collection('drivers').doc(firebaseUser.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final user = User(
              id: firebaseUser.uid,
              name: data['name'] ?? firebaseUser.displayName ?? 'Driver',
              email: firebaseUser.email ?? '',
              userType: 'driver',
              createdAt: data['createdAt'] != null 
                  ? DateTime.parse(data['createdAt']) 
                  : DateTime.now(),
              lastLogin: DateTime.now(),
            );
            state = AuthState(user: user);
          } else {
            final user = User(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? 'Driver',
              email: firebaseUser.email ?? '',
              userType: 'driver',
              createdAt: DateTime.now(),
              lastLogin: DateTime.now(),
            );
            state = AuthState(user: user);
          }
        } catch (e) {
          state = AuthState(errorMessage: e.toString());
        }
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message ?? 'Authentication failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String licenseNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Register driver profile in Firestore
      final driverProfile = {
        'id': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'licenseNumber': licenseNumber,
        'status': 'offline',
        'totalTrips': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'userType': 'driver',
      };

      await _firestore.collection('drivers').doc(uid).set(driverProfile);
      await _firestore.collection('users').doc(uid).set({
        'id': uid,
        'name': name,
        'email': email,
        'userType': 'driver',
        'createdAt': DateTime.now().toIso8601String(),
      });

      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message ?? 'Registration failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _firebaseAuth.signOut();
    state = AuthState(user: null);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<DriverAuthNotifier, AuthState>((ref) {
  return DriverAuthNotifier();
});

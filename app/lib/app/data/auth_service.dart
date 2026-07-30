import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';
import 'ml_service.dart';

class AuthService {
  AuthService(this._storage);

  final GetStorage _storage;

  static const _usersKey = 'registered_users';
  static const _sessionKey = 'current_user';
  static const _progressKey = 'user_progress_cache';

  final MlService _mlService = MlService();

  List<UserModel> get _users {
    final raw = _storage.read<List<dynamic>>(_usersKey);
    if (raw == null) return [];
    return raw
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  UserModel? get currentUser {
    final raw = _storage.read<Map<dynamic, dynamic>>(_sessionKey);
    if (raw == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(raw));
  }

  Map<String, dynamic>? get userProgress {
    final raw = _storage.read<Map<dynamic, dynamic>>(_progressKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  bool get isLoggedIn => currentUser != null;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Try Node Bridge / PostgreSQL first
    try {
      final res = await _mlService.registerUser(
        name: name,
        email: normalizedEmail,
        password: password,
      );

      if (res != null && res['success'] == true && res['user'] != null) {
        final uData = Map<String, dynamic>.from(res['user'] as Map);
        final user = UserModel(
          id: uData['id'].toString(),
          name: uData['name'].toString(),
          email: uData['email'].toString(),
          password: password,
        );

        if (res['progress'] != null) {
          await _storage.write(_progressKey, res['progress']);
        }

        await _storage.write(_sessionKey, user.toJson());
        return user;
      } else if (res != null && res['error'] != null) {
        throw Exception(res['error']);
      }
    } catch (e) {
      if (e.toString().contains('already exists')) rethrow;
      print('[AuthService] Node bridge signup fallback to local: $e');
    }

    // Local Fallback
    if (_users.any((u) => u.email == normalizedEmail)) {
      throw Exception('An account with this email already exists.');
    }

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );

    final updated = [..._users, user];
    await _storage.write(
      _usersKey,
      updated.map((u) => u.toJson()).toList(),
    );
    await _storage.write(_sessionKey, user.toJson());

    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Try Node Bridge / PostgreSQL first
    try {
      final res = await _mlService.loginUser(
        email: normalizedEmail,
        password: password,
      );

      if (res != null && res['success'] == true && res['user'] != null) {
        final uData = Map<String, dynamic>.from(res['user'] as Map);
        final user = UserModel(
          id: uData['id'].toString(),
          name: uData['name'].toString(),
          email: uData['email'].toString(),
          password: password,
        );

        if (res['progress'] != null) {
          await _storage.write(_progressKey, res['progress']);
        }

        await _storage.write(_sessionKey, user.toJson());
        return user;
      } else if (res != null && res['error'] != null) {
        throw Exception(res['error']);
      }
    } catch (e) {
      if (e.toString().contains('Invalid email or password')) rethrow;
      print('[AuthService] Node bridge login fallback to local: $e');
    }

    // Local Fallback
    final user = _users.cast<UserModel?>().firstWhere(
          (u) => u!.email == normalizedEmail && u.password == password,
          orElse: () => null,
        );

    if (user == null) {
      throw Exception('Invalid email or password.');
    }

    await _storage.write(_sessionKey, user.toJson());
    return user;
  }

  Future<void> logout() async {
    await _storage.remove(_sessionKey);
    await _storage.remove(_progressKey);
  }
}

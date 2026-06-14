import 'package:get_storage/get_storage.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService(this._storage);

  final GetStorage _storage;

  static const _usersKey = 'registered_users';
  static const _sessionKey = 'current_user';

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

  bool get isLoggedIn => currentUser != null;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

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
  }
}

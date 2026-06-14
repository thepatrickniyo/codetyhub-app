import 'package:get/get.dart';

import '../data/auth_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  AuthController(this._authService);

  final AuthService _authService;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _authService.currentUser;
  }

  bool get isLoggedIn => user.value != null;

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final newUser = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      user.value = newUser;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final loggedInUser = await _authService.login(
        email: email,
        password: password,
      );
      user.value = loggedInUser;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user.value = null;
  }
}

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/pathway_controller.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/home/home_view.dart';
import '../views/pathway/pathway_detail_view.dart';
import '../views/splash/splash_view.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const pathway = '/pathway/:id';

  static String pathwayDetail(String id) => '/pathway/$id';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController(Get.find()));
      }),
    ),
    GetPage(
      name: signup,
      page: () => const SignupView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController(Get.find()));
      }),
    ),
    GetPage(
      name: home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
        Get.lazyPut<AuthController>(() => AuthController(Get.find()));
        Get.lazyPut<NavController>(() => NavController());
      }),
    ),
    GetPage(
      name: pathway,
      page: () => const PathwayDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PathwayController>(() => PathwayController());
      }),
    ),
  ];
}

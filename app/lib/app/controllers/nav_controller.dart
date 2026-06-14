import 'package:get/get.dart';

class NavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}

import 'package:get/get.dart';

import '../data/mock_data.dart';
import '../models/course_model.dart';
import '../models/pathway_model.dart';

class PathwayController extends GetxController {
  late final PathwayModel pathway;

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'] ?? '';
    pathway = MockData.getPathwayById(id) ?? MockData.pathways.first;
  }

  List<CourseModel> get courses => pathway.courses;
}

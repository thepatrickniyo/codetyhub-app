import 'package:get/get.dart';

import '../data/mock_data.dart';
import '../models/pathway_model.dart';

class HomeController extends GetxController {
  final RxList<PathwayModel> pathways = MockData.pathways.obs;
  final RxString searchQuery = ''.obs;

  List<PathwayModel> get filteredPathways {
    if (searchQuery.value.isEmpty) return pathways;
    final query = searchQuery.value.toLowerCase();
    return pathways
        .where(
          (p) =>
              p.title.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query),
        )
        .toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }
}

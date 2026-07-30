import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/code_review_controller.dart';

void showGistSubmissionDialog(BuildContext context, {required String studentId}) {
  final controller = Get.put(CodeReviewController());
  final urlController = TextEditingController(
    text: 'https://gist.github.com/thepatrickniyo/1a2b3c4d5e',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 20, right: 20,
        ),
        child: SingleChildScrollView(
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.code_rounded, color: Color(0xFF3B82F6), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'GitHub Gist Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste a GitHub Gist URL to run AI CodeBERT evaluation & update your rank in PostgreSQL.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Skill Node Selector
                const Text(
                  'TARGET SKILL MODULE',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedSkillNode.value,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: CodeReviewController.availableSkillNodes.map((node) {
                        return DropdownMenuItem<String>(
                          value: node['id'],
                          child: Text(node['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.selectedSkillNode.value = val;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gist URL Input Field
                const Text(
                  'GITHUB GIST URL',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://gist.github.com/username/gist_id',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF3B82F6)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Content View / Results / Loading
                if (controller.isLoading.value) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF3B82F6)),
                          SizedBox(height: 16),
                          Text('CodeBERT evaluating Gist code quality...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Text('Scoring correctness, elegance, alignment, & doc quality', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ] else if (controller.evaluationResult.value != null) ...[
                  _buildResultCard(
                    context,
                    controller.evaluationResult.value!,
                    onResubmit: () {
                      final url = urlController.text.trim();
                      if (url.isNotEmpty) {
                        controller.submitGistForReview(
                          studentId: studentId,
                          skillNode: controller.selectedSkillNode.value,
                          gistUrl: url,
                        );
                      }
                    },
                    onReset: () {
                      controller.resetSubmission();
                    },
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      final url = urlController.text.trim();
                      if (url.isNotEmpty) {
                        controller.submitGistForReview(
                          studentId: studentId,
                          skillNode: controller.selectedSkillNode.value,
                          gistUrl: url,
                        );
                      }
                    },
                    icon: const Icon(Icons.analytics_rounded),
                    label: const Text('Analyze Submission with CodeBERT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                if (controller.errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      );
    },
  );
}

Widget _buildResultCard(BuildContext context, result, {required VoidCallback onResubmit, required VoidCallback onReset}) {
  final vss = (result.vss as num).toDouble();
  final rank = result.leaderboardRank;
  final scores = result.dimensionScores as Map<String, dynamic>;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VERIFIED SKILL SCORE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  '${vss.toStringAsFixed(1)} / 100',
                  style: const TextStyle(color: Color(0xFF22C55E), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (rank != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Text('Rank #$rank', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
          ],
        ),
        const Divider(color: Colors.white12, height: 24),

        // 4 Rubric Dimensions Breakdown
        ...scores.entries.map((e) {
          final val = (e.value as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('${(val * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF334155),
                    color: val >= 0.8 ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Saved to PostgreSQL user_progress & code_submissions tables.',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6), size: 18),
                label: const Text('Re-evaluate', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70, size: 18),
                label: const Text('New Gist / Reset', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

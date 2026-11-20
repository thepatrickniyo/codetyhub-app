import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';

/// Privacy Policy & Terms of Use screen.
///
/// Open on a specific tab by passing `{'tab': 1}` as Get arguments
/// (0 = Privacy, 1 = Terms).
class PrivacyTermsView extends StatelessWidget {
  const PrivacyTermsView({super.key, this.initialTab});

  final int? initialTab;

  static const lastUpdated = 'November 20, 2026';

  int get _initialIndex {
    if (initialTab != null) return initialTab!.clamp(0, 1);
    final args = Get.arguments;
    if (args is Map && args['tab'] is int) {
      return (args['tab'] as int).clamp(0, 1);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          title: const Text('Privacy & Terms'),
          bottom: TabBar(
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Terms of Use'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _LegalDocument(sections: _privacySections),
              _LegalDocument(sections: _termsSections),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

class _LegalDocument extends StatelessWidget {
  const _LegalDocument({required this.sections});

  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Text(
          'Last updated: ${PrivacyTermsView.lastUpdated}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Text(
            section.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final p in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                p,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

const _privacySections = [
  _LegalSection('Overview', [
    'CodetyHub is an AI-assisted STEM learning app. This policy explains what '
        'information we collect when you use the app, how we use it, and the '
        'choices you have.',
  ]),
  _LegalSection('Information we collect', [
    '• Account details: your name, email address and password. Passwords are '
        'stored on our server in hashed form.',
    '• Learning progress: XP, streaks, completed lessons and quizzes, quiz '
        'answers, skill scores and badges.',
    '• Code submissions: code you submit for review (including code from '
        'GitHub Gist links you provide), along with the scores and feedback it '
        'receives.',
    '• App preferences: settings such as your theme choice, saved on your device.',
  ]),
  _LegalSection('How we use your information', [
    '• To create and secure your account and keep your progress in sync.',
    '• To personalise your learning pathway and recommend courses based on '
        'your skills and quiz results.',
    '• To evaluate your code with automated, AI-based scoring and give you '
        'feedback.',
    '• To estimate engagement (for example, the risk of you falling behind) so '
        'the app can adapt reminders and challenges.',
    '• To run gamification features such as XP, badges and the leaderboard.',
  ]),
  _LegalSection('What other learners can see', [
    'Your display name, XP and code-review scores may appear on the public '
        'leaderboard and in your portfolio. Your email address and password are '
        'never shown to other users.',
  ]),
  _LegalSection('Sharing', [
    'We do not sell your personal information. Code you submit may be sent to '
        'a third-party AI service (such as the HuggingFace Inference API) solely '
        'to score it. We may disclose information if required by law.',
  ]),
  _LegalSection('Storage and security', [
    'Your data is stored in our database and partly cached on your device so '
        'the app can work offline. We use reasonable safeguards, but no system '
        'is completely secure.',
  ]),
  _LegalSection('Your choices', [
    'You can sign out at any time, which clears your session from the device. '
        'You may ask us to access, correct or delete your account and its data '
        'by contacting the CodetyHub team.',
  ]),
  _LegalSection('Children', [
    'If you are under the age required to consent to data processing where you '
        'live, please use CodetyHub only with permission from a parent, guardian '
        'or school.',
  ]),
  _LegalSection('Changes to this policy', [
    'We may update this policy from time to time. We will show the new date at '
        'the top of this page, and significant changes will be announced in the app.',
  ]),
];

const _termsSections = [
  _LegalSection('Acceptance', [
    'By creating an account or using CodetyHub you agree to these Terms of Use '
        'and to our Privacy Policy. If you do not agree, please do not use the app.',
  ]),
  _LegalSection('Your account', [
    'Provide accurate information, keep your password confidential, and let us '
        'know if you suspect unauthorised use. You are responsible for activity '
        'under your account.',
  ]),
  _LegalSection('Acceptable use', [
    'Do not submit code or content that is malicious, unlawful, plagiarised or '
        'infringes the rights of others. Do not attempt to cheat the leaderboard, '
        'disrupt the service, or access other users\' data.',
  ]),
  _LegalSection('Your content', [
    'You keep ownership of the code you submit. You allow CodetyHub to store, '
        'process and evaluate it to provide feedback, scores and leaderboard '
        'rankings.',
  ]),
  _LegalSection('AI-generated feedback', [
    'Recommendations, scores and feedback are produced automatically and may '
        'be inaccurate or incomplete. Use them as learning guidance, not as a '
        'professional assessment.',
  ]),
  _LegalSection('Availability', [
    'The service is provided "as is". Features may change, and we may suspend '
        'accounts that break these terms.',
  ]),
  _LegalSection('Limitation of liability', [
    'To the extent allowed by law, CodetyHub is not liable for indirect or '
        'consequential losses arising from your use of the app.',
  ]),
  _LegalSection('Changes', [
    'We may update these terms. Continuing to use the app after an update means '
        'you accept the revised terms.',
  ]),
];

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cge_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '🎮',
      title: 'Book Gaming Sessions',
      subtitle:
          'Reserve PS4, PS5, and VR stations in seconds. Pick your console, choose your time slot, and show up ready to play.',
    ),
    _OnboardingPage(
      emoji: '🔄',
      title: 'Swap & Sell Gear',
      subtitle:
          'Buy, sell, and trade gaming gear with the community. Controllers, games, accessories — all in one marketplace.',
    ),
    _OnboardingPage(
      emoji: '🏆',
      title: 'Compete in Tournaments',
      subtitle:
          'Join weekly tournaments, climb the leaderboard, and win real prizes. From casual to competitive — there\'s a bracket for you.',
    ),
    _OnboardingPage(
      emoji: '👥',
      title: 'Join the Community',
      subtitle:
          'Connect with fellow gamers, share highlights, find squad mates, and stay updated on lounge events and news.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _nextPage() {
    if (_isLastPage) {
      context.go('/');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    context.go('/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: CgeButton(
                  label: 'Skip',
                  onPressed: _skip,
                  variant: CgeButtonVariant.ghost,
                  size: CgeButtonSize.sm,
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji icon with glow background
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.1),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              page.emoji,
                              style: const TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Title (Orbitron heading)
                        Text(
                          page.title,
                          style: AppTypography.heading,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Subtitle (Sora body muted)
                        Text(
                          page.subtitle,
                          style: AppTypography.body
                              .copyWith(color: AppColors.textMuted, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom area: dots + button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i
                              ? AppColors.cyan
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  CgeButton(
                    label: _isLastPage ? 'Get Started' : 'Next',
                    onPressed: _nextPage,
                    fullWidth: true,
                    size: CgeButtonSize.lg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page Data ──────────────────────────────────────

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/privacy_provider.dart';
import '../theme.dart';

class PrivacyOnboardingScreen extends StatefulWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  State<PrivacyOnboardingScreen> createState() => _PrivacyOnboardingScreenState();
}

class _PrivacyOnboardingScreenState extends State<PrivacyOnboardingScreen> {
  int? _selectedYear;
  late final int _currentYear;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
  }

  bool _isMinor(int year) {
    return _currentYear - year < PrivacyProvider.minorAge;
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final year = _selectedYear;
    if (year == null) return;
    await context.read<PrivacyProvider>().completeOnboarding(birthYear: year);
  }

  @override
  Widget build(BuildContext context) {
    final selectedYear = _selectedYear;
    final isMinor = selectedYear == null ? null : _isMinor(selectedYear);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PeacockTheme.softCream,
                      PeacockTheme.softCream.withAlpha(230),
                      PeacockTheme.peacockGreen.withAlpha(20),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Tamil Setu!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To give you the right experience, when were you born?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Birth year',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedYear,
                    items: List.generate(100, (index) => _currentYear - index)
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                  const SizedBox(height: 24),
                  if (isMinor != null)
                    Text(
                      isMinor
                          ? 'Child Mode will be enabled with restricted features.'
                          : 'You can use the standard experience with privacy controls.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _selectedYear == null
                        ? null
                        : () => _completeOnboarding(context),
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We use this to comply with global privacy laws. '
                    'Children under 13 receive a restricted, ad-free experience.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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

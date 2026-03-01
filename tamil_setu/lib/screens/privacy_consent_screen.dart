import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/privacy_provider.dart';
import '../theme.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _trackingAllowed = false;
  bool _socialEnabled = false;
  bool _notificationsEnabled = false;

  Future<void> _completeConsent(BuildContext context) async {
    await context.read<PrivacyProvider>().completeAdultConsent(
          trackingAllowed: _trackingAllowed,
          socialEnabled: _socialEnabled,
          notificationsEnabled: _notificationsEnabled,
        );
  }

  @override
  Widget build(BuildContext context) {
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
                      PeacockTheme.peacockBlue.withAlpha(12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Privacy choices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You control what we collect and enable. You can adjust these later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  _ConsentTile(
                    title: 'Analytics',
                    subtitle:
                        'Help improve the app with anonymous usage stats.',
                    value: _trackingAllowed,
                    onChanged: (value) {
                      setState(() => _trackingAllowed = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ConsentTile(
                    title: 'Social features',
                    subtitle: 'Enable leaderboards and social experiences.',
                    value: _socialEnabled,
                    onChanged: (value) {
                      setState(() => _socialEnabled = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ConsentTile(
                    title: 'Reminders',
                    subtitle: 'Allow daily learning notifications.',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => _completeConsent(context),
                    child: const Text('Continue'),
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

class _ConsentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PeacockTheme.peacockBlue.withAlpha(40)),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

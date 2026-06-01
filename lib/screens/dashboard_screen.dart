import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/providers/truthlens_provider.dart';
import 'analyzer_screen.dart';

const Color _kCard = Color(0xFF171B3A);
const Color _kAccent2 = Color(0xFF3D8BFF);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrustShieldProvider>(
      builder: (context, provider, _) {
        final user = FirebaseAuth.instance.currentUser;
        final firstName = user?.displayName?.trim().split(' ').first;
        final greetingName =
            (firstName == null || firstName.isEmpty) ? 'there' : firstName;
        final lastScan = provider.history.isNotEmpty ? provider.history.first : null;
        final totalScans = provider.history.length;
        final scamCount = provider.history.where((scan) => scan.isLikelyScam).length;
        final safeCount = totalScans - scamCount;
        final safetyScore = totalScans == 0
            ? 100
            : (((safeCount / totalScans) * 100).round()).clamp(0, 100);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B2F77), Color(0xFF3D8BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kAccent2.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      'Hi $greetingName 👋',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Your digital safety companion: TruthLens',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _QuickStatChip(
                        icon: Icons.verified_user_outlined,
                        label: 'Safety',
                        value: '$safetyScore%',
                      ),
                      const SizedBox(width: 8),
                      _QuickStatChip(
                        icon: Icons.analytics_outlined,
                        label: 'Scans',
                        value: '$totalScans',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'Paste text / link / news for quick check...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mic, color: Colors.white70),
                ),
                fillColor: Colors.white.withValues(alpha: 0.08),
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kAccent2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Feature Scanners'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _AnalyzerTile(
                  icon: Icons.sms_outlined,
                  title: 'Message Scanner',
                  scanType: ScanType.message,
                  gradient: [Color(0xFF5E60CE), Color(0xFF5390D9)],
                ),
                _AnalyzerTile(
                  icon: Icons.description_outlined,
                  title: 'Document Analyzer',
                  scanType: ScanType.document,
                  gradient: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                ),
                _AnalyzerTile(
                  icon: Icons.newspaper_outlined,
                  title: 'News Checker',
                  scanType: ScanType.news,
                  gradient: [Color(0xFF1F7A8C), Color(0xFF3BA99C)],
                ),
                _AnalyzerTile(
                  icon: Icons.link_outlined,
                  title: 'URL Scanner',
                  scanType: ScanType.url,
                  gradient: [Color(0xFF4361EE), Color(0xFF4895EF)],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Quick Safety Tips'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Never share OTP, CVV, PIN or password.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 6),
                  Text('• Verify unknown links before opening.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 6),
                  Text('• Avoid advance payment for jobs/offers.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionTitle('Recent Scan Snapshot'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: lastScan == null
                  ? const Text(
                      'No recent scans yet. Run a quick scan to see your latest result here.',
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              lastScan.isLikelyScam
                                  ? Icons.warning_amber_rounded
                                  : Icons.verified,
                              color: lastScan.isLikelyScam ? Colors.amber : Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${lastScan.scanType.label} - Trust ${lastScan.trustScore}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: lastScan.trustScore / 100,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            color: lastScan.isLikelyScam ? Colors.amber : Colors.green,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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

class _AnalyzerTile extends StatelessWidget {
  const _AnalyzerTile({
    required this.icon,
    required this.title,
    required this.scanType,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final ScanType scanType;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      tween: Tween<double>(begin: 0.95, end: 1),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnalyzerScreen(scanType: scanType),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 34, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
      ),
    );
  }
}
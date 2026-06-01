import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/providers/truthlens_provider.dart';

const Color _kCard = Color(0xFF171B3A);
const Color _kAccent2 = Color(0xFF3D8BFF);

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrustShieldProvider>(
      builder: (context, provider, _) {
        final history = provider.history;
        final totalScans = history.length;
        final scamCount = history.where((e) => e.isLikelyScam).length;
        final safeCount = totalScans - scamCount;

        // Calculate risk breakdown
        final (urlRisk, contentRisk, senderRisk, patternRisk) = _calculateRiskBreakdown(history);

        // Calculate category averages
        final avgRiskScore = totalScans == 0
            ? 0
            : ((urlRisk + contentRisk + senderRisk + patternRisk) / 4).round();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            const Text(
              'Risk Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Overall Risk Score Section
            _OverallRiskCard(
              riskScore: avgRiskScore,
              totalScans: totalScans,
              scamCount: scamCount,
              safeCount: safeCount,
            ),
            const SizedBox(height: 20),

            // Risk Breakdown Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RiskBreakdownItem(
                    icon: Icons.language,
                    title: 'URL / Domain Analysis',
                    score: urlRisk,
                  ),
                  const SizedBox(height: 12),
                  _RiskBreakdownItem(
                    icon: Icons.shield,
                    title: 'Content Analysis',
                    score: contentRisk,
                  ),
                  const SizedBox(height: 12),
                  _RiskBreakdownItem(
                    icon: Icons.person,
                    title: 'Sender Reputation',
                    score: senderRisk,
                  ),
                  const SizedBox(height: 12),
                  _RiskBreakdownItem(
                    icon: Icons.warning_amber,
                    title: 'Scam Pattern Detection',
                    score: patternRisk,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Summary Section
            if (history.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF7A5CFF)),
                        SizedBox(width: 8),
                        Text(
                          'AI Summary',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _generateAiSummary(scamCount, safeCount, avgRiskScore),
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'No scans yet. Start scanning to see AI insights.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            const SizedBox(height: 20),

            // Statistics Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Total Scans',
                          value: '$totalScans',
                          color: _kAccent2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Safe',
                          value: '$safeCount',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Flagged',
                          value: '$scamCount',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pie Chart
            if (totalScans > 0)
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: CustomPaint(
                        painter: _PiePainter(
                          safeRatio: safeCount / totalScans,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  (int, int, int, int) _calculateRiskBreakdown(List<ScanRecord> history) {
    if (history.isEmpty) return (0, 0, 0, 0);

    int urlRisk = 0;
    int contentRisk = 0;
    int senderRisk = 0;
    int patternRisk = 0;

    for (final record in history) {
      // URL/Domain risk based on type and trust score
      if (record.scanType == ScanType.url) {
        urlRisk += (100 - record.trustScore) ~/ history.length;
      }

      // Content risk
      if (record.explanation.isNotEmpty) {
        contentRisk += 30;
      }

      // Sender reputation (simulated)
      if (record.isLikelyScam) {
        senderRisk += 40;
      }

      // Pattern detection
      if (record.riskLevel == RiskLevel.high) {
        patternRisk += 70;
      } else if (record.riskLevel == RiskLevel.medium) {
        patternRisk += 40;
      }
    }

    return (
      (urlRisk / history.length).round().clamp(0, 100),
      (contentRisk / history.length).round().clamp(0, 100),
      (senderRisk / history.length).round().clamp(0, 100),
      (patternRisk / history.length).round().clamp(0, 100),
    );
  }

  String _generateAiSummary(int scamCount, int safeCount, int riskScore) {
    if (scamCount == 0) {
      return 'Great! You haven\'t encountered any flagged content. Keep being cautious and verify links before opening.';
    }

    if (riskScore >= 70) {
      return 'Your scan history shows high-risk patterns. Multiple suspicious items detected. Avoid clicking unknown links and sharing personal details. Enable security notifications.';
    } else if (riskScore >= 40) {
      return 'Moderate risk detected in your scans. Some suspicious patterns found. Be more careful with unknown senders and unverified links.';
    } else {
      return 'Low risk overall, but stay vigilant. Continue verifying sender identity and avoid sharing sensitive information online.';
    }
  }
}

class _OverallRiskCard extends StatelessWidget {
  const _OverallRiskCard({
    required this.riskScore,
    required this.totalScans,
    required this.scamCount,
    required this.safeCount,
  });

  final int riskScore;
  final int totalScans;
  final int scamCount;
  final int safeCount;

  String get _riskLabel {
    if (riskScore >= 70) return 'High Risk';
    if (riskScore >= 40) return 'Medium Risk';
    return 'Low Risk';
  }

  Color get _riskColor {
    if (riskScore >= 70) return Colors.red;
    if (riskScore >= 40) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.white70, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (totalScans > 0)
                      Text(
                        'Based on $totalScans scans',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    const Text(
                      'Overall Risk Assessment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$riskScore',
                      style: TextStyle(
                        color: _riskColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/100',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _riskColor.withValues(alpha: 0.2),
                        border: Border.all(color: _riskColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _riskLabel,
                        style: TextStyle(
                          color: _riskColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 140,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: riskScore / 100,
                      color: _riskColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$safeCount',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Safe',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$scamCount',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Flagged',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBreakdownItem extends StatelessWidget {
  const _RiskBreakdownItem({
    required this.icon,
    required this.title,
    required this.score,
  });

  final IconData icon;
  final String title;
  final int score;

  String get _riskLevel {
    if (score >= 70) return 'High Risk';
    if (score >= 40) return 'Medium Risk';
    return 'Low Risk';
  }

  Color get _riskColor {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _riskColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _riskColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _riskLevel,
              style: TextStyle(
                color: _riskColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: _riskColor,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.356, // -135 degrees
      4.712, // 270 degrees
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.356,
      4.712 * value,
      false,
      valuePaint,
    );

    // Pointer
    final angle = -2.356 + (4.712 * value);
    final pointerX = center.dx + radius * math.cos(angle);
    final pointerY = center.dy + radius * math.sin(angle);

    final pointerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pointerX, pointerY), 6, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.safeRatio});

  final double safeRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 60.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final safePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final scamPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Draw safe portion
    canvas.drawArc(rect, -1.57, 6.28318 * safeRatio, true, safePaint);

    // Draw scam portion
    canvas.drawArc(
      rect,
      -1.57 + (6.28318 * safeRatio),
      6.28318 * (1 - safeRatio),
      true,
      scamPaint,
    );

    // Draw legend
    final textPaint = TextPainter(
      text: const TextSpan(
        text: '● Safe  ● Flagged',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPaint.layout();
    textPaint.paint(
      canvas,
      Offset(
        center.dx - textPaint.width / 2,
        center.dy + radius + 16,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.safeRatio != safeRatio;
  }
}
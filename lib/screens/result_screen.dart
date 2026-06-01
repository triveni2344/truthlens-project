import 'package:flutter/material.dart';
import 'package:task_slider/models/scam_report.dart';

const Color _kBg = Color(0xFF0D1028);

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.record, super.key});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final trust = record.trustScore;
    final (status, color, icon) = switch (trust) {
      >= 75 => ('Safe', Colors.green, Icons.verified),
      >= 45 => ('Suspicious', Colors.amber, Icons.warning_amber_rounded),
      _ => ('Scam', Colors.red, Icons.gpp_bad),
    };
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: const Text('Result Screen', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171B3A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Trust Score', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: trust / 100),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: Colors.white12,
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(value * 100).toInt()}% Trust',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Explanation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...record.explanation.map(
            (reason) => ListTile(
              leading: const Text('•', style: TextStyle(color: Colors.white)),
              title: Text(reason, style: const TextStyle(color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Re-check'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3D8BFF)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Result saved to history')),
                    );
                  },
                  child: const Text('Save Result'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
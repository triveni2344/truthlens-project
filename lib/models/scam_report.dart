enum RiskLevel { low, medium, high }

enum ScanType {
  message('Message Analyzer'),
  document('Document Analyzer'),
  news('News Verification'),
  url('URL Scanner');

  const ScanType(this.label);
  final String label;
}

class ScanRecord {
  ScanRecord({
    required this.id,
    required this.scanType,
    required this.input,
    required this.trustScore,
    required this.riskLevel,
    required this.isLikelyScam,
    required this.explanation,
    required this.scannedAt,
  });

  final String id;
  final ScanType scanType;
  final String input;
  final int trustScore;
  final RiskLevel riskLevel;
  final bool isLikelyScam;
  final List<String> explanation;
  final DateTime scannedAt;
}

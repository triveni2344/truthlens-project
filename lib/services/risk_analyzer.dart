import 'package:task_slider/models/scam_report.dart';

class TrustAnalysis {
  TrustAnalysis({
    required this.trustScore,
    required this.riskLevel,
    required this.isLikelyScam,
    required this.explanation,
  });

  final int trustScore;
  final RiskLevel riskLevel;
  final bool isLikelyScam;
  final List<String> explanation;
}

class FraudAiEngine {
  static const List<String> highRiskKeywords = <String>[
    'urgent',
    'otp',
    'pay now',
    'verify account',
    'click now',
    'limited offer',
    'send money',
    'processing fee',
    'job guaranteed',
    'lottery winner',
  ];

  static const List<String> mediumRiskKeywords = <String>[
    'internship',
    'free',
    'crypto',
    'reward',
    'telegram',
    'loan',
    'investment',
    'exclusive',
  ];

  static const List<String> suspiciousDomainHints = <String>[
    '.xyz',
    '.top',
    '.click',
    '.live',
    '.shop',
    '-secure',
    'verify-',
    'login-',
  ];

  static const List<String> trustSignals = <String>[
    'official website',
    'customer care',
    'invoice',
    'reference id',
    'support ticket',
  ];

  TrustAnalysis analyze(String input, ScanType scanType) {
    final normalized = input.toLowerCase().trim();
    var fraudScore = switch (scanType) {
      ScanType.url => 32,
      ScanType.document => 28,
      ScanType.news => 30,
      ScanType.message => 30,
    };
    final explanation = <String>[];

    if (normalized.isEmpty) {
      return TrustAnalysis(
        trustScore: 0,
        riskLevel: RiskLevel.high,
        isLikelyScam: true,
        explanation: const ['No content available for analysis.'],
      );
    }

    final words = normalized.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final hasUrl = normalized.contains('http://') ||
        normalized.contains('https://') ||
        normalized.contains('www.');
    final suspiciousCount = highRiskKeywords.where(normalized.contains).length +
        mediumRiskKeywords.where(normalized.contains).length;

    if (words.length <= 2 && normalized.length < 10) {
      return TrustAnalysis(
        trustScore: 40,
        riskLevel: RiskLevel.medium,
        isLikelyScam: false,
        explanation: const [
          'Input is too short for reliable analysis.',
          'Provide full message/document text for better accuracy.',
        ],
      );
    }

    if (scanType == ScanType.url || hasUrl) {
      if (normalized.contains('http://')) {
        fraudScore += 20;
        explanation.add('Uses insecure HTTP connection.');
      }
      if (normalized.contains('bit.ly') ||
          normalized.contains('tinyurl') ||
          normalized.contains('t.ly') ||
          normalized.contains('rb.gy')) {
        fraudScore += 25;
        explanation.add('Shortened URL can hide suspicious destination.');
      }
      if (normalized.contains('@')) {
        fraudScore += 10;
        explanation.add('Contains unusual URL structure.');
      }
      if (RegExp(r'https?:\/\/\d{1,3}(\.\d{1,3}){3}').hasMatch(normalized)) {
        fraudScore += 14;
        explanation.add('URL points directly to an IP address.');
      }
      for (final hint in suspiciousDomainHints) {
        if (normalized.contains(hint)) {
          fraudScore += 10;
          explanation.add('Suspicious domain pattern detected: "$hint".');
        }
      }
      if (!RegExp(r'^https?:\/\/').hasMatch(normalized) && scanType == ScanType.url) {
        fraudScore += 8;
        explanation.add('URL format looks incomplete or masked.');
      }
    }

    if (RegExp(r'\b\d{4,}\b').hasMatch(normalized)) {
      fraudScore += 8;
      explanation.add('Contains long numeric patterns common in scam messages.');
    }
    if (RegExp(r'\b(otp|cvv|pin|password)\b').hasMatch(normalized) &&
        RegExp(r'\b(share|send|enter|update|confirm)\b').hasMatch(normalized)) {
      fraudScore += 24;
      explanation.add('Requests sensitive credentials.');
    }
    if (RegExp(r'(upi|gpay|phonepe|paytm|wallet)').hasMatch(normalized) &&
        RegExp(r'(pay|transfer|fee|deposit|advance)').hasMatch(normalized)) {
      fraudScore += 18;
      explanation.add('Pushes immediate payment request through digital wallet/UPI.');
    }
    if (RegExp(r'\b(click|open|install|download|verify|claim)\b').hasMatch(normalized) &&
        (hasUrl || suspiciousCount > 0)) {
      fraudScore += 12;
      explanation.add('Contains action-pressure language with suspicious context.');
    }
    if (RegExp(r'[!]{2,}').hasMatch(input) || RegExp(r'\b[A-Z]{5,}\b').hasMatch(input)) {
      fraudScore += 6;
      explanation.add('Urgent/emotional writing pattern detected.');
    }

    for (final keyword in highRiskKeywords) {
      if (normalized.contains(keyword)) {
        fraudScore += 10;
        explanation.add('High-risk keyword detected: "$keyword".');
      }
    }

    for (final keyword in mediumRiskKeywords) {
      if (normalized.contains(keyword)) {
        fraudScore += 6;
        explanation.add('Suspicious keyword detected: "$keyword".');
      }
    }

    if (scanType == ScanType.news &&
        (normalized.contains('shocking') ||
            normalized.contains('breaking') ||
            normalized.contains('viral'))) {
      fraudScore += 8;
      explanation.add('Emotionally charged framing may indicate misinformation.');
    }

    if (scanType == ScanType.document && normalized.length > 240) {
      fraudScore -= 5;
      explanation.add('Larger context available, improving analysis confidence.');
    }

    if (words.length < 8 && suspiciousCount == 0) {
      fraudScore += 10;
      explanation.add('Limited context lowers confidence in safety.');
    }

    for (final signal in trustSignals) {
      if (normalized.contains(signal)) {
        fraudScore -= 4;
      }
    }

    if (suspiciousCount >= 3) {
      fraudScore += 14;
      explanation.add('Multiple risk indicators appear together.');
    }

    if (suspiciousCount == 0 && words.length > 25 && !hasUrl) {
      fraudScore -= 8;
      explanation.add('Longer neutral context with no strong scam signals detected.');
    }

    fraudScore = fraudScore.clamp(0, 100);
    final trustScore = 100 - fraudScore;
    final riskLevel = _riskLevelFromTrust(trustScore);
    final likelyScam = trustScore < 45;

    if (explanation.isEmpty) {
      explanation.add('No major scam indicators found in the submitted content.');
    }

    return TrustAnalysis(
      trustScore: trustScore,
      riskLevel: riskLevel,
      isLikelyScam: likelyScam,
      explanation: explanation,
    );
  }

  RiskLevel _riskLevelFromTrust(int trustScore) {
    if (trustScore >= 70) {
      return RiskLevel.low;
    }
    if (trustScore >= 45) {
      return RiskLevel.medium;
    }
    return RiskLevel.high;
  }
}

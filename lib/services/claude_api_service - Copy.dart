// lib/services/claude_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_slider/models/scam_report.dart';

/// Response returned from Claude API analysis
class ClaudeAnalysisResult {
  ClaudeAnalysisResult({
    required this.trustScore,
    required this.riskLevel,
    required this.isLikelyScam,
    required this.verdict,
    required this.explanation,
    required this.redFlags,
    required this.legitimacySignals,
    required this.recommendation,
  });

  final int trustScore;
  final RiskLevel riskLevel;
  final bool isLikelyScam;
  final String verdict; // "REAL", "FAKE", or "SUSPICIOUS"
  final String explanation;
  final List<String> redFlags;
  final List<String> legitimacySignals;
  final String recommendation;

  /// Convert to ScanRecord explanation list (used by existing ResultScreen)
  List<String> toExplanationList() {
    final lines = <String>[];
    lines.add('Verdict: $verdict');
    lines.add(explanation);
    if (redFlags.isNotEmpty) {
      lines.add('--- Red Flags ---');
      lines.addAll(redFlags.map((f) => '🚩 $f'));
    }
    if (legitimacySignals.isNotEmpty) {
      lines.add('--- Legitimacy Signals ---');
      lines.addAll(legitimacySignals.map((s) => '✅ $s'));
    }
    lines.add('--- Recommendation ---');
    lines.add(recommendation);
    return lines;
  }
}

class ClaudeApiService {
  // ──────────────────────────────────────────────
  // CONFIGURATION
  // Replace with your actual Anthropic API key.
  // Store it in --dart-define or a secrets file.
  // NEVER commit a real key to version control.
  // ──────────────────────────────────────────────
  static const String _anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');
  static const String _openAiApiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  static const String _anthropicUrl = 'https://api.anthropic.com/v1/messages';
  static const String _anthropicModel = 'claude-haiku-4-5-20251001';
  static const String _openAiChatUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _openAiModel = 'gpt-3.5-turbo';
  static const int _maxTokens = 800;

  /// Analyzes whether an internship offer is real or fake using Claude AI.
  ///
  /// [content] — the raw internship post/message text pasted by the user
  /// [language] — 'english' or 'telugu' (matches your AppLanguage enum)
  Future<ClaudeAnalysisResult> analyzeInternship({
    required String content,
    String language = 'english',
  }) async {
    final prompt = _buildInternshipPrompt(content, language);

    try {
      final response = await http
          .post(
            Uri.parse(_anthropicUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _anthropicApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _anthropicModel,
              'max_tokens': _maxTokens,
              'system': _systemPrompt,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawText = (body['content'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .where((block) => block['type'] == 'text')
            .map((block) => block['text'] as String)
            .join('');
        return _parseClaudeResponse(rawText);
      } else if (response.statusCode == 401) {
        throw ClaudeApiException('Invalid API key. Check your ANTHROPIC_API_KEY.');
      } else if (response.statusCode == 429) {
        throw ClaudeApiException('Rate limit hit. Please wait a moment and retry.');
      } else {
        throw ClaudeApiException(
          'Claude API error ${response.statusCode}: ${response.body}',
        );
      }
    } on ClaudeApiException {
      rethrow;
    } catch (e) {
      throw ClaudeApiException('Network error: $e');
    }
  }

  /// Chat message analysis — used by AiChatAssistantScreen
  Future<String> chatAnalyze({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    String language = 'english',
  }) async {
    if (_openAiApiKey.isNotEmpty) {
      return _chatWithOpenAi(
        userMessage: userMessage,
        conversationHistory: conversationHistory,
        language: language,
      );
    }

    final messages = [
      ...conversationHistory.map(
        (m) => {'role': m['role']!, 'content': m['content']!},
      ),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_anthropicUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _anthropicApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _anthropicModel,
              'max_tokens': _maxTokens,
              'system': _chatSystemPrompt(language),
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['content'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .where((block) => block['type'] == 'text')
            .map((block) => block['text'] as String)
            .join('');
      } else if (response.statusCode == 429) {
        return 'Rate limit reached. Please wait a few seconds and try again.';
      } else {
        return 'Claude AI is temporarily unavailable. Using local analysis instead.';
      }
    } catch (_) {
      return 'Network error. Please check your connection and try again.';
    }
  }

  Future<String> _chatWithOpenAi({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    required String language,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _chatSystemPrompt(language)},
      ...conversationHistory.map(
        (m) => {'role': m['role']!, 'content': m['content']!},
      ),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_openAiChatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_openAiApiKey',
            },
            body: jsonEncode({
              'model': _openAiModel,
              'messages': messages,
              'max_tokens': 300,
              'temperature': 0.2,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = body['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          return 'AI did not return a valid response. Please try again.';
        }
        final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
        return (message?['content'] as String? ?? '').trim();
      } else if (response.statusCode == 401) {
        return 'OpenAI API key invalid or missing. Set OPENAI_API_KEY.';
      } else if (response.statusCode == 429) {
        return 'OpenAI rate limit reached. Please wait and try again.';
      } else {
        return 'OpenAI API error ${response.statusCode}. Please check your key and network.';
      }
    } catch (_) {
      return 'Network error. Please check your connection and try again.';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PROMPTS
  // ─────────────────────────────────────────────────────────────

  static const String _systemPrompt = '''
You are TruthLens AI, a specialized fraud detection assistant for Indian users.
Your job is to analyze internship and job offers to determine if they are 
REAL (legitimate) or FAKE (scam/fraud).

You MUST respond ONLY in valid JSON — no markdown fences, no preamble, no explanation outside JSON.

JSON schema (all fields required):
{
  "verdict": "REAL" | "FAKE" | "SUSPICIOUS",
  "trust_score": <integer 0-100>,
  "explanation": "<2-3 sentence summary of your reasoning>",
  "red_flags": ["<flag1>", "<flag2>", ...],
  "legitimacy_signals": ["<signal1>", "<signal2>", ...],
  "recommendation": "<one clear action for the user to take>"
}

Scoring guide:
- trust_score 75-100 → REAL
- trust_score 40-74  → SUSPICIOUS
- trust_score 0-39   → FAKE

Key red flags to check for internships/jobs in India:
- Asks for registration fee, security deposit, or processing fee upfront
- Promises unrealistic salary (e.g. ₹50,000+/month for freshers with no skills)
- Uses WhatsApp/Telegram as primary contact instead of official email
- No company website, or uses free domains (.xyz, .tk, .click, blogspot, etc.)
- Asks for Aadhaar/PAN/bank details before joining
- Grammar errors, urgent language, "apply now limited seats"
- "Work from home, earn lakhs daily" type phrasing
- No mention of specific role, responsibilities, or skills required
- Vague company name not findable on LinkedIn/MCA registry
- Asks to share OTP or install unknown apps

Legitimacy signals:
- Official company email (e.g. @infosys.com, @tcs.com)
- Listed on LinkedIn, Internshala, Naukri, or Glassdoor
- Specific role description with clear responsibilities
- Mentions interview process (technical round, HR round)
- Company has verifiable presence (MCA registration, social media)
- Stipend amount is realistic (₹5,000–₹25,000/month for students)
- Clear internship duration and work mode (remote/hybrid/onsite)
''';

  String _buildInternshipPrompt(String content, String language) {
    final langNote = language == 'telugu'
        ? 'The user speaks Telugu. Keep the "explanation" and "recommendation" fields in simple English but mark them as Telugu-friendly.'
        : '';
    return '''
Analyze this internship/job offer for legitimacy. $langNote

--- OFFER CONTENT START ---
$content
--- OFFER CONTENT END ---

Respond ONLY with the JSON object. No other text.
''';
  }

  String _chatSystemPrompt(String language) {
    final teluguNote = language == 'telugu'
        ? 'The user prefers Telugu. Reply in simple Telugu mixed with English technical terms.'
        : 'Reply in clear English.';
    return '''
You are TruthLens AI, a scam detection assistant for Indian users. $teluguNote

Your specialties:
1. Detecting fake internships and job offers
2. Identifying phishing messages and URLs
3. Spotting fake news
4. Explaining red flags in simple language

Keep responses concise (under 120 words). 
Always end with one clear action the user should take.
Never ask the user to share personal details with you.
''';
  }

  // ─────────────────────────────────────────────────────────────
  // RESPONSE PARSER
  // ─────────────────────────────────────────────────────────────

  ClaudeAnalysisResult _parseClaudeResponse(String rawText) {
    try {
      // Strip any accidental markdown fences just in case
      var cleaned = rawText.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
            .replaceFirst(RegExp(r'```$'), '')
            .trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final trustScore = (json['trust_score'] as num?)?.toInt() ?? 50;
      final verdictStr = (json['verdict'] as String?) ?? 'SUSPICIOUS';
      final isScam = verdictStr == 'FAKE' || trustScore < 40;

      RiskLevel riskLevel;
      if (trustScore >= 75) {
        riskLevel = RiskLevel.low;
      } else if (trustScore >= 40) {
        riskLevel = RiskLevel.medium;
      } else {
        riskLevel = RiskLevel.high;
      }

      return ClaudeAnalysisResult(
        trustScore: trustScore.clamp(0, 100),
        riskLevel: riskLevel,
        isLikelyScam: isScam,
        verdict: verdictStr,
        explanation: (json['explanation'] as String?) ?? 'Analysis complete.',
        redFlags: _toStringList(json['red_flags']),
        legitimacySignals: _toStringList(json['legitimacy_signals']),
        recommendation: (json['recommendation'] as String?) ??
            'Verify the company on LinkedIn before proceeding.',
      );
    } catch (_) {
      // Fallback if JSON parse fails
      return ClaudeAnalysisResult(
        trustScore: 50,
        riskLevel: RiskLevel.medium,
        isLikelyScam: false,
        verdict: 'SUSPICIOUS',
        explanation: 'Claude returned an unexpected format. Manual review recommended.',
        redFlags: const [],
        legitimacySignals: const [],
        recommendation: 'Paste the offer again or verify manually on LinkedIn/Internshala.',
      );
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}

class ClaudeApiException implements Exception {
  ClaudeApiException(this.message);
  final String message;
  @override
  String toString() => 'ClaudeApiException: $message';
}
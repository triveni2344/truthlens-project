// lib/providers/truthlens_provider.dart

import 'package:flutter/material.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/services/claude_api_service.dart';
import 'package:task_slider/services/risk_analyzer.dart';

enum AppLanguage { english, telugu }

class TrustShieldProvider extends ChangeNotifier {
  final FraudAiEngine _engine = FraudAiEngine();
  final ClaudeApiService _claudeService = ClaudeApiService();

  final List<ScanRecord> _history = <ScanRecord>[];
  ScanRecord? _lastResult;
  bool _isBusy = false;
  ThemeMode _themeMode = ThemeMode.dark;
  AppLanguage _language = AppLanguage.english;

  // Track conversation history for AI Chat screen
  final List<Map<String, String>> _chatHistory = [];

  List<ScanRecord> get history => List.unmodifiable(_history);
  ScanRecord? get lastResult => _lastResult;
  bool get isBusy => _isBusy;
  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  List<Map<String, String>> get chatHistory => List.unmodifiable(_chatHistory);

  int get personalRiskScore {
    if (_history.isEmpty) return 0;
    final suspicious = _history.where((e) => e.isLikelyScam).length;
    return ((suspicious / _history.length) * 100).round();
  }

  /// Main analysis entry point.
  /// Uses Claude for internship/job content, local engine for URL/news/message.
  Future<ScanRecord> analyzeInput({
    required ScanType scanType,
    required String content,
    bool forceClaudeForInternship = true,
  }) async {
    _isBusy = true;
    notifyListeners();

    try {
      // ── Detect if content looks like an internship/job offer ──
      final isInternshipContent = _looksLikeInternship(content);

      ScanRecord record;

      if (forceClaudeForInternship && isInternshipContent) {
        record = await _analyzeWithClaude(content, scanType);
      } else {
        record = await _analyzeLocally(content, scanType);
      }

      _history.insert(0, record);
      _lastResult = record;
      return record;
    } catch (e) {
      // Fallback to local engine if Claude fails
      final record = await _analyzeLocally(content, scanType);
      _history.insert(0, record);
      _lastResult = record;
      return record;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Claude-powered analysis for internship/job offers
  Future<ScanRecord> _analyzeWithClaude(
    String content,
    ScanType scanType,
  ) async {
    final result = await _claudeService.analyzeInternship(
      content: content,
      language: _language == AppLanguage.telugu ? 'telugu' : 'english',
    );

    return ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scanType: scanType,
      input: content,
      trustScore: result.trustScore,
      riskLevel: result.riskLevel,
      isLikelyScam: result.isLikelyScam,
      explanation: result.toExplanationList(),
      scannedAt: DateTime.now(),
    );
  }

  /// Local rule-based analysis (existing FraudAiEngine)
  Future<ScanRecord> _analyzeLocally(
    String content,
    ScanType scanType,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final analysis = _engine.analyze(content, scanType);
    return ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scanType: scanType,
      input: content,
      trustScore: analysis.trustScore,
      riskLevel: analysis.riskLevel,
      isLikelyScam: analysis.isLikelyScam,
      explanation: analysis.explanation,
      scannedAt: DateTime.now(),
    );
  }

  /// Send a chat message — uses Claude API for smarter replies
  Future<String> sendChatMessage(String userMessage) async {
    _chatHistory.add({'role': 'user', 'content': userMessage});
    notifyListeners();

    final reply = await _claudeService.chatAnalyze(
      userMessage: userMessage,
      conversationHistory: _chatHistory.length > 1
          ? _chatHistory.sublist(0, _chatHistory.length - 1)
          : [],
      language: _language == AppLanguage.telugu ? 'telugu' : 'english',
    );

    _chatHistory.add({'role': 'assistant', 'content': reply});
    notifyListeners();
    return reply;
  }

  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }

  void addAssistantChatMessage(String assistantText) {
    _chatHistory.add({'role': 'assistant', 'content': assistantText});
    notifyListeners();
  }

  void addUserChatMessage(String userText) {
    _chatHistory.add({'role': 'user', 'content': userText});
    notifyListeners();
  }

  /// Heuristic: does the content look like a job/internship post?
  bool _looksLikeInternship(String content) {
    final lower = content.toLowerCase();
    final internshipKeywords = [
      'internship', 'intern', 'hiring', 'job opening', 'job offer',
      'apply now', 'stipend', 'salary', 'work from home', 'wfh',
      'remote job', 'fresher', 'vacancy', 'recruiter', 'joining',
      'ctc', 'lpa', 'package', 'company', 'position', 'role',
    ];
    final matchCount = internshipKeywords.where(lower.contains).length;
    return matchCount >= 2;
  }

  void updateThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void updateLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }
}
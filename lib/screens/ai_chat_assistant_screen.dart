import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/providers/truthlens_provider.dart';
import 'package:task_slider/services/risk_analyzer.dart';

const Color _kCard = Color(0xFF171B3A);
const Color _kAccent2 = Color(0xFF3D8BFF);

class AiChatAssistantScreen extends StatefulWidget {
  const AiChatAssistantScreen({super.key});

  @override
  State<AiChatAssistantScreen> createState() => _AiChatAssistantScreenState();
}

class _AiChatAssistantScreenState extends State<AiChatAssistantScreen> {
  final TextEditingController _chatController = TextEditingController();
  final FraudAiEngine _fraudAiEngine = FraudAiEngine();
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatController.clear();
      _isBotTyping = true;
    });
    _scrollToBottom();

    final provider = context.read<TrustShieldProvider>();
    
    try {
      // Use the provider's sendChatMessage which uses the updated OpenRouter service
      await provider.sendChatMessage(text);
    } catch (_) {
      if (!mounted) return;
      // Local fallback in case of catastrophic failure
      final reply = _generateAiReply(text);
      provider.addAssistantChatMessage(reply);
    }

    if (!mounted) return;
    setState(() {
      _isBotTyping = false;
    });

    _scrollToBottom();
  }

  String _generateAiReply(String userMessage) {
    final language = context.read<TrustShieldProvider>().language;
    final input = userMessage.toLowerCase();
    final isGreeting = RegExp(r'^(hi|hello|hey|hii|hola)\b').hasMatch(input);
    if (isGreeting && input.length <= 12) {
      return language == AppLanguage.telugu
          ? 'హాయ్! నేను TruthLens AI. మెసేజ్, URL, జాబ్ ఆఫర్ లేదా న్యూస్ పంపండి, నేను స్కామ్ రిస్క్ చెక్ చేస్తాను.'
          : 'Hi! I am TruthLens AI. Share a message, URL, job offer, or news content and I will check scam risk.';
    }
    final asksGeneral =
        input.contains('how are you') || input.contains('what can you do');
    if (asksGeneral) {
      return language == AppLanguage.telugu
          ? 'నేను బాగున్నాను 🙂. మెసేజ్‌లు, లింకులు, ఇంటర్న్‌షిప్/జాబ్ ఆఫర్లు మరియు ఫేక్ న్యూస్‌ను స్కామ్ కోసం చెక్ చేయగలను.'
          : 'I am doing great 🙂. I can check messages, links, internships, job offers, and fake news for scam indicators.';
    }

    final looksLikeScamCheck =
        input.contains('http://') ||
        input.contains('https://') ||
        input.contains('www.') ||
        input.length > 40 ||
        input.contains('offer') ||
        input.contains('otp') ||
        input.contains('job') ||
        input.contains('internship') ||
        input.contains('payment') ||
        input.contains('link');
    if (!looksLikeScamCheck) {
      return language == AppLanguage.telugu
          ? 'స్కామ్ చెక్ కోసం మెసేజ్ లేదా లింక్ పంపండి. మీ ప్రశ్న కూడా అడగొచ్చు.'
          : 'Please share a message or URL for scam check. You can also ask any general safety question.';
    }

    final scanType = input.contains('http://') ||
            input.contains('https://') ||
            input.contains('www.')
        ? ScanType.url
        : ScanType.message;
    final analysis = _fraudAiEngine.analyze(userMessage, scanType);

    final riskLabel = switch (analysis.riskLevel) {
      RiskLevel.low => 'Low risk',
      RiskLevel.medium => 'Medium risk',
      RiskLevel.high => 'High risk',
    };

    final primaryTip = analysis.explanation.isNotEmpty
        ? analysis.explanation.first
        : 'No major risk indicator detected.';

    if (analysis.isLikelyScam) {
      return language == AppLanguage.telugu
          ? 'AI హెచ్చరిక: $riskLabel. Trust score ${analysis.trustScore}%.\n'
              'కారణం: $primaryTip\n'
              'చర్య: OTP/password ఇవ్వవద్దు, అధికారిక ఛానల్ ద్వారా verify చేయండి, payment links తప్పించండి.'
          : 'AI Alert: $riskLabel. Trust score ${analysis.trustScore}%.\n'
              'Reason: $primaryTip\n'
              'Action: Do not share OTP/password, verify the sender using an official source, and avoid payment links.';
    }

    return language == AppLanguage.telugu
        ? 'AI చెక్: $riskLabel. Trust score ${analysis.trustScore}%.\n'
            'కారణం: $primaryTip\n'
            'సూచన: ఏ చర్య తీసుకునే ముందు domain మరియు contact details verify చేయండి.'
        : 'AI Check: $riskLabel. Trust score ${analysis.trustScore}%.\n'
            'Reason: $primaryTip\n'
            'Tip: Still verify domain and contact details before taking action.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrustShieldProvider>();
    final chatHistory = provider.chatHistory;
    final messages = chatHistory.isEmpty
        ? [(isUser: false, text: 'Hi, I am TruthLens AI assistant. Ask me about scams.')]
        : chatHistory
            .map((item) => (isUser: item['role'] == 'user', text: item['content']!))
            .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length + (_isBotTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isBotTyping && index == messages.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'AI is typing...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }
              final msg = messages[index];
              return Align(
                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: msg.isUser ? _kAccent2 : _kCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(msg.text, style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Is this job fake?',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _kAccent2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent2,
                ),
                child: IconButton(
                  onPressed: _isBotTyping ? null : _send,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
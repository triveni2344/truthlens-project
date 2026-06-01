import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/providers/truthlens_provider.dart';
import 'analyzer_screen.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'ai_chat_assistant_screen.dart';
import 'profile_screen.dart';

const Color _kBg = Color(0xFF0D1028);
const Color _kAccent2 = Color(0xFF3D8BFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<TrustShieldProvider>().themeMode != ThemeMode.light;
    final pages = <Widget>[
      const DashboardScreen(),
      const AnalyticsScreen(),
      const HistoryScreen(),
      const AiChatAssistantScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: isDarkMode ? _kBg : const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: isDarkMode ? _kBg : Colors.white,
        title: Text(
          'TruthLens AI',
          style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF102A43)),
        ),
      ),
      body: pages[_index],
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _kAccent2,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AnalyzerScreen(scanType: ScanType.message),
                  ),
                );
              },
              label: const Text('Scan Now'),
              icon: const Icon(Icons.bolt),
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: isDarkMode ? const Color(0xFF141938) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _kAccent2.withValues(alpha: isDarkMode ? 0.25 : 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: _kAccent2, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54);
        }),
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: isDarkMode ? Colors.white70 : Colors.black54),
            selectedIcon: const Icon(Icons.home, color: _kAccent2),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart, color: isDarkMode ? Colors.white70 : Colors.black54),
            selectedIcon: const Icon(Icons.bar_chart, color: _kAccent2),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.history, color: isDarkMode ? Colors.white70 : Colors.black54),
            selectedIcon: const Icon(Icons.history, color: _kAccent2),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy, color: isDarkMode ? Colors.white70 : Colors.black54),
            selectedIcon: const Icon(Icons.smart_toy, color: _kAccent2),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: isDarkMode ? Colors.white70 : Colors.black54),
            selectedIcon: const Icon(Icons.person, color: _kAccent2),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
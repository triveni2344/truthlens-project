import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/providers/truthlens_provider.dart';
import 'package:task_slider/services/firebase_auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrustShieldProvider>(
      builder: (context, provider, _) {
        final user = FirebaseAuth.instance.currentUser;
        final displayName = user?.displayName?.trim();
        final email = user?.email?.trim();
        final profileName = (displayName == null || displayName.isEmpty)
            ? 'TruthLens User'
            : displayName;
        final profileEmail = (email == null || email.isEmpty)
            ? 'No email available'
            : email;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white12,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                profileName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: Text(
                profileEmail,
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Personal Risk Score'),
                subtitle: const Text(
                  'Based on your recent scanned content and scam exposure.',
                ),
                trailing: Text('${provider.personalRiskScore}%'),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title: const Text('Language', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                provider.language == AppLanguage.english ? 'English' : 'Telugu',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: DropdownButton<AppLanguage>(
                value: provider.language,
                dropdownColor: const Color(0xFF141938),
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  if (value != null) {
                    provider.updateLanguage(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.telugu,
                    child: Text('Telugu'),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined, color: Colors.white),
              title: const Text('Theme', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                provider.themeMode == ThemeMode.light ? 'Light Mode' : 'Dark Mode',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Switch(
                value: provider.themeMode == ThemeMode.dark,
                onChanged: (isDark) {
                  provider.updateThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Do you want to logout now?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldLogout != true) {
                  return;
                }

                final authService = FirebaseAuthService();
                final response = await authService.logout();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response.message)),
                );
                if (!response.success) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
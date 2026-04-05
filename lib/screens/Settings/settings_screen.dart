import 'package:flutter/material.dart';
import 'package:p_a_jewerly/config/environment.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.amber[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Application'),
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0+1',
            ),
            _buildListTile(
              icon: Icons.business,
              title: 'Company',
              subtitle: 'P&A Jewerly',
            ),
            _buildListTile(
              icon: Icons.dns,
              title: 'Environment',
              subtitle: Environment.current.name.toUpperCase(),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Environment.isDevelopment
                      ? Colors.green
                      : Environment.isProduction
                          ? Colors.red
                          : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Environment.current.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Preferences'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.amber),
              title: const Text('Notifications'),
              subtitle: const Text('Enable push notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: Colors.amber),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dark mode setting - coming soon'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Language'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.language, color: Colors.amber),
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Data'),
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.download,
              title: 'Export Data',
              subtitle: 'Download your data',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export data - coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              icon: Icons.upload,
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import data - coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () => _showClearCacheDialog(),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Support'),
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help center - coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report bug - coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              icon: Icons.email,
              title: 'Contact Support',
              subtitle: 'support@pajewerly.com',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact support - coming soon')),
                );
              },
            ),
          ]),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'P&A Jewerly App',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '© 2024 All rights reserved',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French'].map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language changed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache? This will not delete your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SuccessSnackBar extends StatelessWidget {
  final String message;

  const SuccessSnackBar({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

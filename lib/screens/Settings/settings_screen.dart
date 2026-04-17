import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/config/environment.dart';
import 'package:p_a_jewerly/providers/api_config_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

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
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.deepPurple, AppTheme.mediumPurple],
                  ),
                ),
              ),
            ),
            backgroundColor: AppTheme.deepPurple,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Server Configuration
                _buildSectionTitle('Server Configuration', icon: Icons.cloud),
                _buildSettingsCard([
                  Consumer<ApiConfigProvider>(
                    builder: (context, apiConfig, _) {
                      return _buildApiUrlTile(apiConfig);
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Application
                _buildSectionTitle('Application', icon: Icons.app_settings_alt),
                _buildSettingsCard([
                  _buildListTile(icon: Icons.info_outline, title: 'App Version', subtitle: '1.0.0+1'),
                  _buildListTile(icon: Icons.business, title: 'Company', subtitle: 'P&A Jewerly'),
                  _buildListTile(
                    icon: Icons.dns,
                    title: 'Environment',
                    subtitle: Environment.current.name.toUpperCase(),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Environment.isDevelopment ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(Environment.current.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Preferences
                _buildSectionTitle('Preferences', icon: Icons.tune),
                _buildSettingsCard([
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications, color: AppTheme.primaryGold),
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable push notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(value ? 'Notifications enabled' : 'Notifications disabled'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode, color: AppTheme.primaryGold),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dark mode setting - coming soon'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Language
                _buildSectionTitle('Language', icon: Icons.language),
                _buildSettingsCard([
                  ListTile(
                    leading: const Icon(Icons.language, color: AppTheme.primaryGold),
                    title: const Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(),
                  ),
                ]),
                const SizedBox(height: 24),

                // Data
                _buildSectionTitle('Data', icon: Icons.storage),
                _buildSettingsCard([
                  _buildListTile(icon: Icons.download, title: 'Export Data', subtitle: 'Download your data', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export data - coming soon')));
                  }),
                  const Divider(height: 1),
                  _buildListTile(icon: Icons.upload, title: 'Import Data', subtitle: 'Restore from backup', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import data - coming soon')));
                  }),
                  const Divider(height: 1),
                  _buildListTile(icon: Icons.delete_outline, title: 'Clear Cache', subtitle: 'Free up storage space', onTap: () => _showClearCacheDialog()),
                ]),
                const SizedBox(height: 24),

                // Support
                _buildSectionTitle('Support', icon: Icons.help_outline),
                _buildSettingsCard([
                  _buildListTile(icon: Icons.help_outline, title: 'Help Center', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help center - coming soon')));
                  }),
                  const Divider(height: 1),
                  _buildListTile(icon: Icons.bug_report, title: 'Report a Bug', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report bug - coming soon')));
                  }),
                  const Divider(height: 1),
                  _buildListTile(icon: Icons.email, title: 'Contact Support', subtitle: 'support@pajewerly.com', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support - coming soon')));
                  }),
                ]),
                const SizedBox(height: 30),
                Center(child: Text('P&A Jewerly App', style: TextStyle(color: Colors.grey[600], fontSize: 14))),
                const SizedBox(height: 8),
                Center(child: Text('© 2024 All rights reserved', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiUrlTile(ApiConfigProvider apiConfig) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.link, color: AppTheme.primaryGold),
      ),
      title: const Text('API Server URL', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(apiConfig.apiUrl.isNotEmpty ? apiConfig.apiUrl : 'Not configured', style: TextStyle(fontSize: 12, color: apiConfig.apiUrl.isNotEmpty ? Colors.grey[600] : Colors.red), overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, color: AppTheme.deepPurple), onPressed: () => _showApiUrlDialog(apiConfig)),
          if (apiConfig.apiUrl.isNotEmpty)
            IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: () async {
              await apiConfig.resetToDefault();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API URL reset to default'), backgroundColor: Colors.orange));
              }
            }),
        ],
      ),
      onTap: () => _showApiUrlDialog(apiConfig),
    );
  }

  void _showApiUrlDialog(ApiConfigProvider apiConfig) {
    final controller = TextEditingController(text: apiConfig.apiUrl);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.cloud, color: AppTheme.deepPurple), const SizedBox(width: 12), const Text('API Server URL')]),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the base URL for the API server:', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'API URL',
                  hintText: 'http://192.168.1.100:3000/api/v1',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.cream,
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a URL';
                  if (!value.startsWith('http://') && !value.startsWith('https://')) return 'URL must start with http:// or https://';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('Example: http://localhost:3000/api/v1', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await apiConfig.setApiUrl(controller.text.trim());
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API URL updated successfully'), backgroundColor: Colors.green));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save API URL'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(children: [
        Icon(icon, size: 20, color: AppTheme.deepPurple),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepPurple)),
      ]),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shadowColor: AppTheme.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGold),
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
            return RadioListTile<String>(title: Text(language), value: language, groupValue: _selectedLanguage, onChanged: (value) {
              setState(() => _selectedLanguage = value!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language changed'), duration: Duration(seconds: 1)));
            });
          }).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

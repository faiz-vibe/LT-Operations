import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: PreferencesService.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppUiSize>(
          valueListenable: PreferencesService.uiSize,
          builder: (context, uiSize, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: PreferencesService.desktopMode,
              builder: (context, desktopMode, _) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Preferences'),
                    backgroundColor: const Color(0xFFD84315),
                    foregroundColor: Colors.white,
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Theme Section
                      _buildSectionHeader('Appearance'),
                      _buildThemeCard(themeMode),
                      const SizedBox(height: 24),

                      // UI Size Section
                      _buildSectionHeader('UI Size'),
                      _buildUiSizeCard(uiSize),
                      const SizedBox(height: 24),

                      // Desktop Mode Section
                      _buildSectionHeader('Layout'),
                      _buildDesktopModeCard(desktopMode),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD84315))),
    );
  }

  Widget _buildThemeCard(AppThemeMode currentMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          RadioListTile<AppThemeMode>(
            title: const Text('Light Mode'),
            subtitle: const Text('Bright theme for outdoor use', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.light_mode, color: Colors.orange),
            value: AppThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) { if (value != null) PreferencesService.setThemeMode(value); },
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          RadioListTile<AppThemeMode>(
            title: const Text('Dark Mode'),
            subtitle: const Text('Easy on eyes, saves battery', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
            value: AppThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) { if (value != null) PreferencesService.setThemeMode(value); },
          ),
        ],
      ),
    );
  }

  Widget _buildUiSizeCard(AppUiSize currentSize) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          RadioListTile<AppUiSize>(
            title: const Text('Small'),
            subtitle: const Text('More data on screen', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.text_fields, size: 20),
            value: AppUiSize.small,
            groupValue: currentSize,
            onChanged: (value) { if (value != null) PreferencesService.setUiSize(value); },
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          RadioListTile<AppUiSize>(
            title: const Text('Medium (Default)'),
            subtitle: const Text('Balanced view', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.text_fields, size: 24),
            value: AppUiSize.medium,
            groupValue: currentSize,
            onChanged: (value) { if (value != null) PreferencesService.setUiSize(value); },
          ),
          const Divider(height: 0, indent: 16, endIndent: 16),
          RadioListTile<AppUiSize>(
            title: const Text('Large'),
            subtitle: const Text('Bigger text, easy reading', style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.text_fields, size: 30),
            value: AppUiSize.large,
            groupValue: currentSize,
            onChanged: (value) { if (value != null) PreferencesService.setUiSize(value); },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopModeCard(bool currentValue) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: const Text('Desktop Mode'),
        subtitle: const Text('Wider layout for tablets', style: TextStyle(fontSize: 12)),
        secondary: const Icon(Icons.desktop_windows, color: const Color(0xFFD84315)),
        value: currentValue,
        activeColor: const Color(0xFFD84315),
        onChanged: (value) => PreferencesService.setDesktopMode(value),
      ),
    );
  }
}
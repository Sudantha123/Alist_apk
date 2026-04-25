import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/server_config.dart';
import '../services/alist_service.dart';
import '../theme/app_theme.dart';
import 'file_browser_screen.dart';
import 'server_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  ServerConfig? _currentServer;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadServer();
  }

  Future<void> _loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    final serverJson = prefs.getString('server_config');
    if (serverJson != null) {
      try {
        final config = ServerConfig.fromJson(jsonDecode(serverJson));
        AlistService().configure(config);
        setState(() {
          _currentServer = config;
          _isLoading = false;
        });
      } catch (_) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
    _fadeController.forward();
  }

  void _onServerConfigured(ServerConfig config) {
    AlistService().configure(config);
    setState(() {
      _currentServer = config;
      _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentServer == null) {
      return ServerSetupScreen(onConfigured: _onServerConfigured);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            FileBrowserScreen(server: _currentServer!),
            _buildSearchTab(),
            _buildSettingsTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.storage_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'AList',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppTheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 60),
            const Icon(Icons.manage_search_rounded, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Search your files',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_currentServer != null) ...[
            _buildSettingsSection('Server', [
              _buildSettingsTile(
                Icons.dns_rounded,
                'Server Name',
                _currentServer!.name,
                AppTheme.primary,
              ),
              _buildSettingsTile(
                Icons.link_rounded,
                'Base URL',
                _currentServer!.baseUrl,
                AppTheme.secondary,
              ),
              _buildSettingsTile(
                Icons.person_rounded,
                'Username',
                _currentServer!.username.isEmpty ? 'Guest' : _currentServer!.username,
                AppTheme.accent,
              ),
            ]),
            const SizedBox(height: 16),
          ],
          _buildSettingsSection('Actions', [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 20),
              ),
              title: const Text('Change Server', style: TextStyle(color: AppTheme.textPrimary)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServerSetupScreen(
                      onConfigured: _onServerConfigured,
                      existingConfig: _currentServer,
                    ),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'AList Flutter Client v1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

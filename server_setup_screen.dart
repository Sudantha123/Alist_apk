import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/server_config.dart';
import '../services/alist_service.dart';
import '../theme/app_theme.dart';

class ServerSetupScreen extends StatefulWidget {
  final Function(ServerConfig) onConfigured;
  final ServerConfig? existingConfig;

  const ServerSetupScreen({
    super.key,
    required this.onConfigured,
    this.existingConfig,
  });

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _useToken = false;
  String? _errorMsg;
  String? _successMsg;

  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();

    if (widget.existingConfig != null) {
      _urlController.text = widget.existingConfig!.baseUrl;
      _nameController.text = widget.existingConfig!.name;
      _usernameController.text = widget.existingConfig!.username;
      _tokenController.text = widget.existingConfig!.token;
      _useToken = widget.existingConfig!.token.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMsg = 'Please enter server URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _successMsg = null;
    });

    final service = AlistService();
    String token = '';

    if (_useToken) {
      token = _tokenController.text.trim();
      final tempConfig = ServerConfig(
        name: _nameController.text.trim().isEmpty ? 'My Server' : _nameController.text.trim(),
        baseUrl: url,
        token: token,
      );
      service.configure(tempConfig);
    } else {
      final tempConfig = ServerConfig(name: 'temp', baseUrl: url);
      service.configure(tempConfig);

      if (_usernameController.text.trim().isNotEmpty) {
        final loginToken = await service.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        if (loginToken != null) {
          token = loginToken;
        } else {
          setState(() {
            _isLoading = false;
            _errorMsg = 'Login failed. Check credentials.';
          });
          return;
        }
      }
    }

    final config = ServerConfig(
      name: _nameController.text.trim().isEmpty ? 'My Server' : _nameController.text.trim(),
      baseUrl: url,
      token: token,
      username: _usernameController.text.trim(),
    );

    service.configure(config);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_config', jsonEncode(config.toJson()));

    setState(() {
      _isLoading = false;
      _successMsg = 'Connected successfully!';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    widget.onConfigured(config);
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: FadeTransition(
            opacity: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildConnectButton(),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 16),
                    _buildMessage(_errorMsg!, isError: true),
                  ],
                  if (_successMsg != null) ...[
                    const SizedBox(height: 16),
                    _buildMessage(_successMsg!, isError: false),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.storage_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'Connect to\nAList Server',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your server details to get started',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Server URL'),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.1:5244',
            prefixIcon: Icon(Icons.dns_rounded, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Server Name (Optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'My Home Server',
            prefixIcon: Icon(Icons.label_rounded, color: AppTheme.secondary),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Authentication',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            _buildToggle('Use Token', _useToken, (v) => setState(() => _useToken = v)),
          ],
        ),
        const SizedBox(height: 16),
        if (_useToken) ...[
          _buildLabel('API Token'),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'alist-xxxxxxxxxxxx',
              prefixIcon: Icon(Icons.key_rounded, color: AppTheme.accent),
            ),
          ),
        ] else ...[
          _buildLabel('Username (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'admin',
              prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel('Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.secondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF9C63FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _connect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppTheme.accent : AppTheme.secondary).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isError ? AppTheme.accent : AppTheme.secondary).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? AppTheme.accent : AppTheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppTheme.accent : AppTheme.secondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

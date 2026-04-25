class ServerConfig {
  final String name;
  final String baseUrl;
  final String token;
  final String username;

  const ServerConfig({
    required this.name,
    required this.baseUrl,
    this.token = '',
    this.username = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseUrl': baseUrl,
        'token': token,
        'username': username,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        name: json['name'] as String? ?? 'My Server',
        baseUrl: json['baseUrl'] as String? ?? '',
        token: json['token'] as String? ?? '',
        username: json['username'] as String? ?? '',
      );
}

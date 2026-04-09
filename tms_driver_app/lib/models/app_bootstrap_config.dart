class AppBootstrapConfig {
  final int? userId;
  final List<String> roles;
  final List<String> derivedSegments;
  final Map<String, bool> screens;
  final Map<String, bool> features;
  final Map<String, dynamic> policies;
  final String? generatedAt;
  final String resolutionTraceVersion;

  const AppBootstrapConfig({
    required this.userId,
    required this.roles,
    required this.derivedSegments,
    required this.screens,
    required this.features,
    required this.policies,
    required this.generatedAt,
    required this.resolutionTraceVersion,
  });

  factory AppBootstrapConfig.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return AppBootstrapConfig(
      userId: _toInt(user['id']),
      roles: ((user['roles'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      derivedSegments: ((user['derivedSegments'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      screens: _boolMap(json['screens']),
      features: _boolMap(json['features']),
      policies: ((json['policies'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k.toString(), v),
          ),
      generatedAt: meta['generatedAt']?.toString(),
      resolutionTraceVersion:
          meta['resolutionTraceVersion']?.toString() ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'user': {
          'id': userId,
          'roles': roles,
          'derivedSegments': derivedSegments,
        },
        'screens': screens,
        'features': features,
        'policies': policies,
        'meta': {
          'generatedAt': generatedAt,
          'resolutionTraceVersion': resolutionTraceVersion,
        },
      };

  static Map<String, bool> _boolMap(dynamic raw) {
    if (raw is! Map) return <String, bool>{};
    final out = <String, bool>{};
    raw.forEach((key, value) {
      final normalized = value is bool
          ? value
          : value?.toString().toLowerCase() == 'true' ||
              value?.toString() == '1';
      out[key.toString()] = normalized;
    });
    return out;
  }

  static int? _toInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}


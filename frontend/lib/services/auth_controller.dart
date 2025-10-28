import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState()) {
    _restoreSession();
  }

  final Ref ref;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken != null) {
      state = state.copyWith(accessToken: accessToken, refreshToken: refreshToken);
      await loadProfile();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>('/auth/login', data: {
      'email': email,
      'password': password
    });
    final data = response.data;
    if (data == null) {
      return false;
    }
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userJson = data['user'] as Map<String, dynamic>;
    await _persistTokens(accessToken, refreshToken);
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(userJson)
    );
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String captchaToken
  }) async {
    final api = ref.read(apiClientProvider);
    final response = await api.post<Map<String, dynamic>>('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'captchaToken': captchaToken
    });
    final data = response.data;
    if (data == null) {
      return false;
    }
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    await _persistTokens(accessToken, refreshToken);
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>)
    );
    return true;
  }

  Future<void> loadProfile() async {
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.get<Map<String, dynamic>>('/auth/profile');
      final data = response.data;
      if (data != null) {
        state = state.copyWith(user: AuthUser.fromJson(data));
      }
    } catch (_) {
      // ignore profile errors
    }
  }

  Future<bool> tryRefresh() async {
    final refreshToken = state.refreshToken;
    if (refreshToken == null) {
      return false;
    }
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.post<Map<String, dynamic>>('/auth/refresh', data: {
        'refreshToken': refreshToken
      });
      final data = response.data;
      if (data == null) {
        return false;
      }
      final accessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      await _persistTokens(accessToken, newRefreshToken);
      state = state.copyWith(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>)
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.refreshToken;
    if (refreshToken != null) {
      final api = ref.read(apiClientProvider);
      unawaited(api.post('/auth/logout', data: {'refreshToken': refreshToken}).catchError((_) => null));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    state = const AuthState();
  }

  Future<void> _persistTokens(String? accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }
}

class AuthState {
  const AuthState({this.accessToken, this.refreshToken, this.user});

  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;

  bool get isAuthenticated => accessToken != null && user != null;

  AuthState copyWith({String? accessToken, String? refreshToken, AuthUser? user}) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.permissions,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
        permissions: (json['permissions'] as List<dynamic>? ?? [])
            .map((entry) => PermissionGrant.fromJson(entry as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final List<PermissionGrant> permissions;

  String get fullName => '$firstName $lastName';

  bool hasPermission({
    required String module,
    required String action,
    int? leagueId,
  }) {
    for (final grant in permissions) {
      if (!grant.matches(module: module, action: action, leagueId: leagueId)) {
        continue;
      }
      return true;
    }
    return false;
  }

  Set<int>? allowedLeaguesFor({
    required String module,
    required String action,
  }) {
    final matching = permissions.where(
      (grant) => grant.module == module && grant.action == action,
    );
    if (matching.any((grant) => grant.scope == PermissionScope.global)) {
      return null;
    }
    final leagueIds = matching
        .where((grant) => grant.scope == PermissionScope.league)
        .expand((grant) => grant.leagues ?? const <int>[])
        .toSet();
    return leagueIds;
  }
}

class PermissionGrant {
  PermissionGrant({
    required this.module,
    required this.action,
    required this.scope,
    this.leagues,
    this.clubs,
    this.categories,
  });

  factory PermissionGrant.fromJson(Map<String, dynamic> json) {
    return PermissionGrant(
      module: json['module'] as String? ?? 'DESCONOCIDO',
      action: json['action'] as String? ?? 'DESCONOCIDO',
      scope: PermissionScope.parse(json['scope'] as String?),
      leagues: (json['leagues'] as List<dynamic>?)?.map((e) => e as int).toList(),
      clubs: (json['clubs'] as List<dynamic>?)?.map((e) => e as int).toList(),
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  final String module;
  final String action;
  final PermissionScope scope;
  final List<int>? leagues;
  final List<int>? clubs;
  final List<int>? categories;

  bool matches({
    required String module,
    required String action,
    int? leagueId,
  }) {
    if (module != this.module || action != this.action) {
      return false;
    }
    switch (scope) {
      case PermissionScope.global:
        return true;
      case PermissionScope.league:
        if (leagueId == null) {
          return (leagues?.isNotEmpty ?? false);
        }
        return leagues?.contains(leagueId) ?? false;
      case PermissionScope.club:
      case PermissionScope.category:
        return true;
    }
  }
}

enum PermissionScope { global, league, club, category; }

extension on PermissionScope {
  static PermissionScope parse(String? value) {
    switch (value) {
      case 'GLOBAL':
        return PermissionScope.global;
      case 'LIGA':
        return PermissionScope.league;
      case 'CLUB':
        return PermissionScope.club;
      case 'CATEGORIA':
        return PermissionScope.category;
      default:
        return PermissionScope.global;
    }
  }
}

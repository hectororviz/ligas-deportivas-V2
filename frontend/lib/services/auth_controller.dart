import 'dart:async';
import 'package:dio/dio.dart';
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
    await loadProfile();
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
    await loadProfile();
    return true;
  }

  Future<void> loadProfile() async {
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.get<Map<String, dynamic>>('/me');
      final data = response.data;
      if (data != null && state.user != null) {
        state = state.copyWith(user: state.user!.applyProfile(data));
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
      await loadProfile();
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

  Future<void> requestPasswordReset(String email) async {
    final api = ref.read(apiClientProvider);
    await api.post('/auth/password/request-reset', data: {'email': email});
  }

  Future<void> requestEmailChange(String newEmail) async {
    final api = ref.read(apiClientProvider);
    await api.post('/me/email/request-change', data: {'newEmail': newEmail});
  }

  Future<void> confirmEmailChange(String token) async {
    final api = ref.read(apiClientProvider);
    await api.post('/me/email/confirm', data: {'token': token});
    await loadProfile();
  }

  Future<void> updateProfileSettings({required String name, String? language}) async {
    final api = ref.read(apiClientProvider);
    final response = await api.put<Map<String, dynamic>>('/me', data: {
      'name': name,
      if (language != null && language.isNotEmpty) 'language': language
    });
    final data = response.data;
    if (data != null && state.user != null) {
      state = state.copyWith(user: state.user!.applyProfile(data));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword
    });
  }

  Future<Map<String, String>?> uploadAvatar({required List<int> bytes, required String filename}) async {
    final api = ref.read(apiClientProvider);
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename)
    });
    final response = await api.post<Map<String, dynamic>>('/me/avatar', data: formData);
    final data = response.data;
    if (data != null && data['avatar'] is Map<String, dynamic> && state.user != null) {
      final avatarMap = (data['avatar'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value as String));
      state = state.copyWith(user: state.user!.copyWith(avatarUrls: avatarMap));
      return avatarMap;
    }
    return null;
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

const _authUserClubUnset = Object();

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.permissions,
    this.language,
    this.avatarUrls,
    this.club,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        firstName: json['firstName'] as String? ?? _splitFullName(json['name'] as String? ?? '').$1,
        lastName: json['lastName'] as String? ?? _splitFullName(json['name'] as String? ?? '').$2,
        roles: (json['roles'] as List<dynamic>? ?? []).cast<String>(),
        permissions: (json['permissions'] as List<dynamic>? ?? [])
            .map((entry) => PermissionGrant.fromJson(entry as Map<String, dynamic>))
            .toList(),
        language: json['language'] as String?,
        avatarUrls: (json['avatar'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value as String)),
        club: json['club'] is Map<String, dynamic>
            ? AuthUserClub.fromJson(json['club'] as Map<String, dynamic>)
            : null,
      );

  AuthUser copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? language,
    Map<String, String>? avatarUrls,
    Object? club = _authUserClubUnset,
  }) {
    return AuthUser(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      roles: roles,
      permissions: permissions,
      language: language ?? this.language,
      avatarUrls: avatarUrls ?? this.avatarUrls,
      club: club == _authUserClubUnset ? this.club : club as AuthUserClub?,
    );
  }

  AuthUser applyProfile(Map<String, dynamic> profile) {
    final name = profile['name'] as String? ?? fullName;
    final (first, last) = _splitFullName(name);
    final avatar = (profile['avatar'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value as String));
    return copyWith(
      email: profile['email'] as String? ?? email,
      firstName: first,
      lastName: last,
      language: profile['language'] as String? ?? language,
      avatarUrls: avatar,
    );
  }

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final List<PermissionGrant> permissions;
  final String? language;
  final Map<String, String>? avatarUrls;
  final AuthUserClub? club;

  String get fullName => '$firstName $lastName'.trim();
  String get initials => (firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '');
  int? get clubId => club?.id;

  bool hasRole(String role) => roles.contains(role);

  bool hasAnyRole(Iterable<String> values) {
    for (final role in values) {
      if (roles.contains(role)) {
        return true;
      }
    }
    return false;
  }

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
      (grant) => grant.module == module && grant.matchesAction(action),
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

  Set<int>? allowedClubsFor({
    required String module,
    required String action,
  }) {
    final matching = permissions.where(
      (grant) => grant.module == module && grant.matchesAction(action),
    );
    if (matching.isEmpty) {
      return null;
    }
    if (matching.any((grant) => grant.scope == PermissionScope.global)) {
      return null;
    }
    final clubIds = matching
        .where((grant) => grant.scope == PermissionScope.club)
        .expand((grant) => grant.clubs ?? const <int>[])
        .toSet();
    return clubIds;
  }
}

class AuthUserClub {
  const AuthUserClub({
    required this.id,
    required this.name,
  });

  factory AuthUserClub.fromJson(Map<String, dynamic> json) => AuthUserClub(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Club',
      );

  final int id;
  final String name;
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

  bool matchesAction(String other) {
    return action == other || action == 'MANAGE';
  }

  bool matches({
    required String module,
    required String action,
    int? leagueId,
  }) {
    if (module != this.module || !matchesAction(action)) {
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

enum PermissionScope {
  global,
  league,
  club,
  category;

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

(String, String) _splitFullName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return ('', '');
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return (parts.first, '');
  }
  final first = parts.first;
  final last = parts.sublist(1).join(' ');
  return (first, last);
}

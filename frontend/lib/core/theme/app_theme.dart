import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leagueColorsProvider =
    StateNotifierProvider<LeagueColorsNotifier, Map<int, Color>>((ref) {
  return LeagueColorsNotifier();
});

class LeagueColorsNotifier extends StateNotifier<Map<int, Color>> {
  LeagueColorsNotifier() : super({});

  void setColor(int leagueId, Color color) {
    state = {
      ...state,
      leagueId: color
    };
  }

  Color resolve(int? leagueId) {
    if (leagueId == null) {
      return const Color(0xFF0057B8);
    }
    return state[leagueId] ?? const Color(0xFF0057B8);
  }
}

class AppTheme {
  AppTheme(this.ref);

  final Ref ref;

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057B8)),
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F2FD),
        selectedIconTheme: const IconThemeData(color: Color(0xFF0057B8)),
        selectedLabelTextStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0057B8)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Color leagueColor(int? leagueId) => ref.read(leagueColorsProvider.notifier).resolve(leagueId);
}

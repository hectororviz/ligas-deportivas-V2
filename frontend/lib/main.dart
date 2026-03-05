import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/responsive.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LigasApp()));
}

class LigasApp extends ConsumerWidget {
  const LigasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'Ligas Deportivas',
      debugShowCheckedModeBanner: false,
      theme: theme.lightTheme,
      routerConfig: router,
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final isMobile = Responsive.isMobile(context);

        Widget appChild = child;

        // On mobile, override table padding and globally hide scrollbars.
        if (isMobile) {
          appChild = Theme(
            data: Theme.of(context).copyWith(
              dataTableTheme: Theme.of(context).dataTableTheme.copyWith(
                    horizontalMargin: 8,
                    columnSpacing: 12,
                  ),
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: child,
            ),
          );
        }

        return appChild;
      },
    );
  }
}

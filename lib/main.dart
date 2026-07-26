import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'componentes/design_system.dart';
import 'componentes/rodape_versao.dart';
import 'telas/tela_splash.dart';

void main() {
  runApp(const ProviderScope(child: FisioHomeCareApp()));
}

class FisioHomeCareApp extends StatelessWidget {
  const FisioHomeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fisio Home Care',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FisioCores.primary,
          primary: FisioCores.primary,
          secondary: FisioCores.secondary,
          surface: FisioCores.surface,
          error: FisioCores.danger,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .copyWith(
              headlineMedium: const TextStyle(
                color: FisioCores.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              titleLarge: const TextStyle(
                color: FisioCores.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              titleMedium: const TextStyle(
                color: FisioCores.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: const TextStyle(color: FisioCores.textPrimary),
              bodyMedium: const TextStyle(color: FisioCores.textPrimary),
              bodySmall: const TextStyle(color: FisioCores.textSecondary),
              labelMedium: const TextStyle(
                color: FisioCores.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
        scaffoldBackgroundColor: FisioCores.surface,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: FisioCores.textPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.base),
            ),
            backgroundColor: FisioCores.primary,
            foregroundColor: Colors.white,
            shadowColor: FisioCores.primary.withValues(alpha: 0.18),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.base),
            ),
            backgroundColor: FisioCores.primary,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: FisioCores.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FisioRaios.md),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FisioCores.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: FisioEspacamentos.base,
            vertical: FisioEspacamentos.base,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
            borderSide: const BorderSide(color: FisioCores.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
            borderSide: const BorderSide(color: FisioCores.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
            borderSide: const BorderSide(color: FisioCores.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
            borderSide: const BorderSide(color: FisioCores.danger, width: 2),
          ),
          labelStyle: const TextStyle(
            color: FisioCores.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: FisioCores.textMuted),
          prefixIconColor: FisioCores.textMuted,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: FisioCores.primary.withValues(alpha: 0.1),
          selectedColor: FisioCores.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FisioRaios.pill),
          ),
          side: BorderSide(color: FisioCores.primary.withValues(alpha: 0.12)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FisioRaios.lg),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: FisioCores.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FisioRaios.base),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(FisioRaios.lg)),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
      builder: (context, child) =>
          VersaoOverlay(child: child ?? const SizedBox.shrink()),
      home: const TelaSplash(),
    );
  }
}

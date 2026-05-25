import 'package:flutter/material.dart';

import 'screens/dashboard_page.dart';
import 'screens/lista_ordens_page.dart';
import 'screens/cadastro_os_page.dart';
import 'screens/detalhes_os_page.dart';

void main() {
  runApp(const GestorOsApp());
}

class GestorOsApp extends StatelessWidget {
  const GestorOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor OS - Telecell Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFFE67E22),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 214, 217, 221),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Design dos inputs globalmente unificado para estilo premium
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          labelStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ),
      // Rota inicial
      initialRoute: '/',
      // Rotas nomeadas
      routes: {
        '/': (context) => const DashboardPage(),
        '/lista-ordens': (context) => const ListaOrdensPage(),
        '/cadastro-os': (context) => const CadastroOsPage(),
        '/detalhes-os': (context) => const DetalhesOsPage(),
      },
    );
  }
}

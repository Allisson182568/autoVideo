// lib/main.dart
import 'package:automacao_video/screen/home_screen.dart';
import 'package:automacao_video/screen/studio_screen.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const FinanceVideoApp());
}

class FinanceVideoApp extends StatelessWidget {
  const FinanceVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Video Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF9C200),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int    _index      = 0;
  String _temaInicial  = '';
  String _formatoInicial = 'short';

  // Chamado pelo Studio quando usuário clica em ▶
  void _irParaGerador(String tema, String formato) {
    setState(() {
      _temaInicial    = tema;
      _formatoInicial = formato;
      _index          = 0; // muda para aba Gerar
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        temaInicial:    _temaInicial,
        formatoInicial: _formatoInicial,
        onTemaUsado: () => setState(() {
          _temaInicial    = '';
          _formatoInicial = 'short';
        }),
      ),
      StudioScreen(onGerarVideo: _irParaGerador),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1E1E2E)))),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: const Color(0xFF0A0A0F),
          selectedItemColor: const Color(0xFFF9C200),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front_outlined),
              activeIcon: Icon(Icons.video_camera_front),
              label: 'Gerar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Studio',
            ),
          ],
        ),
      ),
    );
  }
}
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'roteiro_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final String temaInicial;
  final String formatoInicial;
  final VoidCallback? onTemaUsado;

  const HomeScreen({
    super.key,
    this.temaInicial    = '',
    this.formatoInicial = 'short',
    this.onTemaUsado,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _temaController;
  late String _formato;
  bool _carregando = false;

  final List<String> _sugestoes = [
    'Tesouro Direto para iniciantes',
    'Como a Selic afeta seus investimentos',
    'FIIs: o que são e como investir',
    'Diferença entre CDB e LCI',
    'Como montar uma reserva de emergência',
    'Renda fixa vs Renda variável',
  ];

  @override
  void initState() {
    super.initState();
    _temaController = TextEditingController(text: widget.temaInicial);
    _formato        = widget.formatoInicial;
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    // Quando o Studio manda um novo tema, atualiza o campo
    if (widget.temaInicial != old.temaInicial && widget.temaInicial.isNotEmpty) {
      _temaController.text = widget.temaInicial;
      setState(() => _formato = widget.formatoInicial);
    }
  }

  @override
  void dispose() {
    _temaController.dispose();
    super.dispose();
  }

  Future<void> _gerarRoteiro() async {
    if (_temaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um tema para o vídeo')),
      );
      return;
    }

    setState(() => _carregando = true);

    // Avisa o main.dart que o tema foi usado
    widget.onTemaUsado?.call();

    try {
      final resultado = await ApiService.gerarRoteiro(
        tema:    _temaController.text.trim(),
        formato: _formato,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoteiroScreen(
            jobId:   resultado['job_id'],
            slides:  List<Map<String, dynamic>>.from(resultado['roteiro']),
            tema:    _temaController.text.trim(),
            formato: _formato,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9C200).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF9C200).withOpacity(0.3)),
                ),
                child: const Text('⚡ FINANCE VIDEO GENERATOR',
                    style: TextStyle(color: Color(0xFFF9C200), fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              ),

              const SizedBox(height: 20),

              const Text('Gerar\nNovo Vídeo',
                  style: TextStyle(color: Colors.white, fontSize: 36,
                      fontWeight: FontWeight.w800, height: 1.1)),

              const SizedBox(height: 8),

              Text('Digite o tema e a IA cria tudo automaticamente',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 14)),

              // Badge quando tema veio do Studio
              if (widget.temaInicial.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF4ADE80).withOpacity(0.3)),
                  ),
                  child: const Text('📅 Tema importado da agenda',
                      style: TextStyle(color: Color(0xFF4ADE80),
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],

              const SizedBox(height: 40),

              const Text('TEMA DO VÍDEO',
                  style: TextStyle(color: Color(0xFFF9C200), fontSize: 11,
                      fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              TextField(
                controller: _temaController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex: Tesouro Direto para iniciantes',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                  filled: true,
                  fillColor: const Color(0xFF111118),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFF9C200), width: 1.5)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 28),

              const Text('FORMATO',
                  style: TextStyle(color: Color(0xFFF9C200), fontSize: 11,
                      fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Row(children: [
                _FormatoCard(label: 'Vídeo Longo', sublabel: '16:9 · 8-10 min',
                    icon: '🎬', selecionado: _formato == 'longo',
                    onTap: () => setState(() => _formato = 'longo')),
                const SizedBox(width: 12),
                _FormatoCard(label: 'Short', sublabel: '9:16 · até 60s',
                    icon: '⚡', selecionado: _formato == 'short',
                    onTap: () => setState(() => _formato = 'short')),
              ]),

              const SizedBox(height: 28),

              const Text('SUGESTÕES',
                  style: TextStyle(color: Color(0xFFF9C200), fontSize: 11,
                      fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _sugestoes.map((s) => GestureDetector(
                  onTap: () => _temaController.text = s,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111118),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E1E2E)),
                    ),
                    child: Text(s, style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _gerarRoteiro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9C200),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _carregando
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black))
                      : const Text('Gerar Roteiro com IA →',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatoCard extends StatelessWidget {
  final String label, sublabel, icon;
  final bool selecionado;
  final VoidCallback onTap;

  const _FormatoCard({required this.label, required this.sublabel,
    required this.icon, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFFF9C200).withOpacity(0.1)
              : const Color(0xFF111118),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado
                ? const Color(0xFFF9C200)
                : const Color(0xFF1E1E2E),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(
              color: selecionado ? const Color(0xFFF9C200) : Colors.white,
              fontWeight: FontWeight.w700, fontSize: 14)),
          Text(sublabel, style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ]),
      ),
    ));
  }
}
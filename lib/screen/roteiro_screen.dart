// lib/screens/roteiro_screen.dart
// Tela de revisão: usuário vê e edita o roteiro gerado pela IA antes de virar vídeo

import 'package:flutter/material.dart';
import 'progresso_screen.dart';
import '../services/api_service.dart';

class RoteiroScreen extends StatefulWidget {
  final String jobId;
  final List<Map<String, dynamic>> slides;
  final String tema;
  final String formato;

  const RoteiroScreen({
    super.key,
    required this.jobId,
    required this.slides,
    required this.tema,
    required this.formato,
  });

  @override
  State<RoteiroScreen> createState() => _RoteiroScreenState();
}

class _RoteiroScreenState extends State<RoteiroScreen> {
  late List<Map<String, dynamic>> _slides;
  bool _gerando = false;

  @override
  void initState() {
    super.initState();
    // Cria cópia editável dos slides
    _slides = widget.slides.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  Future<void> _iniciarVideo() async {
    setState(() => _gerando = true);

    try {
      await ApiService.gerarVideo(jobId: widget.jobId, slides: _slides);

      if (!mounted) return;

      // Navega para a tela de progresso
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProgressoScreen(jobId: widget.jobId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
      setState(() => _gerando = false);
    }
  }

  void _editarSlide(int index) {
    final slide = _slides[index];
    final tituloCtrl = TextEditingController(text: slide['titulo']);
    final narracaoCtrl = TextEditingController(text: slide['narracao']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EDITAR SLIDE ${index + 1}',
              style: const TextStyle(
                color: Color(0xFFF9C200),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildCampo('Título', tituloCtrl, maxLines: 1),
            const SizedBox(height: 12),
            _buildCampo('Narração', narracaoCtrl, maxLines: 5),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _slides[index]['titulo'] = tituloCtrl.text;
                    _slides[index]['narracao'] = narracaoCtrl.text;
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C200),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child:  Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A0A0F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF9C200)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revisar Roteiro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              widget.tema,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E1E2E)),
            ),
            child: Text(
              widget.formato == 'short' ? '⚡ SHORT' : '🎬 LONGO',
              style: const TextStyle(color: Color(0xFFF9C200), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de slides ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _slides.length,
              itemBuilder: (ctx, i) {
                final slide = _slides[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111118),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E1E2E)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9C200).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Color(0xFFF9C200),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      slide['titulo'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        slide['narracao'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFFF9C200), size: 20),
                      onPressed: () => _editarSlide(i),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Botão de gerar vídeo ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Column(
              children: [
                Text(
                  '${_slides.length} slides · Toque em ✏️ para editar qualquer slide',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _gerando ? null : _iniciarVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9C200),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _gerando
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                        : const Text(
                      'Gerar Vídeo →',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
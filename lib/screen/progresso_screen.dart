// lib/screens/progresso_screen.dart
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProgressoScreen extends StatefulWidget {
  final String jobId;
  final String formato;
  const ProgressoScreen({super.key, required this.jobId, this.formato = 'short'});

  @override
  State<ProgressoScreen> createState() => _ProgressoScreenState();
}

class _ProgressoScreenState extends State<ProgressoScreen> {
  Timer? _timer;
  Timer? _cronometro;
  int    _progresso   = 0;
  String _statusLabel = 'Iniciando...';
  String _status      = 'processando';
  int    _segundos    = 0;
  int?   _estimativa;

  static const Map<String, int> _estimativas = {
    'short': 90,
    'longo': 300,
  };

  @override
  void initState() {
    super.initState();
    _estimativa = _estimativas[widget.formato] ?? 120;
    _iniciarPolling();
    _iniciarCronometro();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cronometro?.cancel();
    super.dispose();
  }

  void _iniciarCronometro() {
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status == 'processando') setState(() => _segundos++);
    });
  }

  void _iniciarPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final data = await ApiService.verificarStatus(widget.jobId);
        if (!mounted) return;
        setState(() {
          _progresso   = (data['progresso'] as num).toInt();
          _statusLabel = data['status_label'] ?? _labelParaStatus(data['status']);
          _status      = data['status'];
        });
        if (_status == 'concluido' || _status == 'erro') {
          _timer?.cancel();
          _cronometro?.cancel();
        }
      } catch (_) {}
    });
  }

  String _labelParaStatus(String s) {
    switch (s) {
      case 'processando': return 'Processando...';
      case 'concluido':   return 'Vídeo pronto!';
      case 'erro':        return 'Ocorreu um erro';
      default:            return s;
    }
  }

  String _formatarTempo(int s) =>
      s >= 60 ? '${s ~/ 60}m ${s % 60}s' : '${s}s';

  String _tempoRestante() {
    if (_estimativa == null) return '';
    final r = (_estimativa! - _segundos).clamp(0, _estimativa!);
    return r == 0 ? 'Finalizando...' : '~${_formatarTempo(r)} restantes';
  }

  void _abrirVideo() =>
      html.window.open(ApiService.urlDownload(widget.jobId), '_blank');

  void _baixarVideo() {
    html.AnchorElement(href: ApiService.urlDownload(widget.jobId))
      ..setAttribute('download', 'video_financas.mp4')
      ..click();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        foregroundColor: Colors.white,
        title: const Text('Gerando Vídeo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
      ),
      // ── SingleChildScrollView resolve o overflow ──
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildIconeStatus(),
            const SizedBox(height: 28),

            Text(_statusLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),

            const SizedBox(height: 20),

            if (_status != 'erro') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progresso / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1E1E2E),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _status == 'concluido'
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF9C200),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_progresso%',
                      style: const TextStyle(
                          color: Color(0xFFF9C200),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        color: Color(0xFF64748B), size: 14),
                    const SizedBox(width: 4),
                    Text(_formatarTempo(_segundos),
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12)),
                  ]),
                  if (_status == 'processando')
                    Text(_tempoRestante(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12)),
                ],
              ),
            ],

            const SizedBox(height: 32),
            _buildEtapas(),
            const SizedBox(height: 32),

            // ── Concluído ──
            if (_status == 'concluido') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF4ADE80).withOpacity(0.2)),
                ),
                child: Text('✅ Gerado em ${_formatarTempo(_segundos)}',
                    style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _abrirVideo,
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
                  label: const Text('▶  Assistir Vídeo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _baixarVideo,
                  icon: const Icon(Icons.download_rounded, size: 22),
                  label: const Text('⬇  Baixar .mp4',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9C200),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF1E1E2E)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('+ Gerar Novo Vídeo',
                      style: TextStyle(fontSize: 14)),
                ),
              ),
            ],

            // ── Erro ──
            if (_status == 'erro')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIconeStatus() {
    if (_status == 'concluido') {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4ADE80), width: 2),
        ),
        child: const Icon(Icons.check_rounded, color: Color(0xFF4ADE80), size: 52),
      );
    }
    if (_status == 'erro') {
      return Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: const Icon(Icons.error_outline, color: Colors.red, size: 52),
      );
    }
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF9C200).withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(
            color: const Color(0xFFF9C200).withOpacity(0.3), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
            strokeWidth: 3, color: Color(0xFFF9C200)),
      ),
    );
  }

  Widget _buildEtapas() {
    final etapas = [
      {'label': 'Gerar narração', 'threshold': 10},
      {'label': 'Buscar imagens', 'threshold': 40},
      {'label': 'Montar vídeo',   'threshold': 70},
      {'label': 'Finalizar',      'threshold': 100},
    ];
    return Column(
      children: etapas.map((e) {
        final threshold = e['threshold'] as int;
        final concluida = _progresso >= threshold;
        final ativa     = _progresso >= threshold - 35 && _progresso < threshold;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: concluida
                    ? const Color(0xFF4ADE80).withOpacity(0.15)
                    : ativa
                    ? const Color(0xFFF9C200).withOpacity(0.1)
                    : const Color(0xFF111118),
                shape: BoxShape.circle,
                border: Border.all(
                  color: concluida
                      ? const Color(0xFF4ADE80)
                      : ativa
                      ? const Color(0xFFF9C200)
                      : const Color(0xFF1E1E2E),
                ),
              ),
              child: Icon(
                concluida ? Icons.check : Icons.circle,
                size: concluida ? 16 : 6,
                color: concluida
                    ? const Color(0xFF4ADE80)
                    : ativa
                    ? const Color(0xFFF9C200)
                    : const Color(0xFF1E1E2E),
              ),
            ),
            const SizedBox(width: 12),
            Text(e['label'] as String,
                style: TextStyle(
                  color: concluida
                      ? const Color(0xFF4ADE80)
                      : ativa
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: ativa || concluida
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
          ]),
        );
      }).toList(),
    );
  }
}
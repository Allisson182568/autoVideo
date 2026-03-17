// lib/screens/studio_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Callback para navegar para o gerador com tema pré-preenchido
typedef OnGerarVideo = void Function(String tema, String formato);

class StudioScreen extends StatefulWidget {
  final OnGerarVideo? onGerarVideo;
  const StudioScreen({super.key, this.onGerarVideo});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  Map<String, dynamic>? _dashboard;
  bool _carregando = true;
  bool _sugerindo  = false;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    setState(() => _carregando = true);
    try {
      final data = await ApiService.get('/studio/dashboard');
      setState(() { _dashboard = data; _carregando = false; });
    } catch (e) {
      setState(() => _carregando = false);
      _snack('Erro ao carregar: $e', erro: true);
    }
  }

  Future<void> _sugerirTemas() async {
    setState(() => _sugerindo = true);
    try {
      final sugestoes = await ApiService.post('/studio/sugerir', {});
      if (!mounted) return;
      _mostrarSugestoes(sugestoes);
    } catch (e) {
      _snack('Erro ao sugerir: $e', erro: true);
    } finally {
      setState(() => _sugerindo = false);
    }
  }

  Future<void> _gerarDaAgenda(int indice) async {
    try {
      final params = await ApiService.get('/studio/agenda/$indice/gerar');
      final tema    = params['tema']    as String? ?? '';
      final formato = params['formato'] as String? ?? 'short';

      // Atualiza status para "gerando"
      await ApiService.patch('/studio/agenda/$indice', {'status': 'gerado'});
      _carregarDashboard();

      // Chama o callback para mudar para a aba Gerar com tema pré-preenchido
      if (widget.onGerarVideo != null) {
        widget.onGerarVideo!(tema, formato);
      }
    } catch (e) {
      _snack('Erro: $e', erro: true);
    }
  }

  void _mostrarSugestoes(Map<String, dynamic> sugestoes) {
    final dias = List<Map<String, dynamic>>.from(sugestoes['dias'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠 Sugestões da IA',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  if (sugestoes['resumo_estrategia'] != null)
                    Text(sugestoes['resumo_estrategia'],
                        style: TextStyle(color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                ],
              )),
              ElevatedButton(
                onPressed: () async {
                  await ApiService.post('/studio/agenda/importar', {'dias': dias});
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _carregarDashboard();
                  _snack('${dias.length} temas adicionados!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C200),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Importar Todos',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: dias.length,
              itemBuilder: (_, i) {
                final dia = dias[i];
                final isShort = dia['tipo'] == 'short';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isShort
                          ? const Color(0xFFF9C200).withOpacity(0.3)
                          : const Color(0xFF60A5FA).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _badgeTipo(dia['tipo']),
                        const SizedBox(width: 8),
                        Text(dia['data'] ?? '',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(dia['tema'] ?? '',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      if (dia['hook'] != null) ...[
                        const SizedBox(height: 4),
                        Text('💬 ${dia['hook']}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red : const Color(0xFF4ADE80),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9C200))),
      );
    }

    final canal   = _dashboard?['canal']   ?? {};
    final fase    = _dashboard?['fase']    ?? {};
    final agenda  = List<Map<String, dynamic>>.from(_dashboard?['agenda']  ?? []);
    final analise = _dashboard?['analise'] ?? {};
    final alertas = List<Map<String, dynamic>>.from(analise['alertas'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: RefreshIndicator(
        onRefresh: _carregarDashboard,
        color: const Color(0xFFF9C200),
        child: CustomScrollView(slivers: [

          // Header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('STUDIO', style: TextStyle(
                      color: Color(0xFFF9C200), fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 2)),
                  Text(canal['nome'] ?? 'Meu Canal',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111118),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E1E2E)),
                  ),
                  child: Column(children: [
                    Text(fase['emoji'] ?? '🌱',
                        style: const TextStyle(fontSize: 20)),
                    Text(fase['label'] ?? '',
                        style: const TextStyle(color: Color(0xFFF9C200),
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              _cardInscritos(canal['inscritos'] ?? 0, fase),
            ]),
          )),

          // Alertas
          if (alertas.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: alertas.map(_cardAlerta).toList()),
            )),

          // Stats
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _cardStats(analise, fase),
          )),

          // Botão Sugerir
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _sugerindo ? null : _sugerirTemas,
                icon: _sugerindo
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                    : const Text('🧠', style: TextStyle(fontSize: 18)),
                label: Text(_sugerindo
                    ? 'Gerando estratégia...'
                    : 'Sugerir Temas com IA',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C200),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          )),

          // Label Agenda
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AGENDA', style: TextStyle(
                    color: Color(0xFFF9C200), fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
                Text('${agenda.length} vídeos',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          )),

          // Lista ou vazio
          agenda.isEmpty
              ? SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: _cardVazio()))
              : SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _cardAgenda(agenda[i], i),
            ),
            childCount: agenda.length,
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _dialogAdicionarTema,
        backgroundColor: const Color(0xFFF9C200),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Widgets ──

  Widget _cardInscritos(int inscritos, Map fase) {
    final dist   = fase['distribuicao'] as Map? ?? {};
    final pShort = ((dist['short'] ?? 0.8) * 100).toInt();
    final pLongo = ((dist['longo'] ?? 0.2) * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inscritos.toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              Text('inscritos', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Meta: $pShort% Shorts', style: const TextStyle(
              color: Color(0xFFF9C200), fontSize: 12,
              fontWeight: FontWeight.w600)),
          Text('$pLongo% Longões', style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _cardAlerta(Map alerta) {
    final isCritico = alerta['tipo'] == 'critico';
    final cor = isCritico ? Colors.red : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(isCritico ? Icons.error_outline : Icons.warning_amber_rounded,
            color: cor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alerta['mensagem'] ?? '', style: TextStyle(
                  color: cor, fontSize: 13, fontWeight: FontWeight.w600)),
              if (alerta['acao'] != null)
                Text(alerta['acao'], style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ])),
      ]),
    );
  }

  Widget _cardStats(Map analise, Map fase) {
    final totalShorts = analise['total_shorts'] ?? 0;
    final totalLongos = analise['total_longos'] ?? 0;
    final total       = totalShorts + totalLongos;
    final propAtual   = total > 0 ? (totalShorts / total * 100).round() : 0;
    final dist        = fase['distribuicao'] as Map? ?? {};
    final propIdeal   = ((dist['short'] ?? 0.8) * 100).toInt();
    final ok          = (propAtual - propIdeal).abs() <= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Equilíbrio na Agenda', style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (ok ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(ok ? '✓ Ideal' : '⚠ Ajustar',
                style: TextStyle(
                    color: ok ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B),
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _statItem('⚡ Shorts', totalShorts.toString(), const Color(0xFFF9C200)),
          const SizedBox(width: 8),
          _statItem('🎬 Longões', totalLongos.toString(), const Color(0xFF60A5FA)),
          const SizedBox(width: 8),
          _statItem('% Atual', '$propAtual%',
              ok ? const Color(0xFF4ADE80) : const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _statItem('% Ideal', '$propIdeal%', Colors.white.withOpacity(0.4)),
        ]),
      ]),
    );
  }

  Widget _statItem(String label, String valor, Color cor) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(valor, style: TextStyle(
            color: cor, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(
            color: Colors.white.withOpacity(0.4), fontSize: 10)),
      ]),
    ));
  }

  Widget _cardAgenda(Map item, int indice) {
    final status    = item['status'] ?? 'pendente';
    final corStatus = status == 'publicado'
        ? const Color(0xFF4ADE80)
        : status == 'gerado'
        ? const Color(0xFF60A5FA)
        : Colors.white.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Row(children: [
        _badgeTipo(item['tipo']),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['data'] ?? '', style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 11)),
          const SizedBox(height: 2),
          Text(item['tema'] ?? '', style: const TextStyle(
              color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w600)),
          if (item['hook'] != null && (item['hook'] as String).isNotEmpty)
            Text('💬 ${item['hook']}',
                style: TextStyle(color: Colors.white.withOpacity(0.35),
                    fontSize: 11, fontStyle: FontStyle.italic),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(
                color: corStatus, fontSize: 10,
                fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            // ▶ Play — vai para o gerador com tema pré-preenchido
            GestureDetector(
              onTap: () => _gerarDaAgenda(indice),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9C200).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Color(0xFFF9C200), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // 🗑 Remover
            GestureDetector(
              onTap: () async {
                await ApiService.delete('/studio/agenda/$indice');
                _carregarDashboard();
              },
              child: Icon(Icons.delete_outline,
                  color: Colors.white.withOpacity(0.3), size: 18),
            ),
          ]),
        ]),
      ]),
    );
  }

  Widget _cardVazio() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFF9C200).withOpacity(0.2)),
      ),
      child: Column(children: [
        const Text('📅', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('Agenda vazia', style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Use "Sugerir Temas com IA" para preencher\na semana automaticamente',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _badgeTipo(String? tipo) {
    final isShort = tipo == 'short';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isShort
            ? const Color(0xFFF9C200).withOpacity(0.1)
            : const Color(0xFF60A5FA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isShort
              ? const Color(0xFFF9C200).withOpacity(0.3)
              : const Color(0xFF60A5FA).withOpacity(0.3),
        ),
      ),
      child: Text(isShort ? '⚡ Short' : '🎬 Longo',
          style: TextStyle(
            color: isShort ? const Color(0xFFF9C200) : const Color(0xFF60A5FA),
            fontSize: 11, fontWeight: FontWeight.w600,
          )),
    );
  }

  void _dialogAdicionarTema() {
    final temaCtrl = TextEditingController();
    final hookCtrl = TextEditingController();
    String tipo    = 'short';
    final data     = DateTime.now().toIso8601String().split('T')[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ADICIONAR TEMA', style: TextStyle(
                    color: Color(0xFFF9C200), fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _campo('Tema do vídeo', temaCtrl),
                const SizedBox(height: 10),
                _campo('Hook (abertura)', hookCtrl),
                const SizedBox(height: 16),
                Row(children: [
                  _botaoTipo('⚡ Short', 'short', tipo,
                          (v) => setModal(() => tipo = v)),
                  const SizedBox(width: 10),
                  _botaoTipo('🎬 Longo', 'longo', tipo,
                          (v) => setModal(() => tipo = v)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (temaCtrl.text.trim().isEmpty) return;
                      await ApiService.post('/studio/agenda', {
                        'data':    data,
                        'tipo':    tipo,
                        'tema':    temaCtrl.text.trim(),
                        'hook':    hookCtrl.text.trim(),
                        'status':  'pendente',
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _carregarDashboard();
                      _snack('Tema adicionado!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9C200),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Adicionar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF0A0A0F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF9C200))),
      ),
    );
  }

  Widget _botaoTipo(String label, String valor, String atual, Function(String) onTap) {
    final sel = valor == atual;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFFF9C200).withOpacity(0.1)
              : const Color(0xFF0A0A0F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: sel ? const Color(0xFFF9C200) : const Color(0xFF1E1E2E)),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
                color: sel ? const Color(0xFFF9C200) : Colors.white,
                fontWeight: FontWeight.w600)),
      ),
    ));
  }
}
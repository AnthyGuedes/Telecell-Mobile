import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/analista_controller.dart';
import '../ai/core/analyst_engine.dart';
import '../ai/core/catalogo_consultas.dart';
import 'configuracoes_ia_page.dart';

/// ============================================================================
/// AGENTE ANALISTA — tela de conversa
/// ----------------------------------------------------------------------------
/// Duas decisões de UX que valem mais que o visual:
///  1. A fase atual é mostrada em texto ("Lendo o banco de dados…"). No motor
///     local a resposta demora; sem isso o usuário mata o app.
///  2. O SQL executado fica disponível num expansor. Um agente que analisa
///     dinheiro precisa ser auditável — o técnico tem que poder conferir de
///     onde saiu o número antes de tomar uma decisão de compra.
/// ============================================================================
class AnalistaIaPage extends StatefulWidget {
  const AnalistaIaPage({super.key});

  @override
  State<AnalistaIaPage> createState() => _AnalistaIaPageState();
}

class _AnalistaIaPageState extends State<AnalistaIaPage> {
  final _controller = AnalistaController();
  final _campoController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.sincronizarConfiguracao();
    _controller.addListener(_rolarParaFim);
  }

  @override
  void dispose() {
    _controller.removeListener(_rolarParaFim);
    _controller.dispose();
    _campoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar([String? textoDireto]) async {
    final texto = textoDireto ?? _campoController.text;
    if (texto.trim().isEmpty) return;
    _campoController.clear();
    FocusScope.of(context).unfocus();
    await _controller.perguntar(texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Analista de Dados'),
        actions: [
          IconButton(
            tooltip: 'Limpar conversa',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _controller.limparHistorico,
          ),
          IconButton(
            tooltip: 'Configurações da IA',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracoesIaPage()),
              );
              await _controller.sincronizarConfiguracao();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _FaixaModo(motor: _controller.settings.motor),
              Expanded(
                child: _controller.mensagens.isEmpty
                    ? _EmptyState(onSugestao: _enviar)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                        itemCount: _controller.mensagens.length,
                        itemBuilder: (context, i) =>
                            _Balao(mensagem: _controller.mensagens[i]),
                      ),
              ),
              if (_controller.ocupado)
                _IndicadorFase(mensagem: _controller.fase.mensagem),
              _CampoPergunta(
                controller: _campoController,
                habilitado: !_controller.ocupado,
                onEnviar: _enviar,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FaixaModo extends StatelessWidget {
  final TipoMotor motor;
  const _FaixaModo({required this.motor});

  @override
  Widget build(BuildContext context) {
    final local = motor == TipoMotor.local;
    final cor = local ? const Color(0xFF27AE60) : const Color(0xFFE67E22);
    return Container(
      width: double.infinity,
      color: cor.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(local ? Icons.phonelink_lock_rounded : Icons.cloud_outlined,
              size: 16, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              local
                  ? 'Análise no aparelho. Nenhum dado de cliente sai do celular.'
                  : 'Análise pelo Gemini. Dados pessoais ficam bloqueados.',
              style: TextStyle(
                  fontSize: 11.5, color: Colors.grey[800], height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String) onSugestao;
  const _EmptyState({required this.onSugestao});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Icon(Icons.insights_rounded,
            size: 56, color: Color(0xFF1565C0)),
        const SizedBox(height: 16),
        const Text(
          'Pergunte sobre a sua operação',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'O agente lê apenas as ordens de serviço e os clientes já cadastrados '
          'neste aparelho. Ele não altera nada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 28),
        ...CatalogoConsultas.sugestoes.map(
          (sugestao) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => onSugestao(sugestao),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 17, color: Color(0xFFE67E22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(sugestao,
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Balao extends StatelessWidget {
  final MensagemAnalise mensagem;
  const _Balao({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    if (mensagem.doUsuario) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(mensagem.texto,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      );
    }

    final erro = mensagem.erro;
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 32),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: erro ? const Color(0xFFFFF3F2) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: erro
              ? Colors.redAccent.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (erro)
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text('Não consegui responder',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700])),
              ],
            ),
          if (erro) const SizedBox(height: 8),
          _MarkdownSimples(texto: mensagem.texto),
          if (mensagem.sqlExecutado != null) ...[
            const SizedBox(height: 10),
            _AuditoriaSql(mensagem: mensagem),
          ],
        ],
      ),
    );
  }
}

/// Expansor de auditoria: SQL executado, linhas lidas e tempo total.
class _AuditoriaSql extends StatelessWidget {
  final MensagemAnalise mensagem;
  const _AuditoriaSql({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final rodape = [
      if (mensagem.linhasRetornadas != null)
        '${mensagem.linhasRetornadas} linha(s)',
      if (mensagem.duracao != null)
        '${(mensagem.duracao!.inMilliseconds / 1000).toStringAsFixed(1)} s',
      if (mensagem.viaCurada) 'resposta rápida',
    ].join(' · ');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.receipt_long_outlined,
            size: 17, color: Color(0xFF1565C0)),
        title: Text('Ver a consulta usada  ·  $rodape',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  mensagem.sqlExecutado!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.5,
                    color: Color(0xFFB9E4C9),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: mensagem.sqlExecutado!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consulta copiada.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
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

class _IndicadorFase extends StatelessWidget {
  final String mensagem;
  const _IndicadorFase({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(mensagem,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _CampoPergunta extends StatelessWidget {
  final TextEditingController controller;
  final bool habilitado;
  final void Function([String?]) onEnviar;

  const _CampoPergunta({
    required this.controller,
    required this.habilitado,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: habilitado,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              decoration: const InputDecoration(
                hintText: 'Ex.: qual foi meu faturamento em junho?',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: habilitado ? () => onEnviar() : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(15),
            ),
            child: const Icon(Icons.arrow_upward_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Renderizador de um subconjunto de Markdown (##, **negrito**, - lista, >).
/// Deliberadamente caseiro: evita adicionar uma dependência de 300 KB para
/// formatar quatro elementos, e o prompt do agente já restringe a saída a eles.
class _MarkdownSimples extends StatelessWidget {
  final String texto;
  const _MarkdownSimples({required this.texto});

  @override
  Widget build(BuildContext context) {
    final blocos = <Widget>[];

    for (final linhaBruta in texto.split('\n')) {
      final linha = linhaBruta.trim();
      if (linha.isEmpty) {
        blocos.add(const SizedBox(height: 8));
        continue;
      }

      if (linha.startsWith('#')) {
        final titulo = linha.replaceFirst(RegExp(r'^#+\s*'), '');
        blocos.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ));
      } else if (linha.startsWith('> ')) {
        blocos.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _linhaRica(linha.substring(2), italico: true),
        ));
      } else if (linha.startsWith('- ') || linha.startsWith('* ')) {
        blocos.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontSize: 13.5)),
              Expanded(child: _linhaRica(linha.substring(2))),
            ],
          ),
        ));
      } else {
        blocos.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _linhaRica(linha),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocos,
    );
  }

  Widget _linhaRica(String linha, {bool italico = false}) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;

    for (final m in regex.allMatches(linha)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: linha.substring(cursor, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      cursor = m.end;
    }
    if (cursor < linha.length) {
      spans.add(TextSpan(text: linha.substring(cursor)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: Colors.grey[850],
          fontStyle: italico ? FontStyle.italic : FontStyle.normal,
        ),
        children: spans,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/config/ai_settings.dart';
import '../ai/core/analyst_engine.dart';
import '../ai/engines/gemini_cloud_engine.dart';
import '../ai/engines/local_llm_engine.dart';

/// ============================================================================
/// CONFIGURAÇÕES DA IA
/// ----------------------------------------------------------------------------
/// Uma decisão principal na tela — onde a inferência acontece — e tudo o mais
/// se subordina a ela. O bloco de chave de API só aparece no modo nuvem; o
/// catálogo de modelos, só no modo local. Menos campos visíveis, menos chance
/// de o balconista configurar algo que não vai usar.
/// ============================================================================
class ConfiguracoesIaPage extends StatefulWidget {
  const ConfiguracoesIaPage({super.key});

  @override
  State<ConfiguracoesIaPage> createState() => _ConfiguracoesIaPageState();
}

class _ConfiguracoesIaPageState extends State<ConfiguracoesIaPage> {
  final _repositorio = AiSettingsRepository();
  final _chaveController = TextEditingController();
  final _caminhoController = TextEditingController();

  AiSettings _settings = const AiSettings();
  bool _carregando = true;
  bool _testando = false;
  bool _ocultarChave = true;
  StatusMotor? _ultimoTeste;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _chaveController.dispose();
    _caminhoController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final settings = await _repositorio.carregar();
    final chave = await _repositorio.lerChaveApi();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _chaveController.text = chave;
      _caminhoController.text = settings.modeloLocalCaminho;
      _carregando = false;
    });
  }

  Future<void> _persistir(AiSettings novo) async {
    setState(() {
      _settings = novo;
      _ultimoTeste = null;
    });
    await _repositorio.salvar(novo);
  }

  Future<void> _salvarChave() async {
    await _repositorio.salvarChaveApi(_chaveController.text);
    if (!mounted) return;
    setState(() => _ultimoTeste = null);
    _avisar('Chave salva no cofre criptografado do aparelho.');
  }

  Future<void> _testarMotor() async {
    setState(() {
      _testando = true;
      _ultimoTeste = null;
    });

    late AnalystEngine motor;
    if (_settings.motor == TipoMotor.nuvem) {
      await _repositorio.salvarChaveApi(_chaveController.text);
      motor = GeminiCloudEngine(apiKey: _chaveController.text.trim());
    } else {
      final caminho = _settings.modeloLocalCaminho;
      motor = LocalLlmEngine(
        origemModelo: caminho.isNotEmpty ? caminho : _settings.modeloLocal.url,
        origemLocal: caminho.isNotEmpty,
      );
    }

    StatusMotor status;
    try {
      if (_settings.motor == TipoMotor.local) await motor.preparar();
      status = await motor.verificarStatus();
    } on MotorIndisponivelException catch (e) {
      status = StatusMotor.indisponivel(e.motivo);
    } on Object catch (e) {
      status = StatusMotor.indisponivel('Falha no teste: $e');
    } finally {
      await motor.liberar();
    }

    if (!mounted) return;
    setState(() {
      _testando = false;
      _ultimoTeste = status;
    });
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF27AE60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Configurações da IA')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SecaoTitulo(
                  icone: Icons.memory_rounded,
                  titulo: 'Onde a análise acontece',
                  subtitulo:
                      'Define se os dados dos seus clientes saem do aparelho.',
                ),
                _CartaoMotor(
                  selecionado: _settings.motor == TipoMotor.local,
                  icone: Icons.phonelink_lock_rounded,
                  titulo: 'No aparelho',
                  descricao:
                      'Funciona sem internet. Nenhum dado de cliente sai do '
                      'celular. Respostas levam alguns segundos a mais.',
                  destaque: 'Recomendado',
                  onTap: () => _persistir(_settings.copyWith(motor: TipoMotor.local)),
                ),
                const SizedBox(height: 10),
                _CartaoMotor(
                  selecionado: _settings.motor == TipoMotor.nuvem,
                  icone: Icons.cloud_outlined,
                  titulo: 'Google Gemini',
                  descricao:
                      'Mais rápido e mais preciso, mas exige internet e envia '
                      'os números consultados para a API. CPF, IMEI, telefone '
                      'e senha de desbloqueio ficam bloqueados neste modo.',
                  onTap: () => _persistir(_settings.copyWith(motor: TipoMotor.nuvem)),
                ),
                const SizedBox(height: 24),

                if (_settings.motor == TipoMotor.local) ..._blocoModeloLocal(),
                if (_settings.motor == TipoMotor.nuvem) ..._blocoChaveApi(cores),

                const SizedBox(height: 24),
                _SecaoTitulo(
                  icone: Icons.speed_rounded,
                  titulo: 'Desempenho',
                  subtitulo: 'Como o agente decide responder.',
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: SwitchListTile(
                    value: _settings.usarConsultasCuradas,
                    onChanged: (v) => _persistir(
                        _settings.copyWith(usarConsultasCuradas: v)),
                    title: const Text('Usar respostas rápidas'),
                    subtitle: const Text(
                      'Perguntas comuns (faturamento, gargalos, modelos mais '
                      'atendidos) usam consultas já validadas e respondem na '
                      'hora, sem acionar o modelo.',
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),

                const SizedBox(height: 24),
                if (_ultimoTeste != null) _ResultadoTeste(status: _ultimoTeste!),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _testando ? null : _testarMotor,
                  icon: _testando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_circle_outline_rounded),
                  label: Text(_testando
                      ? 'Testando…'
                      : 'Testar conexão com o agente'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _blocoModeloLocal() {
    return [
      _SecaoTitulo(
        icone: Icons.download_for_offline_outlined,
        titulo: 'Modelo instalado',
        subtitulo:
            'Baixe uma vez pelo Wi-Fi; depois o agente funciona offline.',
      ),
      ...ModeloLocalDisponivel.catalogo.map((modelo) {
        final ativo = _settings.modeloLocalId == modelo.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CartaoMotor(
            selecionado: ativo,
            icone: Icons.auto_awesome_outlined,
            titulo: modelo.nome,
            descricao: modelo.requisito,
            onTap: () => _persistir(
              _settings.copyWith(
                  modeloLocalId: modelo.id, modeloLocalCaminho: ''),
            ),
          ),
        );
      }),
      const SizedBox(height: 4),
      Text(
        'Tem o arquivo .task ou .litertlm já no aparelho? Informe o caminho '
        'completo em vez de baixar de novo.',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _caminhoController,
        decoration: const InputDecoration(
          labelText: 'Caminho do arquivo (opcional)',
          hintText: '/storage/emulated/0/Download/gemma3-1b-it.task',
          prefixIcon: Icon(Icons.folder_open_rounded),
        ),
        onSubmitted: (valor) =>
            _persistir(_settings.copyWith(modeloLocalCaminho: valor.trim())),
      ),
    ];
  }

  List<Widget> _blocoChaveApi(ColorScheme cores) {
    return [
      _SecaoTitulo(
        icone: Icons.key_rounded,
        titulo: 'Chave de API',
        subtitulo: 'Guardada no cofre criptografado do sistema operacional.',
      ),
      TextField(
        controller: _chaveController,
        obscureText: _ocultarChave,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: 'Chave do Google AI Studio',
          hintText: 'AIza…',
          prefixIcon: const Icon(Icons.vpn_key_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _ocultarChave ? 'Mostrar chave' : 'Ocultar chave',
                icon: Icon(_ocultarChave
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _ocultarChave = !_ocultarChave),
              ),
              IconButton(
                tooltip: 'Colar',
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () async {
                  final dados = await Clipboard.getData(Clipboard.kTextPlain);
                  if (dados?.text != null) {
                    setState(() => _chaveController.text = dados!.text!.trim());
                  }
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _salvarChave,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Salvar chave'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await _repositorio.salvarChaveApi('');
                _chaveController.clear();
                if (mounted) _avisar('Chave removida do aparelho.');
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remover'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Componentes visuais
// ─────────────────────────────────────────────────────────────────────────────

class _SecaoTitulo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;

  const _SecaoTitulo({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitulo,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoMotor extends StatelessWidget {
  final bool selecionado;
  final IconData icone;
  final String titulo;
  final String descricao;
  final String? destaque;
  final VoidCallback onTap;

  const _CartaoMotor({
    required this.selecionado,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
    this.destaque,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF1565C0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado ? azul.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? azul : Colors.grey.withValues(alpha: 0.22),
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: selecionado ? azul : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(titulo,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.bold)),
                      if (destaque != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(destaque!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(descricao,
                      style:
                          TextStyle(fontSize: 12.5, color: Colors.grey[700])),
                ],
              ),
            ),
            Icon(
              selecionado
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selecionado ? azul : Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoTeste extends StatelessWidget {
  final StatusMotor status;

  const _ResultadoTeste({required this.status});

  @override
  Widget build(BuildContext context) {
    final cor = status.pronto ? const Color(0xFF27AE60) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.pronto
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: cor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(status.descricao,
                style: TextStyle(fontSize: 13, color: Colors.grey[850])),
          ),
        ],
      ),
    );
  }
}

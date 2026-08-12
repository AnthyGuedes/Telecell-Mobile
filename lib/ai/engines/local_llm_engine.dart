import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../core/analyst_engine.dart';
import '../core/telecell_schema.dart';

/// ============================================================================
/// MOTOR LOCAL — inferência no próprio aparelho, zero rede
/// ----------------------------------------------------------------------------
/// ⚠️ PONTO DE MANUTENÇÃO: toda chamada ao pacote `flutter_gemma` está confinada
/// aos três métodos privados no fim deste arquivo (`_instalarModelo`,
/// `_abrirModelo`, `_completar`). O pacote evolui rápido; se a assinatura mudar
/// numa atualização, só este arquivo precisa de ajuste — o restante do app
/// depende apenas da interface [AnalystEngine].
///
/// Modelos recomendados para o caso de uso (Text-to-SQL + sumarização curta):
///   • Gemma 4 E2B .litertlm  — melhor qualidade, ~3 GB RAM, exige 6 GB+ no aparelho
///   • Gemma 3 1B  .task      — cabe em aparelhos de balcão, ~1 GB RAM
/// Text-to-SQL é uma tarefa de precisão: prefira o maior modelo que o parque de
/// aparelhos da loja suportar, e mantenha o roteador de consultas curadas ligado
/// como rede de segurança.
/// ============================================================================
class LocalLlmEngine implements AnalystEngine {
  /// URL ou caminho do arquivo do modelo (.litertlm ou .task).
  final String origemModelo;

  /// `true` quando [origemModelo] aponta para um arquivo já presente no
  /// aparelho (cartão SD, pasta de downloads) em vez de uma URL.
  final bool origemLocal;

  final int maxTokens;

  InferenceModel? _modelo;
  bool _inicializado = false;

  LocalLlmEngine({
    required this.origemModelo,
    this.origemLocal = false,
    this.maxTokens = 2048,
  });

  @override
  TipoMotor get tipo => TipoMotor.local;

  @override
  String get nomeModelo => origemModelo.split('/').last;

  @override
  Future<StatusMotor> verificarStatus() async {
    if (origemModelo.trim().isEmpty) {
      return const StatusMotor.indisponivel(
        'Nenhum modelo configurado. Escolha um modelo em Configurações da IA.',
      );
    }
    if (_modelo != null) {
      return StatusMotor(pronto: true, descricao: '$nomeModelo carregado');
    }
    return StatusMotor(
      pronto: false,
      descricao: '$nomeModelo ainda não foi carregado na memória',
    );
  }

  @override
  Future<void> preparar() async {
    if (_modelo != null) return;
    try {
      await _inicializarRuntime();
      await _instalarModelo();
      _modelo = await _abrirModelo();
    } on Object catch (e) {
      throw MotorIndisponivelException(
        'Não foi possível carregar o modelo local. Verifique se o arquivo foi '
        'baixado por completo e se o aparelho tem memória livre. Detalhe: $e',
      );
    }
  }

  @override
  Future<String> gerarSql(String pergunta) async {
    await preparar();
    // Sessão nova a cada pergunta: sem histórico, sem contaminação de contexto.
    // Em Text-to-SQL o histórico atrapalha mais do que ajuda.
    final resposta = await _completar(
      sistema: promptSistemaTextToSql(ocultarPii: false),
      usuario: 'Pergunta: $pergunta',
      temperatura: 0.1, // determinismo: SQL não é tarefa criativa
    );
    return resposta.trim();
  }

  @override
  Future<String> gerarRelatorio({
    required String pergunta,
    required String resultadoJson,
  }) async {
    await preparar();
    return _completar(
      sistema: promptSistemaRelatorio,
      usuario: 'Pergunta do gestor: "$pergunta"\n'
          'Resultado do banco (JSON): $resultadoJson',
      temperatura: 0.4, // um pouco de folga: aqui o texto é para humano
    );
  }

  @override
  Future<void> liberar() async {
    await _modelo?.close();
    _modelo = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FRONTEIRA COM O PACOTE flutter_gemma — ajuste aqui se a API mudar
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _inicializarRuntime() async {
    if (_inicializado) return;
    FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
    _inicializado = true;
  }

  Future<void> _instalarModelo() async {
    final instalador = FlutterGemma.installModel(modelType: ModelType.gemma4);
    if (origemLocal) {
      await instalador.fromFile(origemModelo).install();
    } else {
      await instalador.fromNetwork(origemModelo).install();
    }
  }

  Future<InferenceModel> _abrirModelo() =>
      FlutterGemma.getActiveModel(maxTokens: maxTokens);

  Future<String> _completar({
    required String sistema,
    required String usuario,
    required double temperatura,
  }) async {
    final chat = await _modelo!.createChat(temperature: temperatura);
    await chat.addQueryChunk(Message.text(text: sistema, isUser: false));
    await chat.addQueryChunk(Message.text(text: usuario, isUser: true));
    final resposta = await chat.generateChatResponse();
    return resposta.toString();
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/analyst_engine.dart';
import '../core/telecell_schema.dart';

/// ============================================================================
/// MOTOR EM NUVEM — Google Gemini (opcional, exige internet)
/// ----------------------------------------------------------------------------
/// Mantido como plano B: aparelhos de balcão antigos podem não ter RAM para o
/// modelo local. Note que aqui a política de privacidade é `nuvem`, e o
/// [SqlGuard] bloqueia automaticamente colunas com dado pessoal (senha de
/// desbloqueio, CPF, IMEI, telefone) — nada disso sai do aparelho.
///
/// Diferenças em relação ao `gemini_analyst_service.dart` original:
///  • a validação de SQL saiu daqui e virou o [SqlGuard] compartilhado, porque
///    o motor não deve ser responsável pela segurança do banco;
///  • o schema usado é o real do Drift, não o do rascunho.
/// ============================================================================
class GeminiCloudEngine implements AnalystEngine {
  final String apiKey;
  final String modelo;

  GenerativeModel? _modeloSql;
  GenerativeModel? _modeloRelatorio;

  GeminiCloudEngine({
    required this.apiKey,
    this.modelo = 'gemini-2.5-flash',
  });

  @override
  TipoMotor get tipo => TipoMotor.nuvem;

  @override
  String get nomeModelo => modelo;

  @override
  Future<StatusMotor> verificarStatus() async {
    if (apiKey.trim().isEmpty) {
      return const StatusMotor.indisponivel(
        'Nenhuma chave de API salva. Cole sua chave do Google AI Studio.',
      );
    }
    try {
      await preparar();
      final teste = await _modeloRelatorio!
          .generateContent([Content.text('Responda apenas: ok')]);
      final texto = teste.text?.trim() ?? '';
      return StatusMotor(
        pronto: texto.isNotEmpty,
        descricao: texto.isNotEmpty
            ? 'Chave válida. Conectado ao $modelo.'
            : 'A API respondeu vazio. Tente novamente em alguns instantes.',
      );
    } on Object catch (e) {
      return StatusMotor.indisponivel(_traduzirErro(e));
    }
  }

  @override
  Future<void> preparar() async {
    if (apiKey.trim().isEmpty) {
      throw const MotorIndisponivelException(
        'Salve uma chave de API antes de usar o motor em nuvem.',
      );
    }
    _modeloSql ??= GenerativeModel(
      model: modelo,
      apiKey: apiKey,
      systemInstruction:
          Content.system(promptSistemaTextToSql(ocultarPii: true)),
      generationConfig: GenerationConfig(temperature: 0.1, maxOutputTokens: 512),
    );
    _modeloRelatorio ??= GenerativeModel(
      model: modelo,
      apiKey: apiKey,
      systemInstruction: Content.system(promptSistemaRelatorio),
      generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 800),
    );
  }

  @override
  Future<String> gerarSql(String pergunta) async {
    await preparar();
    try {
      final resposta =
          await _modeloSql!.generateContent([Content.text('Pergunta: $pergunta')]);
      return resposta.text?.trim() ?? '';
    } on Object catch (e) {
      throw MotorIndisponivelException(_traduzirErro(e));
    }
  }

  @override
  Future<String> gerarRelatorio({
    required String pergunta,
    required String resultadoJson,
  }) async {
    await preparar();
    try {
      final resposta = await _modeloRelatorio!.generateContent([
        Content.text(
          'Pergunta do gestor: "$pergunta"\n'
          'Resultado do banco (JSON): $resultadoJson',
        ),
      ]);
      return resposta.text?.trim() ?? 'A API não retornou conteúdo.';
    } on Object catch (e) {
      throw MotorIndisponivelException(_traduzirErro(e));
    }
  }

  @override
  Future<void> liberar() async {
    _modeloSql = null;
    _modeloRelatorio = null;
  }

  /// Traduz falhas técnicas em instruções acionáveis para o balconista.
  String _traduzirErro(Object erro) {
    final texto = erro.toString().toLowerCase();
    if (texto.contains('api key') || texto.contains('api_key_invalid')) {
      return 'A chave de API foi recusada. Confira se copiou a chave inteira '
          'do Google AI Studio.';
    }
    if (texto.contains('quota') || texto.contains('429')) {
      return 'Limite de uso da API atingido. Aguarde alguns minutos ou use o '
          'motor local.';
    }
    if (texto.contains('socket') ||
        texto.contains('failed host lookup') ||
        texto.contains('network')) {
      return 'Sem conexão com a internet. Troque para o motor local em '
          'Configurações da IA.';
    }
    return 'Falha ao falar com a API: $erro';
  }
}

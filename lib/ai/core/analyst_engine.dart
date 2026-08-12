import 'sql_guard.dart';

/// ============================================================================
/// CONTRATO DO MOTOR DE INFERÊNCIA (padrão Strategy)
/// ----------------------------------------------------------------------------
/// A UI e o controller conhecem apenas esta interface. Trocar Gemma local por
/// Gemini em nuvem — ou por qualquer motor futuro — não toca em nenhuma tela.
/// ============================================================================

enum TipoMotor { local, nuvem }

extension TipoMotorX on TipoMotor {
  String get rotulo => this == TipoMotor.local
      ? 'Modelo no aparelho (offline)'
      : 'Google Gemini (requer internet)';

  PoliticaPrivacidade get politica => this == TipoMotor.local
      ? PoliticaPrivacidade.local
      : PoliticaPrivacidade.nuvem;
}

/// Estado de prontidão do motor, exibido na tela de Configurações.
class StatusMotor {
  final bool pronto;
  final String descricao;
  final double? progressoDownload; // 0.0–1.0 durante instalação do modelo

  const StatusMotor({
    required this.pronto,
    required this.descricao,
    this.progressoDownload,
  });

  const StatusMotor.indisponivel(String motivo)
      : pronto = false,
        descricao = motivo,
        progressoDownload = null;
}

class MotorIndisponivelException implements Exception {
  final String motivo;
  const MotorIndisponivelException(this.motivo);
  @override
  String toString() => motivo;
}

abstract class AnalystEngine {
  TipoMotor get tipo;

  /// Nome legível do modelo em uso (ex.: 'Gemma 4 E2B').
  String get nomeModelo;

  /// Verifica se o motor pode responder agora (modelo baixado / chave válida).
  Future<StatusMotor> verificarStatus();

  /// Carrega pesos, abre contexto, valida credencial. Idempotente.
  Future<void> preparar();

  /// ETAPA 1 — pergunta em português → SQL bruto (ainda não sanitizado).
  Future<String> gerarSql(String pergunta);

  /// ETAPA 2 — pergunta + resultado JSON do SQLite → relatório em Markdown.
  Future<String> gerarRelatorio({
    required String pergunta,
    required String resultadoJson,
  });

  /// Libera contexto/memória. Chamado ao trocar de motor ou fechar a tela.
  Future<void> liberar();
}
